import 'customer_address.dart';

class Customer {
  final int? id;
  final String nome;
  final String cpf;
  final String rua;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;
  final DateTime? createdAt;
  final List<CustomerAddress> addresses;

  const Customer({
    this.id,
    required this.nome,
    required this.cpf,
    this.rua = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.cep = '',
    this.createdAt,
    this.addresses = const [],
  });

  factory Customer.fromMap(Map<String, dynamic> map, {List<CustomerAddress>? addresses}) {
    return Customer(
      id: map['id'] as int?,
      nome: (map['nome'] ?? '').toString(),
      cpf: (map['cpf'] ?? '').toString(),
      rua: (map['rua'] ?? '').toString(),
      bairro: (map['bairro'] ?? '').toString(),
      cidade: (map['cidade'] ?? '').toString(),
      estado: (map['estado'] ?? '').toString(),
      cep: (map['cep'] ?? '').toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      addresses: addresses ?? const [],
    );
  }

  CustomerAddress? get mainAddress {
    if (addresses.isEmpty) return null;
    final principal = addresses.cast<CustomerAddress?>().firstWhere(
          (a) => a?.principal == true,
          orElse: () => null,
        );
    return principal ?? addresses.first;
  }

  Customer withAddresses(List<CustomerAddress> addresses) {
    return Customer.fromMap(
      toMap(),
      addresses: addresses,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome.trim(),
      'cpf': _somenteNumeros(cpf),
      'rua': rua.trim(),
      'bairro': bairro.trim(),
      'cidade': cidade.trim(),
      'estado': estado.trim().toUpperCase(),
      'cep': cep.trim(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Endereco completo montado a partir dos campos separados.
  String get endereco {
    final partes = <String>[
      rua.trim(),
      bairro.trim(),
      if (cidade.trim().isNotEmpty && estado.trim().isNotEmpty)
        '${cidade.trim()} - ${estado.trim().toUpperCase()}'
      else if (cidade.trim().isNotEmpty)
        cidade.trim()
      else if (estado.trim().isNotEmpty)
        estado.trim().toUpperCase(),
      cep.trim(),
    ].where((p) => p.isNotEmpty);

    return partes.join(', ');
  }

  static String _somenteNumeros(String valor) {
    return valor.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String get cpfFormatado {
    final numeros = _somenteNumeros(cpf);
    if (numeros.length != 11) return cpf;
    return '${numeros.substring(0, 3)}.${numeros.substring(3, 6)}.${numeros.substring(6, 9)}-${numeros.substring(9, 11)}';
  }
}
