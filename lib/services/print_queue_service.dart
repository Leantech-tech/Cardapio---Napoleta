import '../data/api_config.dart';
import '../models/cart_item.dart';
import '../models/order_checkout_data.dart';
import 'db_client.dart';

/// Serviço responsável por enfileirar pedidos para impressão térmica.
///
/// Quando o app opera no modo totem, o pedido não é enviado por WhatsApp
/// nem vinculado a uma comanda: ele é salvo na tabela `fila_impressao` para
/// ser impresso posteriormente em uma impressora térmica de etiqueta.
///
/// Regras de setor:
/// - Pedidos feitos pelo totem -> setor obrigatório 'Balcao'.
/// - Pedidos feitos pelo link  -> setor obrigatório 'Delivery'.
class PrintQueueService {
  final DbClient _db = DbClient();

  static const String _origemTotem = 'totem';
  static const String _origemLink = 'link';
  static const String _setorBalcao = 'Balcao';
  static const String _setorDelivery = 'Delivery';

  /// Insere um pedido completo na fila de impressão.
  ///
  /// O parâmetro [isTotem] define a origem e, consequentemente, o setor:
  /// - `true`  -> origem 'totem', setor 'Balcao'.
  /// - `false` -> origem 'link', setor 'Delivery'.
  Future<void> adicionarPedido({
    required List<CartItem> itens,
    required OrderCheckoutData checkoutData,
    required bool isTotem,
    String? storeAddress,
    int? deliveryPedidoId,
  }) async {
    final empresaId = ApiConfig.empresaId;
    final origem = isTotem ? _origemTotem : _origemLink;
    final setor = isTotem ? _setorBalcao : _setorDelivery;

    final mensagem = _buildMessage(
      itens: itens,
      checkoutData: checkoutData,
      storeAddress: storeAddress,
    );

    final conteudo = <String, dynamic>{
      'itens': itens.map((item) => _itemToJson(item)).toList(),
      'setor': setor,
      'origem': origem,
      'delivery_pedido_id': deliveryPedidoId,
      'impressao_producao_antecipada': true,
      'cliente': {
        'cpf': checkoutData.cpf,
        'nome': checkoutData.nome,
        'endereco': checkoutData.endereco,
        'tipo_entrega': checkoutData.tipoEntregaLabel,
        'forma_pagamento_id': checkoutData.paymentMethod.id.toString(),
        'forma_pagamento': checkoutData.formaPagamentoLabel,
        'pagar_na_entrega': checkoutData.isEntrega,
      },
      'mensagem': mensagem,
      'criado_em': DateTime.now().toIso8601String(),
      'empresa_id': empresaId,
      'total_itens': itens.fold<int>(0, (sum, item) => sum + item.quantity),
      'valor_total': itens.fold<double>(0.0, (sum, item) => sum + item.total),
    };

    await _db.insert('fila_impressao', {
      'empresa_id': empresaId,
      'setor': setor,
      'conteudo': conteudo,
      'impresso': false,
      'criado_em': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic> _itemToJson(CartItem item) {
    final observacao = item.observation?.trim();
    return {
      'id': item.id,
      'produto': item.name,
      'opcoes': item.selectedOptions.entries.expand((entry) {
        return entry.value.map((optionId) {
          return {
            'grupo_id': entry.key,
            'opcao_id': optionId,
            'quantidade': item.selectedOptionQuantities[optionId] ?? 1,
            'valor_adicional': item.selectedOptionPrices[optionId] ?? 0.0,
          };
        });
      }).toList(),
      'observacao': observacao != null && observacao.isNotEmpty ? observacao : null,
      'produto_id': item.productId,
      'quantidade': item.quantity,
      'valor_total': item.total,
      'valor_unitario': item.unitPrice,
    };
  }

  String _buildMessage({
    required List<CartItem> itens,
    required OrderCheckoutData checkoutData,
    required String? storeAddress,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Pedido finalizado!');
    buffer.writeln();

    for (final item in itens) {
      buffer.writeln('• ${item.quantity}x ${item.name}');
    }

    buffer.writeln();
    buffer.writeln(
        'Total de itens: ${itens.fold<int>(0, (sum, item) => sum + item.quantity)}');

    buffer.writeln();
    buffer.writeln('Tipo: ${checkoutData.tipoEntregaLabel}');
    buffer.writeln('Cliente: ${checkoutData.nome}');
    buffer.writeln('CPF: ${checkoutData.cpf}');
    if (checkoutData.endereco.isNotEmpty) {
      buffer.writeln('Endereço: ${checkoutData.endereco}');
    }
    buffer.writeln('Pagamento: ${checkoutData.formaPagamentoLabel}');
    if (checkoutData.isEntrega) {
      buffer.writeln('(O entregador receberá o pagamento na entrega)');
    }

    if (storeAddress != null &&
        storeAddress.isNotEmpty &&
        checkoutData.isRetirada) {
      buffer.writeln();
      buffer.writeln('Endereço da loja para retirada:');
      buffer.writeln(storeAddress);
    }

    return buffer.toString();
  }
}
