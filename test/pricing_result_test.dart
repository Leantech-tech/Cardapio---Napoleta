import 'package:flutter_test/flutter_test.dart';
import 'package:tachao_menu/models/pricing.dart';

void main() {
  group('PrecoOrigem.parse', () {
    test('reconhece as origens em várias grafias', () {
      expect(PrecoOrigem.parse('PADRAO'), PrecoOrigem.padrao);
      expect(PrecoOrigem.parse('tabela'), PrecoOrigem.tabela);
      expect(PrecoOrigem.parse('TABELA'), PrecoOrigem.tabela);
      expect(PrecoOrigem.parse('promocao'), PrecoOrigem.promocao);
      expect(PrecoOrigem.parse('PROMOÇÃO'), PrecoOrigem.promocao);
      expect(PrecoOrigem.parse(null), PrecoOrigem.padrao);
      expect(PrecoOrigem.parse(''), PrecoOrigem.padrao);
    });

    test('wire retorna o nome do contrato', () {
      expect(PrecoOrigem.padrao.wire, 'PADRAO');
      expect(PrecoOrigem.tabela.wire, 'TABELA');
      expect(PrecoOrigem.promocao.wire, 'PROMOCAO');
    });
  });

  group('PricingResult.fromJson', () {
    test('parse do formato com data.items', () {
      final result = PricingResult.fromJson({
        'data': {
          'items': [
            {
              'produto_id': 10,
              'valor': 8.5,
              'origem': 'PROMOCAO',
              'preco_padrao': 10.0,
              'promocao': {'id': 5, 'nome': 'Happy hour', 'tipo': 'DE_POR'},
            },
            {
              'produto_id': 20,
              'valor': 15.0,
              'origem': 'TABELA',
              'tabela_preco_id': 3,
              'tabela_nome': 'Atacado VIP',
            },
          ],
        },
      });

      expect(result.precos.length, 2);

      final promocao = result[10]!;
      expect(promocao.valor, 8.5);
      expect(promocao.origem, PrecoOrigem.promocao);
      expect(promocao.precoPadrao, 10.0);
      expect(promocao.promocaoId, 5);
      expect(promocao.promocaoNome, 'Happy hour');

      final tabela = result[20]!;
      expect(tabela.origem, PrecoOrigem.tabela);
      expect(tabela.tabelaPrecoId, 3);
      expect(result.tabelaPrecoId, 3);
      expect(result.precosDeTabela, {20: 15.0});
    });

    test(
      'aceita chaves alternativas (prices, valor_unitario, preco_origem)',
      () {
        final result = PricingResult.fromJson({
          'prices': [
            {'produtoId': 7, 'preco': '12,50', 'preco_origem': 'PADRAO'},
          ],
        });

        final resolvido = result[7]!;
        expect(resolvido.valor, 12.5);
        expect(resolvido.origem, PrecoOrigem.padrao);
      },
    );

    test('aceita promoção em campos planos (promocao_id/promocao_nome)', () {
      final result = PricingResult.fromJson({
        'data': {
          'itens': [
            {
              'produto_id': 1,
              'valor': 9.0,
              'promocao_id': 8,
              'promocao_nome': 'Leve 3',
              'promocao_tipo': 'ATACADO',
              'promocao_qtd_minima': 3,
            },
          ],
        },
      });

      final resolvido = result[1]!;
      expect(resolvido.origem, PrecoOrigem.padrao); // sem origem, assume PADRAO
      expect(resolvido.promocaoId, 8);
      expect(resolvido.promocaoTipo, 'ATACADO');
      expect(resolvido.promocaoQtdMinima, 3);
    });

    test('parse do formato real do servidor (tabela na raiz, prices)', () {
      final result = PricingResult.fromJson({
        'data': {
          'tabela_id': 6,
          'nome': 'Atacado',
          'revisao': 2,
          'ativa': true,
          'prices': [
            {
              'produto_id': 8241,
              'preco_padrao': 189,
              'valor': 150,
              'origem': 'TABELA',
            },
            {
              'produto_id': 8249,
              'preco_padrao': 20,
              'valor': 20,
              'origem': 'PADRAO',
            },
          ],
        },
      });

      expect(result.tabelaPrecoId, 6);
      expect(result.tabelaNome, 'Atacado');
      expect(result.tabelaRevisao, 2);
      expect(result.tabelaAtiva, isTrue);
      expect(result.precosDeTabela, {8241: 150.0});
      expect(result[8249]?.origem, PrecoOrigem.padrao);
    });

    test('aplica promoções De/Por e Atacado do formato real do servidor', () {
      final result = PricingResult.fromJson({
        'data': {
          'tabela_id': 6,
          'nome': 'Clientes especiais',
          'ativa': true,
          'prices': [
            {
              'produto_id': 10,
              'preco_padrao': 20,
              'valor': 18,
              'origem': 'TABELA',
            },
            {
              'produto_id': 20,
              'preco_padrao': 12,
              'valor': 12,
              'origem': 'PADRAO',
            },
          ],
          'promotions': [
            {
              'produto_id': 10,
              'id': 101,
              'nome': 'Oferta do dia',
              'tipo': 'DE_POR',
              'valor_promocional': 15,
            },
            {
              'produto_id': 20,
              'id': 202,
              'nome': 'Leve 3',
              'tipo': 'ATACADO',
              'valor_promocional': 9,
              'quantidade_minima': 3,
            },
          ],
        },
      });

      expect(result[10]?.valor, 15);
      expect(result[10]?.origem, PrecoOrigem.promocao);
      expect(result[10]?.promocaoTipo, 'DE_POR');
      expect(result[10]?.tabelaPrecoId, 6);
      expect(result[20]?.valor, 9);
      expect(result[20]?.origem, PrecoOrigem.promocao);
      expect(result[20]?.promocaoTipo, 'ATACADO');
      expect(result[20]?.promocaoQtdMinima, 3);
    });

    test('promoção mais cara não aumenta preço de tabela menor', () {
      final result = PricingResult.fromJson({
        'data': {
          'tabela_id': 6,
          'ativa': true,
          'prices': [
            {
              'produto_id': 10,
              'preco_padrao': 20,
              'valor': 12,
              'origem': 'TABELA',
            },
          ],
          'promotions': [
            {
              'produto_id': 10,
              'id': 101,
              'tipo': 'DE_POR',
              'valor_promocional': 15,
            },
          ],
        },
      });

      expect(result[10]?.valor, 12);
      expect(result[10]?.origem, PrecoOrigem.tabela);
    });

    test('tabela inativa na raiz não deve ser aplicada', () {
      final result = PricingResult.fromJson({
        'data': {
          'tabela_id': 6,
          'nome': 'Atacado',
          'revisao': 2,
          'ativa': false,
          'prices': [
            {
              'produto_id': 8241,
              'preco_padrao': 189,
              'valor': 189,
              'origem': 'PADRAO',
            },
          ],
        },
      });

      expect(result.tabelaAtiva, isFalse);
      expect(result.precosDeTabela, isEmpty);
    });

    test(
      'payload sem itens reconhecíveis retorna vazio e chama onUnparsed',
      () {
        var chamou = false;
        final result = PricingResult.fromJson({
          'data': {'total': 100},
        }, onUnparsed: (_) => chamou = true);

        expect(result.precos, isEmpty);
        expect(chamou, isTrue);
      },
    );

    test('ignora itens sem produto_id ou valor', () {
      final result = PricingResult.fromJson({
        'items': [
          {'produto_id': 1},
          {'valor': 10.0},
          {'produto_id': 2, 'valor': 5.0},
        ],
      });

      expect(result.precos.length, 1);
      expect(result[2]?.valor, 5.0);
    });
  });
}
