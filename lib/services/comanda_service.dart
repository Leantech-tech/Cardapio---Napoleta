import '../models/cart_item.dart';
import 'db_client.dart';

class ComandaService {
  final DbClient _db = DbClient();

  Future<Map<String, dynamic>?> buscarComanda(String numero, int empresaId) async {
    return _db.selectSingle(
      'comanda',
      filters: {
        'eq_empresa_id': empresaId.toString(),
        'eq_numero': (int.tryParse(numero) ?? 0).toString(),
      },
    );
  }

  Future<Map<String, dynamic>> criarComanda(
    String numero,
    int empresaId, {
    int? mesaId,
  }) async {
    final now = DateTime.now().toIso8601String();
    return _db.insertSingle('comanda', {
      'empresa_id': empresaId,
      'numero': int.tryParse(numero) ?? 0,
      'mesa_id': mesaId,
      'status': 'ABERTA',
      'hora_abertura': now,
      'hora_ultimo_pedido': now,
      'valor_total': 0,
      'is_ativo': true,
    });
  }

  Future<void> adicionarItens(
    int comandaId,
    int empresaId,
    List<CartItem> itens,
  ) async {
    for (final item in itens) {
      final response = await _db.insertSingle('comanda_item', {
        'empresa_id': empresaId,
        'comanda_id': comandaId,
        'produto_id': int.tryParse(item.productId) ?? 0,
        'quantidade': item.quantity,
        'valor_unitario': item.unitPrice,
        'valor_total_item': item.total,
        'observacao': item.observation,
        'status': 'ATIVO',
        'created_at': DateTime.now().toIso8601String(),
      });

      final comandaItemId = response['id'] as int;

      if (item.selectedOptions.isNotEmpty) {
        final modificadores = <Map<String, dynamic>>[];

        for (final entry in item.selectedOptions.entries) {
          for (final optionId in entry.value) {
            final vrAdicional = item.selectedOptionPrices[optionId] ?? 0.0;
            final qty = item.selectedOptionQuantities[optionId] ?? 1;
            modificadores.add({
              'comanda_item_id': comandaItemId,
              'grupo_modificador_item_id': int.tryParse(optionId) ?? 0,
              'quantidade': qty,
              'vr_adicional': vrAdicional,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }

        if (modificadores.isNotEmpty) {
          await _db.insert('comanda_item_modificador', modificadores);
        }
      }
    }
  }

  Future<void> atualizarTotalComanda(int comandaId) async {
    final response = await _db.select(
      'comanda_item',
      filters: {
        'eq_comanda_id': comandaId.toString(),
        'eq_status': 'ATIVO',
      },
    );

    double total = 0;
    for (final row in response) {
      total += (row['valor_total_item'] as num?)?.toDouble() ?? 0;
    }

    await _db.update(
      'comanda',
      {
        'valor_total': total,
        'hora_ultimo_pedido': DateTime.now().toIso8601String(),
      },
      filters: {'eq_id': comandaId.toString()},
    );
  }

  Future<void> registrarLog(
    int comandaId,
    int? mesaId,
    int empresaId,
    String acao,
    Map<String, dynamic> detalhes,
  ) async {
    await _db.insert('comanda_log', {
      'empresa_id': empresaId,
      'comanda_id': comandaId,
      'mesa_id': mesaId,
      'acao': acao,
      'detalhes': detalhes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> buscarItensComanda(int comandaId) async {
    final itens = await _db.select(
      'comanda_item',
      filters: {
        'eq_comanda_id': comandaId.toString(),
        'eq_status': 'ATIVO',
      },
      order: 'created_at.desc',
    );

    if (itens.isEmpty) return [];

    final produtoIds = itens
        .map((i) => i['produto_id'])
        .whereType<int>()
        .toSet()
        .toList();

    Map<int, Map<String, dynamic>> produtosPorId = {};
    if (produtoIds.isNotEmpty) {
      final produtos = await _db.select(
        'produto',
        filters: {
          'in_id': produtoIds.join(','),
        },
        columns: 'id,nome,foto_url',
      );
      produtosPorId = {
        for (final p in produtos) p['id'] as int: p,
      };
    }

    return itens.map((item) {
      final produtoId = item['produto_id'] as int?;
      final produto = produtoId != null ? produtosPorId[produtoId] : null;
      return {
        ...item,
        'produto': produto,
      };
    }).toList();
  }

  Future<void> adicionarFilaImpressao(
    int comandaId,
    int empresaId,
    List<CartItem> itens,
    String numeroComanda,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('=== NOVO PEDIDO - COMANDA $numeroComanda ===');
    for (final item in itens) {
      buffer.writeln('${item.quantity}x ${item.name}');
      if (item.selectedOptions.isNotEmpty) {
        buffer.writeln('   Opções: ${item.selectedOptionsDisplay}');
      }
      if (item.observation != null && item.observation!.isNotEmpty) {
        buffer.writeln('   Obs: ${item.observation}');
      }
    }

    await _db.insert('fila_impressao', {
      'empresa_id': empresaId,
      'setor': 'Cozinha',
      'conteudo': {'texto': buffer.toString()},
      'impresso': false,
      'criado_em': DateTime.now().toIso8601String(),
    });
  }
}
