import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_config.dart';
import '../models/order_tracking_status.dart';
import 'api_client.dart';
import 'db_client.dart';

/// Serviço responsável por consultar o status atual de um pedido delivery.
///
/// Utiliza o endpoint específico `GET /api/v1/delivery/orders/{id}`, que é o
/// mesmo usado pelo app Minha Loja para ler e atualizar pedidos. O polling
/// fica a cargo da UI.
class OrderTrackingService {
  final ApiClient _api = ApiClient();
  final DbClient _db = DbClient();

  static const String _lastOrderKey = 'last_order_by_cpf';

  static String _normalizeCpf(String cpf) =>
      cpf.replaceAll(RegExp(r'[^0-9]'), '');

  /// Salva localmente o vínculo CPF → orderId assim que o pedido é criado.
  ///
  /// Permite reabrir o acompanhamento rapidamente sem depender apenas de
  /// consultas ao backend.
  static Future<void> saveLastOrderByCpf(String cpf, int orderId) async {
    final numeros = _normalizeCpf(cpf);
    if (numeros.length != 11) return;

    final prefs = await SharedPreferences.getInstance();
    final map = _readMap(prefs);
    map[numeros] = orderId;
    await prefs.setString(_lastOrderKey, jsonEncode(map));
    debugPrint('[OrderTrackingService] Cache salvo: $numeros -> $orderId');
  }

  /// Remove o vínculo armazenado para o [cpf].
  static Future<void> clearLastOrderByCpf(String cpf) async {
    final numeros = _normalizeCpf(cpf);
    final prefs = await SharedPreferences.getInstance();
    final map = _readMap(prefs);
    map.remove(numeros);
    await prefs.setString(_lastOrderKey, jsonEncode(map));
  }

  static Map<String, dynamic> _readMap(SharedPreferences prefs) {
    final raw = prefs.getString(_lastOrderKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded;
    } catch (_) {
      return {};
    }
  }

  Future<int?> _findLocalOrderByCpf(String cpf) async {
    final numeros = _normalizeCpf(cpf);
    final prefs = await SharedPreferences.getInstance();
    final map = _readMap(prefs);
    final orderId = map[numeros];
    if (orderId is int) return orderId;
    if (orderId is String) return int.tryParse(orderId);
    return null;
  }

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

  /// Busca o último pedido delivery em aberto vinculado ao [cpf].
  ///
  /// Localiza a pessoa pela tabela `pessoa_fisica`, depois consulta
  /// `delivery_pedido` filtrando pela empresa e ordenando do mais recente
  /// para o mais antigo. Ignora pedidos já entregues ou cancelados.
  ///
  /// Retorna o `id` do pedido ou `null` caso não exista pedido em aberto.
  Future<int?> findLatestOpenOrderByCpf(String cpf) async {
    final numeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    debugPrint('[OrderTrackingService] Buscando pedido por CPF: $numeros');
    if (numeros.length != 11) return null;

    // Primeiro tenta recuperar o pedido salvo localmente no momento da compra.
    final localOrderId = await _findLocalOrderByCpf(cpf);
    debugPrint('[OrderTrackingService] pedido local: $localOrderId');
    if (localOrderId != null) {
      try {
        final order = await fetchOrder(localOrderId);
        final status = extractStatus(order);
        if (!OrderTrackingConfig.isTerminal(status)) {
          return localOrderId;
        }
        // Se o pedido local já terminou, limpa o cache e continua a busca.
        await clearLastOrderByCpf(cpf);
      } catch (e) {
        debugPrint('[OrderTrackingService] Erro ao validar pedido local: $e');
      }
    }

    // Fallback: busca pelo vínculo pessoa_fisica → delivery_pedido.
    try {
      final pfResults = await _db.select(
        'pessoa_fisica',
        filters: {'eq_cpf': numeros},
        columns: 'pessoa_id',
        limit: 1,
      );

      debugPrint('[OrderTrackingService] pessoa_fisica results: $pfResults');

      if (pfResults.isEmpty) return null;

      final pessoaId = pfResults.first['pessoa_id'] as int?;
      debugPrint('[OrderTrackingService] pessoa_id encontrado: $pessoaId');
      if (pessoaId == null) return null;

      final orders = await _db.select(
        'delivery_pedido',
        filters: {
          'eq_pessoa_id': pessoaId.toString(),
          'eq_empresa_id': ApiConfig.empresaId.toString(),
        },
        order: 'created_at.desc',
        limit: 1,
        columns: 'id, status, created_at',
      );

      debugPrint('[OrderTrackingService] delivery_pedido orders: $orders');

      if (orders.isEmpty) return null;

      final order = orders.first;
      final status = extractStatus(order);
      debugPrint('[OrderTrackingService] ultimo pedido: $order, status extraido: $status');
      if (OrderTrackingConfig.isTerminal(status)) return null;

      return order['id'] as int?;
    } catch (e) {
      debugPrint('[OrderTrackingService] Erro ao buscar pedido por CPF: $e');
      return null;
    }
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
