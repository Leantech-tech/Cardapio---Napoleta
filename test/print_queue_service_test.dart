import 'package:flutter_test/flutter_test.dart';
import 'package:tachao_menu/models/cart_item.dart';
import 'package:tachao_menu/models/order_checkout_data.dart';
import 'package:tachao_menu/models/payment_method.dart';
import 'package:tachao_menu/services/db_client.dart';
import 'package:tachao_menu/services/print_queue_service.dart';

class _FakeDbClient extends DbClient {
  Object? payload;

  @override
  Future<List<Map<String, dynamic>>> insert(
    String table,
    Object payload,
  ) async {
    expect(table, 'fila_impressao');
    this.payload = payload;
    return const [];
  }
}

void main() {
  const checkout = OrderCheckoutData(
    tipoEntrega: TipoEntrega.retirada,
    nome: 'Cliente',
    cpf: '00000000000',
    paymentMethod: PaymentMethod(
      id: 1,
      descricao: 'Crédito',
      permiteParcelamento: false,
      parcelasMaximas: 1,
      intervaloPadrao: 30,
      isAprazo: false,
    ),
  );

  test(
    'fila do link usa o preço autoritativo devolvido pelo Delivery',
    () async {
      final db = _FakeDbClient();
      final service = PrintQueueService(db: db);
      final cartItem = CartItem(
        id: 'linha-1',
        productId: '8241',
        name: 'AÇAÍ 10L',
        imagePath: '',
        basePrice: 189,
        quantity: 3,
      );

      await service.adicionarPedido(
        itens: [cartItem],
        checkoutData: checkout,
        isTotem: false,
        deliveryPedidoId: 44,
        valorTotalPedido: 300,
        itensPersistidos: const [
          {'produto_id': 8241, 'valor_unitario': 100, 'valor_total_item': 300},
        ],
      );

      final row = db.payload! as Map<String, dynamic>;
      final content = row['conteudo']! as Map<String, dynamic>;
      final items = content['itens']! as List<dynamic>;
      final item = items.single as Map<String, dynamic>;
      expect(item['valor_unitario'], 100);
      expect(item['valor_total'], 300);
      expect(content['valor_total_pedido'], 300);
    },
  );

  test(
    'fila mantém o carrinho quando não há snapshot correspondente',
    () async {
      final db = _FakeDbClient();
      final service = PrintQueueService(db: db);
      final cartItem = CartItem(
        id: 'linha-1',
        productId: '8241',
        name: 'AÇAÍ 10L',
        imagePath: '',
        basePrice: 189,
        quantity: 1,
      );

      await service.adicionarPedido(
        itens: [cartItem],
        checkoutData: checkout,
        isTotem: false,
        itensPersistidos: const [
          {'produto_id': 9999, 'valor_unitario': 1, 'valor_total_item': 1},
        ],
      );

      final row = db.payload! as Map<String, dynamic>;
      final content = row['conteudo']! as Map<String, dynamic>;
      final items = content['itens']! as List<dynamic>;
      final item = items.single as Map<String, dynamic>;
      expect(item['valor_unitario'], 189);
      expect(item['valor_total'], 189);
    },
  );
}
