import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/storage_image_url.dart';
import 'adaptive_image.dart';

/// Exibe a imagem de uma categoria vinda do storage.
///
/// Quando [Category.imagePath] estiver vazio ou a imagem falhar ao carregar,
/// renderiza o ícone padrão da categoria como fallback.
class CategoryImage extends StatelessWidget {
  final Category category;
  final BoxFit fit;
  final double? size;
  final BorderRadius? borderRadius;
  final Color? iconColor;

  const CategoryImage({
    super.key,
    required this.category,
    this.fit = BoxFit.cover,
    this.size,
    this.borderRadius,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = StorageImageUrl.resolve(category.imagePath);

    Widget content;
    if (imageUrl.isEmpty) {
      content = _IconFallback(category: category, size: size, iconColor: iconColor);
    } else if (imageUrl.startsWith('http')) {
      content = AdaptiveNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: size,
        height: size,
        placeholder: (_) => _IconFallback(category: category, size: size, iconColor: iconColor),
        errorBuilder: (_, _) => _IconFallback(category: category, size: size, iconColor: iconColor),
      );
    } else {
      content = Image.asset(
        imageUrl,
        fit: fit,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => _IconFallback(category: category, size: size, iconColor: iconColor),
      );
    }

    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }

    return content;
  }
}

class _IconFallback extends StatelessWidget {
  final Category category;
  final double? size;
  final Color? iconColor;

  const _IconFallback({required this.category, this.size, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 24;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Icon(
        category.icon,
        size: iconSize,
        color: iconColor ?? Colors.white,
      ),
    );
  }
}
