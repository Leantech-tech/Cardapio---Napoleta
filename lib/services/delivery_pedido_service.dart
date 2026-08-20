import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../data/api_config.dart';
import '../models/cart_item.dart';
import '../models/order_checkout_data.dart';
import 'api_client.dart';

/// Serviço responsável por persistir pedidos feitos pelo cardápio digital.
///
/// Grava em uma única transação as tabelas:
/// - `delivery_pedido`
/// - `delivery_pedido_item`
/// - `delivery_pedido_item_modificador`
///
/// Usa a rota única `POST /api/v1/delivery/orders`. Não são feitas chamadas
/// separadas aos endpoints `/api/v1/db/...` dessas tabelas.
class DeliveryPedidoService {
  final ApiClient _api = ApiClient();

  /// Cria o pedido completo no banco (em uma única transação) e retorna o
  /// mapa do pedido criado.
  Future<Map<String, dynamic>> salvarPedido(
    List<CartItem> itens,
    OrderCheckoutData checkoutData, {
    double taxaEntrega = 0.0,
  }) async {
    final subtotal = itens.fold<double>(0, (sum, item) => sum + item.total);
    final valorTotal = subtotal + taxaEntrega;

    final payload = <String, dynamic>{
      'empresa_id': ApiConfig.empresaId,
      'pessoa_id': checkoutData.customerId,
      'cliente_nome': checkoutData.nome,
      'cliente_telefone': '',
      'tipo_atendimento': checkoutData.isEntrega ? 'ENTREGA' : 'RETIRADA',
      'status': 'AGUARDANDO_CONFIRMACAO',
      'geo_endereco_id': checkoutData.addressId,
      'cotacao_token': '',
      'endereco_logradouro': checkoutData.rua,
      'endereco_numero': checkoutData.numero,
      'endereco_complemento': '',
      'endereco_bairro': checkoutData.bairro,
      'endereco_cidade': checkoutData.cidade,
      'endereco_uf': checkoutData.estado.toUpperCase(),
      'endereco_cep': checkoutData.cep,
      'endereco_referencia': '',
      'observacao': '',
      'usuario_id': '',
      'subtotal': subtotal,
      'taxa_entrega': taxaEntrega,
      'valor_total': valorTotal,
      'items': itens.map(_construirItem).toList(),
    };

    debugPrint('[DeliveryPedidoService] payload: ${jsonEncode(payload)}');

    final uri = _api.buildUri('/api/v1/delivery/orders');
    final response = await _api.post(uri, body: payload);

    debugPrint('[DeliveryPedidoService] status: ${response.statusCode}');
    debugPrint('[DeliveryPedidoService] body: ${response.body}');

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
      'produto_nome': item.name,
      'quantidade': item.quantity,
      'valor_unitario': item.unitPrice,
      'valor_total_item': item.total,
      'observacao': item.observation ?? '',
      'status': 'ATIVO',
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
          'nome': item.selectedOptionsDisplay.isNotEmpty
              ? item.selectedOptionsDisplay
              : '',
          'quantidade': item.selectedOptionQuantities[optionId] ?? 1,
          'valor_adicional': item.selectedOptionPrices[optionId] ?? 0.0,
        });
      }
    }

    return modificadores;
  }
}
