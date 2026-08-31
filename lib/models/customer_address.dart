class CustomerAddress {
  final int? id;
  final int? pessoaId;
  final String tipo;
  final String rua;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;
  final bool principal;
  final DateTime? createdAt;

  const CustomerAddress({
    this.id,
    this.pessoaId,
    this.tipo = 'entrega',
    this.rua = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.cep = '',
    this.principal = false,
    this.createdAt,
  });

  factory CustomerAddress.fromMap(Map<String, dynamic> map) {
    return CustomerAddress(
      id: map['id'] as int?,
      pessoaId: map['pessoa_id'] as int?,
      tipo: (map['tipo'] ?? 'entrega').toString(),
      rua: (map['rua'] ?? '').toString(),
      numero: (map['numero'] ?? '').toString(),
      complemento: (map['complemento'] ?? '').toString(),
      bairro: (map['bairro'] ?? '').toString(),
      cidade: (map['cidade'] ?? '').toString(),
      estado: (map['estado'] ?? '').toString(),
      cep: (map['cep'] ?? '').toString(),
      principal: map['principal'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap({int? pessoaIdOverride}) {
    return {
      if (id != null) 'id': id,
      if (pessoaId != null || pessoaIdOverride != null)
        'pessoa_id': pessoaId ?? pessoaIdOverride,
      'tipo': tipo,
      'rua': rua.trim(),
      'numero': numero.trim(),
      'complemento': complemento.trim(),
      'bairro': bairro.trim(),
      'cidade': cidade.trim(),
      'estado': estado.trim().toUpperCase(),
      'cep': cep.trim(),
      'principal': principal,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get endereco {
    final partes = <String>[
      '${rua.trim()}${numero.trim().isNotEmpty ? ', ${numero.trim()}' : ''}${complemento.trim().isNotEmpty ? ' - ${complemento.trim()}' : ''}',
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

  CustomerAddress copyWith({
    int? id,
    int? pessoaId,
    String? tipo,
    String? rua,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? estado,
    String? cep,
    bool? principal,
    DateTime? createdAt,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      pessoaId: pessoaId ?? this.pessoaId,
      tipo: tipo ?? this.tipo,
      rua: rua ?? this.rua,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      cep: cep ?? this.cep,
      principal: principal ?? this.principal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool isSameAddress(CustomerAddress other) {
    return _normalize(rua) == _normalize(other.rua) &&
        _normalize(numero) == _normalize(other.numero) &&
        _normalize(complemento) == _normalize(other.complemento) &&
        _normalize(bairro) == _normalize(other.bairro) &&
        _normalize(cidade) == _normalize(other.cidade) &&
        _normalize(estado) == _normalize(other.estado) &&
        _somenteNumeros(cep) == _somenteNumeros(other.cep);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _somenteNumeros(String valor) {
    return valor.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
