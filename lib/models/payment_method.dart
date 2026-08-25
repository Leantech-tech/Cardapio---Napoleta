class PaymentMethod {
  final int id;
  final String descricao;
  final bool permiteParcelamento;
  final int parcelasMaximas;
  final int intervaloPadrao;
  final bool isAprazo;
  final String? tipoVencimento;
  final int? diaVencimento;
  final int? diaCorte;

  const PaymentMethod({
    required this.id,
    required this.descricao,
    required this.permiteParcelamento,
    required this.parcelasMaximas,
    required this.intervaloPadrao,
    required this.isAprazo,
    this.tipoVencimento,
    this.diaVencimento,
    this.diaCorte,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      descricao: (json['descricao'] as String?)?.trim() ?? '',
      permiteParcelamento: json['permite_parcelamento'] as bool? ?? false,
      parcelasMaximas: json['parcelas_maximas'] as int? ?? 1,
      intervaloPadrao: json['intervalo_padrao'] as int? ?? 30,
      isAprazo: json['is_aprazo'] as bool? ?? false,
      tipoVencimento: json['tipo_vencimento'] as String?,
      diaVencimento: json['dia_vencimento'] as int?,
      diaCorte: json['dia_corte'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'permite_parcelamento': permiteParcelamento,
      'parcelas_maximas': parcelasMaximas,
      'intervalo_padrao': intervaloPadrao,
      'is_aprazo': isAprazo,
      'tipo_vencimento': tipoVencimento,
      'dia_vencimento': diaVencimento,
      'dia_corte': diaCorte,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethod &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PaymentMethod(id: $id, descricao: $descricao)';
}
