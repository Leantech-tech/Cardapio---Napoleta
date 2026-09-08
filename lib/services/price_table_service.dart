import 'package:flutter/foundation.dart';

import 'db_client.dart';

class PriceTableService {
  final DbClient _db = DbClient();

  /// Retorna o mapa produto_id -> valor dos itens da tabela de preço.
  /// Retorna um mapa vazio quando a tabela não pode ser consultada
  /// (nesse caso o app mantém os preços normais).
  Future<Map<int, double>> buscarPrecos(int tabelaPrecoId) async {
    try {
      final result = await _db.select(
        'tabela_preco_item',
        filters: {'eq_tabela_preco_id': tabelaPrecoId.toString()},
        columns: 'produto_id,valor',
      );

      final precos = <int, double>{};
      for (final row in result) {
        final produtoId = (row['produto_id'] as num?)?.toInt();
        final valor = (row['valor'] as num?)?.toDouble();
        if (produtoId != null && valor != null) {
          precos[produtoId] = valor;
        }
      }
      return precos;
    } on Exception catch (e) {
      debugPrint('PriceTableService: erro ao buscar tabela $tabelaPrecoId: $e');
      return {};
    }
  }
}
