import 'package:flutter_test/flutter_test.dart';
import 'package:tachao_menu/services/pricing_service.dart';

void main() {
  group('PricingItemRequest', () {
    test('item do carrinho participa da promoção por padrão', () {
      const item = PricingItemRequest(produtoId: 10, quantidade: 3);

      expect(item.toJson()['aplica_promocao'], isTrue);
    });

    test(
      'item usado apenas para precificar o menu não participa da promoção',
      () {
        const item = PricingItemRequest(
          produtoId: 10,
          quantidade: 1,
          aplicaPromocao: false,
        );

        expect(item.toJson()['aplica_promocao'], isFalse);
      },
    );
  });
}
