import 'product_option.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imagePath;
  final String categoryId;
  final List<String> ingredients;
  final bool isActive;
  final String? badge;
  final double rating;
  final int prepTimeMinutes;
  final int reviewCount;
  final List<ProductOptionGroup> optionGroups;

  double get minPrice {
    double min = price;
    for (final group in optionGroups) {
      if (group.qtdMin > 0 && group.options.isNotEmpty) {
        final cheapest = group.options
            .map((o) => o.priceModifier)
            .reduce((a, b) => a < b ? a : b);
        min += cheapest;
      }
    }
    return min;
  }

  bool get isRefrigerante => name.toLowerCase().contains('refrigerante');

  String get priceDisplay {
    if (price == 0 && minPrice > 0) {
      return 'A partir de R\$ ${minPrice.toStringAsFixed(2).replaceAll('.', ',')}';
    }
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    required this.categoryId,
    this.ingredients = const [],
    this.isActive = true,
    this.badge,
    this.rating = 4.5,
    this.prepTimeMinutes = 15,
    this.reviewCount = 0,
    this.optionGroups = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parseia optionGroups se vierem no JSON (do backend Go com join)
    List<ProductOptionGroup> groups = const [];
    if (json['produto_grupo_modificador'] != null) {
      final vinculos = json['produto_grupo_modificador'] as List<dynamic>;
      groups = vinculos
          .where((v) => v['grupo_modificador'] != null)
          .map((v) {
            final grupo = v['grupo_modificador'] as Map<String, dynamic>;
            // Injeta is_obrigatorio do vínculo no grupo
            grupo['is_obrigatorio'] = v['is_obrigatorio'];
            return ProductOptionGroup.fromJson(grupo);
          })
          .where((g) => g.options.isNotEmpty)
          .toList();
    } else if (json['option_groups'] != null) {
      groups = (json['option_groups'] as List<dynamic>)
          .map((g) => ProductOptionGroup.fromJson(g as Map<String, dynamic>))
          .toList();
    }

    return Product(
      id: json['id'].toString(),
      name: json['nome'] as String? ?? 'Sem nome',
      description: json['inf_adicionais'] as String? ?? '',
      price: (json['vr_venda'] as num?)?.toDouble() ?? 0.0,
      imagePath: (json['foto_url'] as String? ?? '').isNotEmpty
          ? json['foto_url'] as String
          : json['image_url'] as String? ?? '',
      categoryId: json['categoria_id'].toString(),
      ingredients: const [],
      isActive: json['is_ativo'] as bool? ?? true,
      badge: null,
      rating: 4.5,
      prepTimeMinutes: 15,
      reviewCount: 0,
      optionGroups: groups,
    );
  }
}
