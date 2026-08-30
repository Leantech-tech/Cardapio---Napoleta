import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../data/api_config.dart';
import '../models/cart_item.dart';
import '../models/order_checkout_data.dart';
import 'api_client.dart';

/// Serviço responsável por persistir pedidos feitos pelo totem no módulo
/// Balcão do Minha Loja.
///
/// Grava em uma única transação as tabelas:
/// - `balcao_pedido`
/// - `balcao_pedido_item`
/// - `balcao_pedido_item_modificador`
///
/// A fila de impressão (`fila_impressao`) é preenchida automaticamente pelo
/// backend. O Cardápio NÃO deve inserir diretamente nessa tabela.
///
/// Usa a rota única `POST /api/v1/balcao/orders`.
class BalcaoPedidoService {
  final ApiClient _api = ApiClient();

  /// Cria o pedido de balcão no backend e retorna o mapa do pedido criado.
  Future<Map<String, dynamic>> salvarPedido(
    List<CartItem> itens,
    OrderCheckoutData checkoutData, {
    required String usuarioId,
  }) async {
    final payload = <String, dynamic>{
      'empresa_id': ApiConfig.empresaId,
      'pessoa_id': checkoutData.customerId,
      'cliente_nome': checkoutData.nome,
      'observacao': '',
      'usuario_id': usuarioId,
      'items': itens.map(_construirItem).toList(),
    };

    debugPrint('[BalcaoPedidoService] payload: ${jsonEncode(payload)}');

    final uri = _api.buildUri('/api/v1/balcao/orders');
    final response = await _api.post(uri, body: payload);

    debugPrint('[BalcaoPedidoService] status: ${response.statusCode}');
    debugPrint('[BalcaoPedidoService] body: ${response.body}');

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return body;
    }
    return {'response': body};
  }

  Map<String, dynamic> _construirItem(CartItem item) {
    return {
      'produto_id': int.tryParse(item.productId) ?? 0,
      'quantidade': item.quantity,
      'observacao': item.observation ?? '',
      'modifiers': _construirModificadores(item),
    };
  }

  List<Map<String, dynamic>> _construirModificadores(CartItem item) {
    final modificadores = <Map<String, dynamic>>[];

    for (final entry in item.selectedOptions.entries) {
      for (final optionId in entry.value) {
        final id = int.tryParse(optionId);
        if (id == null) continue;
        modificadores.add({
          'grupo_modificador_item_id': id,
          'quantidade': item.selectedOptionQuantities[optionId] ?? 1,
        });
      }
    }

    return modificadores;
  }

  /// Lista os pedidos de balcão da empresa.
  ///
  /// [status] filtra por status (ex: `EM_PREPARO`, `PRONTO`).
  /// [search] filtra por número do pedido ou nome do cliente.
  Future<List<Map<String, dynamic>>> listarPedidos({
    String? status,
    String? search,
    bool includeFinalized = false,
  }) async {
    final query = <String, String>{
      'empresa_id': ApiConfig.empresaId.toString(),
    };

    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }
    query['include_finalized'] = includeFinalized.toString();

    final uri = _api.buildUri('/api/v1/balcao/orders', queryParams: query);
    final response = await _api.get(uri);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  /// Busca um pedido de balcão pelo id.
  Future<Map<String, dynamic>?> buscarPedido(int id) async {
    final uri = _api.buildUri(
      '/api/v1/balcao/orders/$id',
      queryParams: {'empresa_id': ApiConfig.empresaId.toString()},
    );
    final response = await _api.get(uri);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  /// Altera o status de um pedido de balcão.
  Future<Map<String, dynamic>?> alterarStatus(
    int id,
    String status, {
    required String usuarioId,
    String motivo = '',
  }) async {
    final payload = {
      'empresa_id': ApiConfig.empresaId,
      'status': status,
      'usuario_id': usuarioId,
      'motivo': motivo,
    };

    final uri = _api.buildUri('/api/v1/balcao/orders/$id/status');
    final response = await _api.post(uri, body: payload);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return null;
  }
}
