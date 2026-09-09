import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _menuService = MenuService();

  List<Category> _categories = [];
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  /// Preços originais (vr_venda) capturados no carregamento do cardápio,
  /// usados para restaurar os preços normais quando não há tabela aplicada.
  final Map<int, double> _precosBase = {};

  /// Tabela de preço atualmente aplicada, ou null quando os preços são os normais.
  int? _tabelaPrecoIdAplicada;

  /// Últimos preços de tabela aplicados, reutilizados após um reload do cardápio
  /// para não voltar silenciosamente ao preço padrão quando o cliente já está
  /// identificado (o PricingProvider reconsulta valores frescos a cada recálculo).
  Map<int, double> _ultimosPrecosTabela = {};

  List<Category> get categories => _categories;
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get tabelaPrecoIdAplicada => _tabelaPrecoIdAplicada;

  /// IDs dos produtos do cardápio, para consulta de preços em lote.
  List<int> get produtoIds => [
        for (final p in _products)
          if (int.tryParse(p.id) != null) int.parse(p.id),
      ];

  MenuProvider() {
    loadMenu();
  }

  Future<void> loadMenu() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _menuService.fetchCategories(),
        _menuService.fetchProducts(),
      ]);

      _categories = results[0] as List<Category>;
      _products = results[1] as List<Product>;
      _precosBase
        ..clear()
        ..addAll(_mapearPrecos(_products));

      // Reaplica a tabela do cliente identificado após o reload, em vez de
      // voltar silenciosamente aos preços normais.
      final tabelaAnterior = _tabelaPrecoIdAplicada;
      final precosAnteriores = _ultimosPrecosTabela;
      if (tabelaAnterior != null && precosAnteriores.isNotEmpty) {
        _tabelaPrecoIdAplicada = null;
        aplicarPrecosDaTabela(tabelaAnterior, precosAnteriores);
      } else {
        _tabelaPrecoIdAplicada = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar o cardápio: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Substitui os preços dos produtos pelos valores da tabela de preço.
  /// Produtos sem valor na tabela mantêm o preço normal.
  void aplicarPrecosDaTabela(int tabelaPrecoId, Map<int, double> precos) {
    _tabelaPrecoIdAplicada = tabelaPrecoId;
    _ultimosPrecosTabela = Map.of(precos);
    _products = [
      for (final p in _products)
        precos.containsKey(int.tryParse(p.id))
            ? p.copyWith(price: precos[int.parse(p.id)])
            : p,
    ];
    notifyListeners();
  }

  /// Restaura os preços normais (vr_venda) de todos os produtos.
  void restaurarPrecosNormais() {
    if (_tabelaPrecoIdAplicada == null) return;
    _tabelaPrecoIdAplicada = null;
    _ultimosPrecosTabela = {};
    _products = [
      for (final p in _products)
        _precosBase.containsKey(int.tryParse(p.id))
            ? p.copyWith(price: _precosBase[int.parse(p.id)])
            : p,
    ];
    notifyListeners();
  }

  static Map<int, double> _mapearPrecos(List<Product> products) {
    final map = <int, double>{};
    for (final p in products) {
      final id = int.tryParse(p.id);
      if (id != null) map[id] = p.price;
    }
    return map;
  }

  void refresh() {
    loadMenu();
  }
}
