import 'package:flutter/foundation.dart';

import '../data/api_config.dart';
import '../models/customer.dart';
import 'db_client.dart';

class CustomerService {
  final DbClient _db = DbClient();

  Future<Customer?> buscarPorCpf(String cpf) async {
    final numeros = _somenteNumeros(cpf);
    if (numeros.isEmpty) return null;

    try {
      final pfResult = await _db.selectSingle(
        'pessoa_fisica',
        filters: {'eq_cpf': numeros},
      );

      if (pfResult == null) return null;

      final pessoaId = pfResult['pessoa_id'] as int?;
      if (pessoaId == null) return null;

      final pessoa = await _db.selectSingle(
        'pessoa',
        filters: {'eq_id': pessoaId.toString()},
      );

      if (pessoa == null) return null;

      return Customer.fromMap({
        ...pessoa,
        'cpf': numeros,
        'endereco': '',
      });
    } on Exception catch (e) {
      debugPrint('CustomerService: erro ao buscar cliente: $e');
      rethrow;
    }
  }

  Future<Customer> criar(Customer customer) async {
    try {
      debugPrint('CustomerService: criando pessoa para ${customer.nome}');
      final now = DateTime.now().toIso8601String();
      final pessoaResult = await _db.insertSingle('pessoa', {
        'empresa_id': ApiConfig.empresaId,
        'nome': customer.nome.trim(),
        'tipo': 'PF',
        'is_cliente': true,
        'is_ativo': true,
        'is_excluido': false,
        'created_at': now,
        'updated_at': now,
      });

      final pessoaId = pessoaResult['id'] as int;
      debugPrint('CustomerService: pessoa criada com id $pessoaId');

      await _db.insertSingle('pessoa_fisica', {
        'pessoa_id': pessoaId,
        'cpf': _somenteNumeros(customer.cpf),
        'created_at': now,
        'updated_at': now,
      });
      debugPrint('CustomerService: pessoa_fisica criada');

      final enderecoTrimmed = customer.endereco.trim();
      debugPrint('CustomerService: endereco = "$enderecoTrimmed"');
      if (enderecoTrimmed.isNotEmpty) {
        await _db.insertSingle('pessoa_endereco', {
          'pessoa_id': pessoaId,
          'empresa_id': ApiConfig.empresaId,
          'tipo': 'entrega',
          'endereco': enderecoTrimmed,
          'principal': true,
          'created_at': now,
          'updated_at': now,
        });
        debugPrint('CustomerService: pessoa_endereco criada');
      }

      return Customer.fromMap({
        ...pessoaResult,
        'cpf': customer.cpf,
        'endereco': customer.endereco.trim(),
      });
    } on Exception catch (e) {
      debugPrint('CustomerService: erro ao criar cliente: $e');
      rethrow;
    }
  }

  Future<Customer> buscarOuCriar(Customer customer) async {
    final existente = await buscarPorCpf(customer.cpf);
    if (existente != null) {
      debugPrint('CustomerService: cliente ja existente - id=${existente.id}');
      return existente;
    }
    return criar(customer);
  }

  static String _somenteNumeros(String valor) {
    return valor.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
