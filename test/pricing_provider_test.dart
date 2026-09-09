import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tachao_menu/models/customer.dart';
import 'package:tachao_menu/models/pricing.dart';
import 'package:tachao_menu/models/product.dart';
import 'package:tachao_menu/providers/cart_provider.dart';
import 'package:tachao_menu/providers/pricing_provider.dart';
import 'package:tachao_menu/services/pricing_service.dart';

class _FakePricingService extends PricingService {
  final List<Completer<PricingResult>> pending = [];
  final List<PricingResult> scripted = [];
  final List<int?> pessoaIds = [];
  final List<List<PricingItemRequest>> consultas = [];

  @override
  Future<PricingResult> resolverPrecos({
    required List<PricingItemRequest> items,
    int? pessoaId,
  }) {
    pessoaIds.add(pessoaId);
    consultas.add(items);
    if (pending.isNotEmpty) return pending.removeAt(0).future;
    if (scripted.isNotEmpty) return Future.value(scripted.removeAt(0));
    return Future.value(const PricingResult({}));
  }
}

PricingResult resultado(int produtoId, double valor, {PrecoOrigem origem = PrecoOrigem.padrao, int? tabelaPrecoId}) {
  return PricingResult({
    produtoId: PrecoResolvido(
      produtoId: produtoId,
      valor: valor,
      origem: origem,
      tabelaPrecoId: tabelaPrecoId,
    ),
  });
}

Product produto(int id, double preco) => Product(
      id: '$id',
      name: 'Produto $id',
      description: '',
      price: preco,
      imagePath: '',
      categoryId: '1',
    );

void main() {
  group('PricingProvider', () {
    test('recalcular aplica preços resolvidos no carrinho com snapshot', () async {
      final cart = CartProvider();
      cart.addItem(produto(10, 20.0), 2, null, {}, {}, 0.0);

      final fake = _FakePricingService()
        ..scripted.add(resultado(10, 15.0, origem: PrecoOrigem.tabela, tabelaPrecoId: 3));
      final provider = PricingProvider(cart: cart, service: fake);

      await provider.recalcular();

      final item = cart.items.single;
      expect(item.basePrice, 15.0);
      expect(item.precoOrigem, PrecoOrigem.tabela);
      expect(item.tabelaPrecoId, 3);
      expect(item.precoPadrao, isNull);
      provider.dispose();
    });

    test('produto ausente do resultado mantém o preço base (PADRAO)', () async {
      final cart = CartProvider();
      cart.addItem(produto(10, 20.0), 1, null, {}, {}, 0.0);

      final fake = _FakePricingService()..scripted.add(const PricingResult({}));
      final provider = PricingProvider(cart: cart, service: fake);

      await provider.recalcular();

      final item = cart.items.single;
      expect(item.basePrice, 20.0);
      expect(item.precoOrigem, PrecoOrigem.padrao);
      provider.dispose();
    });

    test('atualizarCliente envia pessoa_id e remover cliente restaura preços normais', () async {
      final cart = CartProvider();
      cart.addItem(produto(10, 20.0), 1, null, {}, {}, 0.0);

      final fake = _FakePricingService()
        ..scripted.add(resultado(10, 15.0, origem: PrecoOrigem.tabela, tabelaPrecoId: 3))
        ..scripted.add(const PricingResult({}));
      final provider = PricingProvider(cart: cart, service: fake);

      await provider.atualizarCliente(
        const Customer(id: 123, nome: 'Cliente Teste', cpf: '31547485809'),
      );
      expect(fake.pessoaIds.last, 123);
      expect(cart.items.single.basePrice, 15.0);

      await provider.atualizarCliente(null);
      expect(fake.pessoaIds.last, isNull);
      final item = cart.items.single;
      expect(item.basePrice, 20.0);
      expect(item.precoOrigem, PrecoOrigem.padrao);
      expect(item.tabelaPrecoId, isNull);
      provider.dispose();
    });

    test('validarFechamento retorna ok quando o servidor confere o preço', () async {
      final cart = CartProvider();
      cart.addItem(produto(10, 20.0), 2, null, {}, {}, 0.0);

      final fake = _FakePricingService()..scripted.add(resultado(10, 20.0));
      final provider = PricingProvider(cart: cart, service: fake);

      final validacao = await provider.validarFechamento();
      expect(validacao, ValidacaoFechamento.ok);
      expect(cart.totalPrice, 40.0);
      provider.dispose();
    });

    test('validarFechamento detecta divergência e atualiza o carrinho', () async {
      final cart = CartProvider();
      cart.addItem(produto(10, 20.0), 2, null, {}, {}, 0.0);

      final fake = _FakePricingService()..scripted.add(resultado(10, 18.0));
      final provider = PricingProvider(cart: cart, service: fake);

      final validacao = await provider.validarFechamento();
      expect(validacao, ValidacaoFechamento.precosAtualizados);
      expect(cart.items.single.basePrice, 18.0);
      expect(cart.totalPrice, 36.0);
      provider.dispose();
    });

    test('resposta atrasada de uma consulta anterior não sobrescreve o preço', () async {
      final cart = CartProvider();
      cart.addItem(produto(10, 20.0), 1, null, {}, {}, 0.0);

      final fake = _FakePricingService();
      final c1 = Completer<PricingResult>();
      final c2 = Completer<PricingResult>();
      fake.pending.addAll([c1, c2]);
      final provider = PricingProvider(cart: cart, service: fake);

      final f1 = provider.recalcular();
      final f2 = provider.recalcular();

      // A consulta mais recente responde primeiro; a antiga não pode vencer.
      c2.complete(resultado(10, 12.0));
      await f2;
      c1.complete(resultado(10, 99.0));
      await f1;

      expect(cart.items.single.basePrice, 12.0);
      provider.dispose();
    });

    test('finalizarPedido limpa o cliente e restaura os preços normais', () async {
      final cart = CartProvider();
      cart.addItem(produto(10, 20.0), 1, null, {}, {}, 0.0);

      final fake = _FakePricingService()
        ..scripted.add(resultado(10, 15.0, origem: PrecoOrigem.promocao, tabelaPrecoId: null));
      final provider = PricingProvider(cart: cart, service: fake);

      await provider.atualizarCliente(
        const Customer(id: 7, nome: 'Cliente', cpf: '31547485809'),
      );
      expect(cart.items.single.basePrice, 15.0);

      provider.finalizarPedido();
      expect(provider.cliente, isNull);
      final item = cart.items.single;
      expect(item.basePrice, 20.0);
      expect(item.precoOrigem, PrecoOrigem.padrao);
      provider.dispose();
    });
  });
}
