import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/storage_image_url.dart';
import 'adaptive_image.dart';

class ProductImage extends StatelessWidget {
  final Product product;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double placeholderSize;

  const ProductImage({
    super.key,
    required this.product,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderSize = 40,
  });

  static final Map<String, _PlaceholderStyle> _styles = {
    '1': const _PlaceholderStyle( // Doces
      bgColor: Color(0xFFFCE4EC),
      iconColor: Color(0xFFC2185B),
      icon: Icons.cake,
    ),
    '2': const _PlaceholderStyle( // Tamanho Família
      bgColor: Color(0xFFF3E5F5),
      iconColor: Color(0xFF7B1FA2),
      icon: Icons.people,
    ),
    '3': const _PlaceholderStyle( // Salgados
      bgColor: Color(0xFFFFF3E0),
      iconColor: Color(0xFFE65100),
      icon: Icons.local_pizza,
    ),
    '4': const _PlaceholderStyle( // Combos
      bgColor: Color(0xFFE8F5E9),
      iconColor: Color(0xFF2E7D32),
      icon: Icons.fastfood,
    ),
    '5': const _PlaceholderStyle( // Bebidas Geladas
      bgColor: Color(0xFFE3F2FD),
      iconColor: Color(0xFF1565C0),
      icon: Icons.local_drink,
    ),
    '6': const _PlaceholderStyle( // Bebidas Quentes
      bgColor: Color(0xFFFFF8E1),
      iconColor: Color(0xFFF9A825),
      icon: Icons.coffee,
    ),
  };

  _PlaceholderStyle get _style {
    return _styles[product.categoryId] ??
        const _PlaceholderStyle(
          bgColor: Color(0xFFF5F5F5),
          iconColor: Color(0xFF757575),
          icon: Icons.restaurant,
        );
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;

    final imageUrl = StorageImageUrl.resolve(product.imagePath);

    Widget image;
    if (imageUrl.isEmpty) {
      image = SizedBox.expand(
        child: _Placeholder(style: style, iconSize: placeholderSize),
      );
    } else if (imageUrl.startsWith('http')) {
      image = AdaptiveNetworkImage(
        key: ValueKey(imageUrl),
        imageUrl: imageUrl,
        fit: fit,
        placeholder: (context) => _Placeholder(style: style, iconSize: placeholderSize),
        errorBuilder: (context, error) => _Placeholder(style: style, iconSize: placeholderSize),
      );
    } else {
      image = Image.asset(
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _Placeholder(style: style, iconSize: placeholderSize),
      );
    }

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

class _Placeholder extends StatelessWidget {
  final _PlaceholderStyle style;
  final double iconSize;

  const _Placeholder({required this.style, this.iconSize = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: style.bgColor,
      child: Center(
        child: Icon(
          style.icon,
          color: style.iconColor,
          size: iconSize,
        ),
      ),
    );
  }
}

class _PlaceholderStyle {
  final Color bgColor;
  final Color iconColor;
  final IconData icon;

  const _PlaceholderStyle({
    required this.bgColor,
    required this.iconColor,
    required this.icon,
  });
}
