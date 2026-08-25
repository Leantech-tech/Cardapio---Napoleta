import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/api_config.dart';
import '../models/order_tracking_status.dart';
import 'api_client.dart';

/// Serviço responsável por consultar o status atual de um pedido delivery.
///
/// Utiliza o endpoint específico `GET /api/v1/delivery/orders/{id}`, que é o
/// mesmo usado pelo app Minha Loja para ler e atualizar pedidos. O polling
/// fica a cargo da UI.
class OrderTrackingService {
  final ApiClient _api = ApiClient();

  /// Busca o pedido [orderId] no endpoint de delivery.
  ///
  /// Retorna `null` se o pedido não for encontrado ou se a requisição falhar.
  Future<Map<String, dynamic>?> fetchOrder(int orderId) async {
    try {
      final uri = _api.buildUri(
        '/api/v1/delivery/orders/$orderId',
        queryParams: {'empresa_id': ApiConfig.empresaId.toString()},
      );
      final response = await _api.get(uri);
      final responseBody = jsonDecode(response.body);

      debugPrint('[OrderTrackingService] HTTP ${response.statusCode}');
      debugPrint('[OrderTrackingService] Body: ${response.body}');

      if (responseBody is! Map<String, dynamic>) {
        debugPrint('[OrderTrackingService] Resposta não é um objeto JSON.');
        return null;
      }

      final data = responseBody['data'];
      if (data is Map<String, dynamic>) {
        return _unwrapOrder(data);
      }

      return _unwrapOrder(responseBody);
    } catch (e) {
      // Em caso de falha de rede/consulta, retorna null para que a UI possa
      // tentar novamente no próximo ciclo de polling sem quebrar o popup.
      debugPrint('[OrderTrackingService] Erro ao buscar pedido $orderId: $e');
      return null;
    }
  }

  /// Desembrulha possíveis formatos de resposta do backend.
  Map<String, dynamic>? _unwrapOrder(Map<String, dynamic> map) {
    for (final key in const ['pedido', 'order', 'delivery_pedido']) {
      final value = map[key];
      if (value is Map<String, dynamic>) return value;
    }
    return map;
  }

  /// Extrai o status atual do mapa retornado pelo backend.
  ///
  /// Tenta ler os campos `status`, `situacao` e `delivery_status`, pois
  /// diferentes apps (Minha Loja, cardápio, etc.) podem usar nomes distintos.
  /// Mantém o status anterior quando o pedido não é encontrado.
  OrderStatus extractStatus(Map<String, dynamic>? order) {
    if (order == null) return OrderStatus.aguardandoConfirmacao;

    final raw = order['status'] as String? ??
        order['situacao'] as String? ??
        order['delivery_status'] as String? ??
        order['estado'] as String?;

    debugPrint('[OrderTrackingService] Status bruto extraído: $raw');
    return OrderTrackingConfig.fromString(raw);
  }

  /// Tenta extrair o timestamp de atualização do pedido.
  ///
  /// Usa `updated_at`; se ausente, usa `created_at`. Retorna `null` se nenhum
  /// dos dois estiver disponível.
  DateTime? extractUpdatedAt(Map<String, dynamic>? order) {
    if (order == null) return null;
    final raw = order['updated_at'] as String? ?? order['created_at'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
