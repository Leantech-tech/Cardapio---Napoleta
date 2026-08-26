import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tachao_menu/models/order_tracking_status.dart';
import 'package:tachao_menu/services/order_tracking_service.dart';

void main() {
  group('OrderTrackingConfig.fromString', () {
    test('mapeia status padrão do backend', () {
      expect(
        OrderTrackingConfig.fromString('AGUARDANDO_CONFIRMACAO'),
        OrderStatus.aguardandoConfirmacao,
      );
      expect(
        OrderTrackingConfig.fromString('CONFIRMADO'),
        OrderStatus.confirmado,
      );
      expect(
        OrderTrackingConfig.fromString('EM_PREPARO'),
        OrderStatus.confirmado,
      );
      expect(
        OrderTrackingConfig.fromString('EM_TRANSITO'),
        OrderStatus.emTransito,
      );
      expect(
        OrderTrackingConfig.fromString('ENTREGUE'),
        OrderStatus.entregue,
      );
      expect(
        OrderTrackingConfig.fromString('CANCELADO'),
        OrderStatus.cancelado,
      );
    });

    test('ignora caixa e espaços', () {
      expect(
        OrderTrackingConfig.fromString('  entregue  '),
        OrderStatus.entregue,
      );
      expect(
        OrderTrackingConfig.fromString('Em Transito'),
        OrderStatus.emTransito,
      );
    });

    test('aceita variações com hífen e underscore', () {
      expect(
        OrderTrackingConfig.fromString('em-preparo'),
        OrderStatus.confirmado,
      );
      expect(
        OrderTrackingConfig.fromString('saiu_para_entrega'),
        OrderStatus.emTransito,
      );
    });

    test('valor desconhecido cai em aguardando confirmação', () {
      expect(
        OrderTrackingConfig.fromString('STATUS_INVALIDO'),
        OrderStatus.aguardandoConfirmacao,
      );
      expect(
        OrderTrackingConfig.fromString(null),
        OrderStatus.aguardandoConfirmacao,
      );
    });
  });

  group('OrderTrackingConfig.isTerminal', () {
    test('entregue e cancelado são terminais', () {
      expect(OrderTrackingConfig.isTerminal(OrderStatus.entregue), isTrue);
      expect(OrderTrackingConfig.isTerminal(OrderStatus.cancelado), isTrue);
      expect(
        OrderTrackingConfig.isTerminal(OrderStatus.aguardandoConfirmacao),
        isFalse,
      );
      expect(OrderTrackingConfig.isTerminal(OrderStatus.emTransito), isFalse);
    });
  });

  group('OrderTrackingService.extractStatus', () {
    final service = OrderTrackingService();

    test('extrai status do mapa', () {
      expect(
        service.extractStatus({'status': 'EM_PREPARO'}),
        OrderStatus.confirmado,
      );
    });

    test('retorna aguardando quando mapa é nulo ou sem status', () {
      expect(service.extractStatus(null), OrderStatus.aguardandoConfirmacao);
      expect(
        service.extractStatus({'id': 1}),
        OrderStatus.aguardandoConfirmacao,
      );
    });
  });

  group('OrderTrackingService.extractIsRetirada', () {
    final service = OrderTrackingService();

    test('identifica retirada pelo tipo_atendimento', () {
      expect(service.extractIsRetirada({'tipo_atendimento': 'RETIRADA'}), isTrue);
      expect(service.extractIsRetirada({'tipo_atendimento': 'BALCAO'}), isTrue);
      expect(service.extractIsRetirada({'tipo_atendimento': 'ENTREGA'}), isFalse);
    });

    test('identifica retirada pelo tipo_entrega', () {
      expect(service.extractIsRetirada({'tipo_entrega': 'Retirar na loja'}), isTrue);
      expect(service.extractIsRetirada({'tipo_entrega': 'Entrega'}), isFalse);
    });

    test('retorna false quando não há tipo', () {
      expect(service.extractIsRetirada(null), isFalse);
      expect(service.extractIsRetirada({}), isFalse);
    });
  });

  group('OrderTrackingConfig.stepsFor', () {
    test('entrega tem 4 passos incluindo emTransito', () {
      final steps = OrderTrackingConfig.stepsFor(isRetirada: false);
      expect(steps.map((s) => s.status), [
        OrderStatus.aguardandoConfirmacao,
        OrderStatus.confirmado,
        OrderStatus.emTransito,
        OrderStatus.entregue,
      ]);
    });

    test('retirada tem 3 passos incluindo prontoParaRetirada', () {
      final steps = OrderTrackingConfig.stepsFor(isRetirada: true);
      expect(steps.map((s) => s.status), [
        OrderStatus.aguardandoConfirmacao,
        OrderStatus.confirmado,
        OrderStatus.prontoParaRetirada,
      ]);
    });
  });

  group('OrderTrackingService.extractUpdatedAt', () {
    final service = OrderTrackingService();

    test('usa updated_at quando disponível', () {
      final date = DateTime(2026, 8, 25, 14, 30);
      expect(
        service.extractUpdatedAt({
          'updated_at': date.toIso8601String(),
        }),
        date,
      );
    });

    test('usa created_at como fallback', () {
      final date = DateTime(2026, 8, 25, 14, 30);
      expect(
        service.extractUpdatedAt({
          'created_at': date.toIso8601String(),
        }),
        date,
      );
    });

    test('retorna null quando não há timestamps', () {
      expect(service.extractUpdatedAt({}), isNull);
      expect(service.extractUpdatedAt(null), isNull);
    });

    test('converte timestamp UTC para horário local', () {
      final dateUtc = DateTime.utc(2026, 8, 26, 19, 5, 51);
      final result = service.extractUpdatedAt({
        'updated_at': dateUtc.toIso8601String(),
      });
      expect(result, isNotNull);
      expect(result!.toLocal(), dateUtc.toLocal());
    });
  });

  group('OrderTrackingService cache local', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('salva e recupera pedido por CPF', () async {
      await OrderTrackingService.saveLastOrderByCpf('123.456.789-00', 42);

      final service = OrderTrackingService();
      expect(await service.findLatestOpenOrderByCpf('12345678900'), 42);
    });

    test('ignora CPF inválido ao salvar', () async {
      await OrderTrackingService.saveLastOrderByCpf('123', 42);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_order_by_cpf'), isNull);
    });

    test('limpa vínculo ao chamar clearLastOrderByCpf', () async {
      await OrderTrackingService.saveLastOrderByCpf('123.456.789-00', 42);
      await OrderTrackingService.clearLastOrderByCpf('12345678900');

      final service = OrderTrackingService();
      expect(await service.findLatestOpenOrderByCpf('12345678900'), isNull);
    });
  });
}
