class Customer {
  final int? id;
  final String nome;
  final String cpf;
  final String endereco;
  final DateTime? createdAt;

  const Customer({
    this.id,
    required this.nome,
    required this.cpf,
    required this.endereco,
    this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      nome: (map['nome'] ?? '').toString(),
      cpf: (map['cpf'] ?? '').toString(),
      endereco: (map['endereco'] ?? '').toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome.trim(),
      'cpf': _somenteNumeros(cpf),
      'endereco': endereco.trim(),
      'created_at': createdAt?.toIso8601String(),
    };
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
