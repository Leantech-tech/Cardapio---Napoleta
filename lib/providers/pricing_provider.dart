import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../models/pricing.dart';
import '../services/pricing_service.dart';
import 'cart_provider.dart';
import 'menu_provider.dart';

/// Resultado da última validação de preços antes do fechamento do pedido.
enum ValidacaoFechamento {
  /// Preços conferem com o exibido; pode finalizar.
  ok,

  /// O servidor devolveu preços diferentes; o carrinho já foi atualizado e o
  /// cliente precisa conferir e confirmar novamente.
  precosAtualizados,

  /// Não foi possível consultar o servidor; os preços exibidos foram mantidos.
  indisponivel,
}

/// Orquestra a resolução de preços do Cardápio em tempo real.
///
/// Toda decisão de preço (tabela de preço do cliente, promoções De/Por e
/// Atacado, preço padrão) é delegada ao servidor via [PricingService]. Este
/// provider apenas recalcula nos momentos exigidos pela integração — inclusão,
/// remoção, troca de quantidade, troca/remoção de cliente e fechamento — e
/// aplica o resultado no carrinho e no cardápio.
class PricingProvider extends ChangeNotifier {
  final CartProvider _cart;
  final MenuProvider? _menu;
  final PricingService _service;

  Customer? _cliente;
  PricingResult? _resultado;
  bool _carregando = false;
  String? _erro;

  Timer? _debounce;

  /// Controle de respostas atrasadas: só a consulta mais recente aplica.
  int _sequencia = 0;

  /// Evita loop: aplicação de preços notifica o carrinho, que notifica este
  /// provider; enquanto aplica, novos recálculos são ignorados.
  bool _aplicando = false;

  /// Evita loop análogo nas notificações do cardápio.
  bool _aplicandoMenu = false;

  PricingProvider({
    required CartProvider cart,
    MenuProvider? menu,
    PricingService? service,
  })  : _cart = cart,
        _menu = menu,
        _service = service ?? PricingService() {
    _cart.addListener(_onCartChanged);
    _menu?.addListener(_onMenuChanged);
  }

  Customer? get cliente => _cliente;
  PricingResult? get resultado => _resultado;
  bool get carregando => _carregando;
  String? get erro => _erro;

  void _onCartChanged() {
    if (_aplicando) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), recalcular);
  }

  /// O cardápio terminou de carregar (ou recarregar): recalcula os preços com
  /// os produtos disponíveis, para exibir a tabela/promoções mesmo com o
  /// carrinho ainda vazio.
  void _onMenuChanged() {
    if (_aplicandoMenu) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), recalcular);
  }

  /// Monta a consulta de preços: todos os produtos do cardápio (para exibir a
  /// tabela no menu) mais as quantidades do carrinho (para o Atacado avaliar a
  /// quantidade acumulada de cada produto).
  List<PricingItemRequest> _montarItensConsulta() {
    final itens = <int, PricingItemRequest>{};

    final menu = _menu;
    if (menu != null) {
      for (final id in menu.produtoIds) {
        itens[id] = PricingItemRequest(produtoId: id, quantidade: 1);
      }
    }

    for (final item in _cart.items) {
      final produtoId = int.tryParse(item.productId);
      if (produtoId == null) continue;
      final atual = itens[produtoId];
      itens[produtoId] = PricingItemRequest(
        produtoId: produtoId,
        quantidade: (atual?.quantidade ?? 0) + item.quantity,
        valorAdicional: item.optionsPrice,
      );
    }

    return itens.values.toList();
  }

  /// Cliente identificado, trocado ou removido (null). Sempre recalcula em
  /// tempo real, mesmo que o cardápio/clientes já tenham sido carregados.
  Future<void> atualizarCliente(Customer? cliente) async {
    _cliente = cliente;
    await recalcular();
  }

  Future<void> recalcular() async {
    _debounce?.cancel();

    final itensConsulta = _montarItensConsulta();
    if (itensConsulta.isEmpty) {
      _resultado = const PricingResult({});
      _erro = null;
      _carregando = false;
      _aplicandoMenu = true;
      _menu?.restaurarPrecosNormais();
      _aplicandoMenu = false;
      notifyListeners();
      return;
    }

    final seq = ++_sequencia;
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final resultado = await _service.resolverPrecos(
        items: itensConsulta,
        pessoaId: _cliente?.id,
      );
      if (seq != _sequencia) return;
      _aplicar(resultado);
      _erro = null;
    } catch (e) {
      if (seq != _sequencia) return;
      _erro = 'Não foi possível atualizar os preços agora.';
      debugPrint('[PricingProvider] erro ao recalcular: $e');
    } finally {
      if (seq == _sequencia) {
        _carregando = false;
        notifyListeners();
      }
    }
  }

  /// Última consulta ao servidor antes de gravar o pedido. O aplicativo não é
  /// a autoridade final do preço: se o servidor devolver valores diferentes,
  /// o carrinho é atualizado e o fechamento deve ser confirmado novamente.
  Future<ValidacaoFechamento> validarFechamento() async {
    if (_cart.items.isEmpty) return ValidacaoFechamento.ok;

    _debounce?.cancel();
    final totalAntes = _cart.totalPrice;
    final seq = ++_sequencia;

    try {
      final resultado = await _service.resolverPrecos(
        items: _montarItensConsulta(),
        pessoaId: _cliente?.id,
      );
      if (seq != _sequencia) return ValidacaoFechamento.ok;
      _aplicar(resultado);
      _erro = null;
      notifyListeners();
      final diferenca = (_cart.totalPrice - totalAntes).abs();
      return diferenca > 0.011
          ? ValidacaoFechamento.precosAtualizados
          : ValidacaoFechamento.ok;
    } catch (e) {
      debugPrint('[PricingProvider] validação de fechamento falhou: $e');
      return ValidacaoFechamento.indisponivel;
    }
  }

  /// Pedido finalizado: limpa o cliente e restaura os preços normais.
  void finalizarPedido() {
    _debounce?.cancel();
    _cliente = null;
    _resultado = null;
    _erro = null;
    _aplicando = true;
    _cart.restaurarPrecosNormais();
    _aplicando = false;
    _aplicandoMenu = true;
    _menu?.restaurarPrecosNormais();
    _aplicandoMenu = false;
    notifyListeners();
  }

  void _aplicar(PricingResult resultado) {
    _resultado = resultado;
    _aplicando = true;
    _cart.aplicarPrecosResolvidos(resultado);
    _aplicando = false;
    _aplicandoMenu = true;
    _aplicarNoMenu(resultado);
    _aplicandoMenu = false;
  }

  /// O cardápio exibe somente preços de tabela; promoções aparecem no carrinho
  /// (a de Atacado depende da quantidade acumulada, não faz sentido no menu).
  void _aplicarNoMenu(PricingResult resultado) {
    final menu = _menu;
    if (menu == null) return;
    final tabelaId = resultado.tabelaPrecoId;
    final precosTabela = resultado.precosDeTabela;
    if (resultado.tabelaAtiva && tabelaId != null && precosTabela.isNotEmpty) {
      menu.aplicarPrecosDaTabela(tabelaId, precosTabela);
    } else {
      menu.restaurarPrecosNormais();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cart.removeListener(_onCartChanged);
    _menu?.removeListener(_onMenuChanged);
    super.dispose();
  }
}
