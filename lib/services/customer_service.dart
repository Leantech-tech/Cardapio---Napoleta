import 'package:flutter/foundation.dart';

import '../data/api_config.dart';
import '../models/customer.dart';
import '../models/customer_address.dart';
import 'db_client.dart';

class CustomerService {
  final DbClient _db = DbClient();

  Future<List<CustomerAddress>> buscarEnderecos(int pessoaId) async {
    try {
      final result = await _db.select(
        'pessoa_endereco',
        filters: {'eq_pessoa_id': pessoaId.toString()},
        order: 'created_at.desc',
      );
      return result.map((e) => CustomerAddress.fromMap(e)).toList();
    } on Exception catch (e) {
      debugPrint('CustomerService: erro ao buscar endereços: $e');
      rethrow;
    }
  }

  Future<Customer?> buscarPorCpf(String cpf) async {
    final numeros = _somenteNumeros(cpf);
    if (numeros.isEmpty) return null;

    try {
      final pfResults = await _db.select(
        'pessoa_fisica',
        filters: {'eq_cpf': numeros},
        order: 'created_at.desc',
        limit: 1,
      );
      final pfResult = pfResults.isEmpty ? null : pfResults.first;

      if (pfResult == null) return null;

      final pessoaId = pfResult['pessoa_id'] as int?;
      if (pessoaId == null) return null;

      final pessoaResults = await _db.select(
        'pessoa',
        filters: {'eq_id': pessoaId.toString()},
        order: 'created_at.desc',
        limit: 1,
      );
      final pessoa = pessoaResults.isEmpty ? null : pessoaResults.first;

      if (pessoa == null) return null;

      final addresses = await buscarEnderecos(pessoaId);

      return Customer.fromMap(
        {
          ...pessoa,
          'cpf': numeros,
        },
        addresses: addresses,
      );
    } on Exception catch (e) {
      debugPrint('CustomerService: erro ao buscar cliente: $e');
      rethrow;
    }
  }

  Future<CustomerAddress> criarEndereco(
    int pessoaId,
    CustomerAddress address, {
    String tipoEndereco = 'entrega',
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final result = await _db.insertSingle('pessoa_endereco', {
        'pessoa_id': pessoaId,
        'empresa_id': ApiConfig.empresaId,
        'tipo': tipoEndereco,
        'rua': address.rua.trim(),
        'numero': address.numero.trim(),
        'bairro': address.bairro.trim(),
        'cidade': address.cidade.trim(),
        'estado': address.estado.trim().toUpperCase(),
        'cep': address.cep.trim(),
        'principal': address.principal,
        'created_at': now,
        'updated_at': now,
      });

      return CustomerAddress.fromMap(result);
    } on Exception catch (e) {
      debugPrint('CustomerService: erro ao criar endereço: $e');
      rethrow;
    }
  }

  Future<Customer> criar(
    Customer customer, {
    String tipoEndereco = 'entrega',
  }) async {
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

      CustomerAddress? createdAddress;
      final temEndereco = customer.rua.trim().isNotEmpty ||
          customer.bairro.trim().isNotEmpty ||
          customer.cidade.trim().isNotEmpty ||
          customer.estado.trim().isNotEmpty ||
          customer.cep.trim().isNotEmpty;

      if (temEndereco) {
        createdAddress = await criarEndereco(
          pessoaId,
          CustomerAddress(
            rua: customer.rua,
            bairro: customer.bairro,
            cidade: customer.cidade,
            estado: customer.estado,
            cep: customer.cep,
            principal: true,
          ),
          tipoEndereco: tipoEndereco,
        );
        debugPrint('CustomerService: pessoa_endereco criada (tipo=$tipoEndereco)');
      }

      return Customer.fromMap(
        {
          ...pessoaResult,
          'cpf': customer.cpf,
        },
        addresses: createdAddress != null ? [createdAddress] : const [],
      );
    } on Exception catch (e) {
      debugPrint('CustomerService: erro ao criar cliente: $e');
      rethrow;
    }
  }

  Future<Customer> buscarOuCriar(
    Customer customer, {
    String tipoEndereco = 'entrega',
  }) async {
    final existente = await buscarPorCpf(customer.cpf);
    if (existente != null) {
      debugPrint('CustomerService: cliente já existente - id=${existente.id}');
      return existente;
    }
    return criar(customer, tipoEndereco: tipoEndereco);
  }

  Future<Customer> salvarClienteEEndereco(
    Customer customer,
    CustomerAddress address, {
    String tipoEndereco = 'entrega',
  }) async {
    final existente = await buscarPorCpf(customer.cpf);

    if (existente == null) {
      return criar(
        Customer(
          id: customer.id,
          nome: customer.nome,
          cpf: customer.cpf,
          rua: address.rua,
          bairro: address.bairro,
          cidade: address.cidade,
          estado: address.estado,
          cep: address.cep,
          createdAt: customer.createdAt,
          addresses: customer.addresses,
        ),
        tipoEndereco: tipoEndereco,
      );
    }

    final pessoaId = existente.id;
    if (pessoaId == null) {
      throw Exception('Cliente existente não possui pessoa_id');
    }

    final jaExiste = existente.addresses.any((a) => a.isSameAddress(address));
    if (jaExiste) {
      debugPrint('CustomerService: endereço já existe para pessoa $pessoaId');
      return existente;
    }

    final novoEndereco = await criarEndereco(
      pessoaId,
      address.copyWith(principal: existente.addresses.isEmpty),
      tipoEndereco: tipoEndereco,
    );

    final addressesAtualizados = [...existente.addresses, novoEndereco];
    return existente.withAddresses(addressesAtualizados);
  }

  static String _somenteNumeros(String valor) {
    return valor.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
