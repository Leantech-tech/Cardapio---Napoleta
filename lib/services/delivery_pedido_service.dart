import 'dart:convert';

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
    final payload = <String, dynamic>{
      'empresa_id': ApiConfig.empresaId,
      'pessoa_id': checkoutData.customerId,
      'cliente_nome': checkoutData.nome,
      'cliente_telefone': '',
      'tipo_atendimento': checkoutData.isEntrega ? 'ENTREGA' : 'RETIRADA',
      'geo_endereco_id': checkoutData.addressId,
      'cotacao_token': '',
      'endereco_logradouro': checkoutData.rua,
      'endereco_numero': '',
      'endereco_complemento': '',
      'endereco_bairro': checkoutData.bairro,
      'endereco_cidade': checkoutData.cidade,
      'endereco_uf': checkoutData.estado.toUpperCase(),
      'endereco_cep': checkoutData.cep,
      'endereco_referencia': '',
      'observacao': '',
      'usuario_id': '',
      'items': itens.map(_construirItem).toList(),
    };

    final uri = _api.buildUri('/api/v1/delivery/orders');
    final response = await _api.post(uri, body: payload);

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
}
