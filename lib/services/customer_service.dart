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

  /// Busca o cliente pelo CPF em tempo real (sempre consulta o servidor).
  ///
  /// Regras: CPF sem máscara; restrito à empresa atual; apenas clientes;
  /// excluídos nunca retornados; apenas ativos. Quando todos os cadastros com
  /// o CPF estiverem excluídos, retorna null ("cliente não encontrado").
  Future<Customer?> buscarPorCpf(String cpf) async {
    final numeros = somenteNumeros(cpf);
    if (numeros.isEmpty) return null;

    try {
      // Consulta AMBOS os formatos de gravação do CPF (sem e com máscara) e
      // une os candidatos: o mesmo CPF pode ter cadastros antigos gravados de
      // um jeito e o cadastro atual de outro — consultar só um formato deixaria
      // de achar o cliente válido (ex.: só o excluído em formato sem máscara).
      final consultas = [
        _db.select(
          'pessoa_fisica',
          filters: {'eq_cpf': numeros},
          order: 'created_at.desc',
        ),
        if (numeros.length == 11)
          _db.select(
            'pessoa_fisica',
            filters: {'eq_cpf': _mascararCpf(numeros)},
            order: 'created_at.desc',
          ),
      ];
      final pfResults = (await Future.wait(consultas)).expand((r) => r).toList();

      if (pfResults.isEmpty) return null;

      final pessoaIds = pfResults
          .map((e) => e['pessoa_id'])
          .whereType<num>()
          .map((e) => e.toInt())
          .toSet()
          .toList();
      if (pessoaIds.isEmpty) return null;

      final pessoas = await _db.select(
        'pessoa',
        filters: {'in_id': pessoaIds.join(',')},
        order: 'created_at.desc',
      );

      final elegivel = filtrarCandidatos(pessoas, ApiConfig.empresaId);
      if (elegivel == null) return null;

      final pessoaId = (elegivel['id'] as num).toInt();
      final addresses = await buscarEnderecos(pessoaId);

      return Customer.fromMap(
        {
          ...elegivel,
          'cpf': numeros,
        },
        addresses: addresses,
      );
    } on Exception catch (e) {
      debugPrint('CustomerService: erro ao buscar cliente: $e');
      rethrow;
    }
  }

  /// Aplica as regras de elegibilidade do cliente e retorna o cadastro
  /// vigente, ou null quando nenhum candidato se qualifica.
  static Map<String, dynamic>? filtrarCandidatos(
    List<Map<String, dynamic>> pessoas,
    int empresaId,
  ) {
    final elegiveis = pessoas.where((p) {
      if ((p['empresa_id'] as num?)?.toInt() != empresaId) return false;
      if (!(p['is_cliente'] as bool? ?? false)) return false;
      if (!(p['is_ativo'] as bool? ?? true)) return false;
      if (p['is_excluido'] as bool? ?? false) return false;
      return true;
    }).toList();

    if (elegiveis.isEmpty) return null;

    // Entre vários cadastros ativos com o mesmo CPF, prefere o mais recente.
    elegiveis.sort((a, b) {
      final aData = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bData = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bData.compareTo(aData);
    });
    return elegiveis.first;
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
        'complemento': address.complemento.trim(),
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
        'cpf': somenteNumeros(customer.cpf),
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
            numero: customer.numero,
            complemento: customer.complemento,
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
          numero: address.numero,
          complemento: address.complemento,
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

  static String somenteNumeros(String valor) {
    return valor.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String _mascararCpf(String numeros) {
    if (numeros.length != 11) return numeros;
    return '${numeros.substring(0, 3)}.${numeros.substring(3, 6)}.'
        '${numeros.substring(6, 9)}-${numeros.substring(9, 11)}';
  }
}
