import 'package:flutter_test/flutter_test.dart';
import 'package:tachao_menu/services/customer_service.dart';

void main() {
  group('CustomerService.somenteNumeros', () {
    test('remove máscara e caracteres não numéricos', () {
      expect(CustomerService.somenteNumeros('315.474.858-09'), '31547485809');
      expect(CustomerService.somenteNumeros('31547485809'), '31547485809');
      expect(CustomerService.somenteNumeros('abc 315.474.858-09 xyz'), '31547485809');
      expect(CustomerService.somenteNumeros(''), '');
    });
  });

  group('CustomerService.filtrarCandidatos', () {
    Map<String, dynamic> pessoa({
      required int id,
      int empresaId = 9,
      bool isCliente = true,
      bool? isAtivo,
      bool? isExcluido,
      String createdAt = '2024-01-01T00:00:00',
    }) {
      return {
        'id': id,
        'empresa_id': empresaId,
        'nome': 'Cliente $id',
        'is_cliente': isCliente,
        'is_ativo': ?isAtivo,
        'is_excluido': ?isExcluido,
        'created_at': createdAt,
      };
    }

    test('retorna cliente ativo da empresa', () {
      final resultado = CustomerService.filtrarCandidatos([
        pessoa(id: 1),
      ], 9);
      expect(resultado?['id'], 1);
    });

    test('campos ausentes usam defaults: ativo=true, excluido=false', () {
      final resultado = CustomerService.filtrarCandidatos([
        pessoa(id: 1, isAtivo: null, isExcluido: null),
      ], 9);
      expect(resultado?['id'], 1);
    });

    test('cliente excluído nunca é retornado', () {
      final resultado = CustomerService.filtrarCandidatos([
        pessoa(id: 1, isExcluido: true),
      ], 9);
      expect(resultado, isNull);
    });

    test('quando todos estão excluídos, resultado é null (cliente não encontrado)', () {
      final resultado = CustomerService.filtrarCandidatos([
        pessoa(id: 1, isExcluido: true),
        pessoa(id: 2, isExcluido: true),
      ], 9);
      expect(resultado, isNull);
    });

    test('prefere o cadastro ativo quando há um excluído com o mesmo CPF', () {
      final resultado = CustomerService.filtrarCandidatos([
        pessoa(id: 1, isExcluido: true, createdAt: '2024-06-01T00:00:00'),
        pessoa(id: 2, isExcluido: false, createdAt: '2024-01-01T00:00:00'),
      ], 9);
      expect(resultado?['id'], 2);
    });

    test('cliente de outra empresa nunca é retornado', () {
      final resultado = CustomerService.filtrarCandidatos([
        pessoa(id: 1, empresaId: 99),
      ], 9);
      expect(resultado, isNull);
    });

    test('pessoa que não é cliente é ignorada', () {
      final resultado = CustomerService.filtrarCandidatos([
        pessoa(id: 1, isCliente: false),
      ], 9);
      expect(resultado, isNull);
    });

    test('pessoa inativa é ignorada', () {
      final resultado = CustomerService.filtrarCandidatos([
        pessoa(id: 1, isAtivo: false),
      ], 9);
      expect(resultado, isNull);
    });

    test('entre vários ativos, prefere o cadastro mais recente', () {
      final resultado = CustomerService.filtrarCandidatos([
        pessoa(id: 1, createdAt: '2023-01-01T00:00:00'),
        pessoa(id: 2, createdAt: '2024-01-01T00:00:00'),
      ], 9);
      expect(resultado?['id'], 2);
    });

    test('cenário real 315.474.858-09: excluído + outra empresa + ativo → retorna o ativo da empresa', () {
      // pessoa 126: CPF sem máscara, excluída; pessoa 1: outra empresa;
      // pessoa 173: CPF com máscara, ativa, cliente da empresa 9.
      final resultado = CustomerService.filtrarCandidatos([
        pessoa(id: 126, isExcluido: true, createdAt: '2026-08-03T17:06:42Z'),
        pessoa(id: 1, empresaId: 1, createdAt: '2026-01-23T19:53:31Z'),
        pessoa(id: 173, createdAt: '2026-09-08T17:52:22Z'),
      ], 9);
      expect(resultado?['id'], 173);
    });

    test('se todos os candidatos estão excluídos em qualquer formato, retorna null', () {
      final resultado = CustomerService.filtrarCandidatos([
        pessoa(id: 126, isExcluido: true, createdAt: '2026-08-03T17:06:42Z'),
        pessoa(id: 1, empresaId: 1, isExcluido: true, createdAt: '2026-01-23T19:53:31Z'),
      ], 9);
      expect(resultado, isNull);
    });
  });
}
