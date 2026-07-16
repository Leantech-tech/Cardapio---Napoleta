class ProductOption {
  final String id;
  final String name;
  final double priceModifier;

  ProductOption({
    required this.id,
    required this.name,
    this.priceModifier = 0.0,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      id: json['id'].toString(),
      name: json['name'] as String? ?? json['nome'] as String? ?? '',
      priceModifier: (json['price_modifier'] as num?)?.toDouble() ??
          (json['vr_adicional'] as num?)?.toDouble() ??
          0.0,
    );
  }
}

enum OptionGroupType { modificador, adicional }

class ProductOptionGroup {
  final String id;
  final String name;
  final List<ProductOption> options;
  final OptionGroupType type;
  final int qtdMin;
  final int qtdMax;
  final bool isObrigatorio;

  bool get isSingleChoice => type == OptionGroupType.modificador;
  bool get isMultipleChoice => type == OptionGroupType.adicional;

  ProductOptionGroup({
    required this.id,
    required this.name,
    required this.options,
    this.type = OptionGroupType.modificador,
    this.qtdMin = 1,
    this.qtdMax = 1,
    this.isObrigatorio = false,
  });

  factory ProductOptionGroup.fromJson(Map<String, dynamic> json) {
    final optionsList = (json['options'] as List<dynamic>? ??
            json['grupo_modificador_item'] as List<dynamic>? ??
            [])
        .map((o) => ProductOption.fromJson(o as Map<String, dynamic>))
        .toList();

    final tipo = json['tipo'] as String? ?? 'MODIFICADOR';
    final type = tipo.toUpperCase() == 'ADICIONAL'
        ? OptionGroupType.adicional
        : OptionGroupType.modificador;

    return ProductOptionGroup(
      id: json['id'].toString(),
      name: json['name'] as String? ?? json['nome'] as String? ?? '',
      options: optionsList,
      type: type,
      qtdMin: (json['qtd_min'] as num?)?.toInt() ?? 1,
      qtdMax: (json['qtd_max'] as num?)?.toInt() ?? 1,
      isObrigatorio: json['is_obrigatorio'] as bool? ?? false,
    );
  }
}
