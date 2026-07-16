import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget que escolhe o melhor renderizador de imagem conforme a plataforma.
///
/// No Flutter Web (especialmente com o renderer HTML), [CachedNetworkImage]
/// pode gerar erros de DOM (`removeChild`) quando widgets são removidos ou
/// reciclados rapidamente. Neste caso usamos [Image.network], que é mais
/// estável. Em mobile/desktop mantemos [CachedNetworkImage] para aproveitar
/// o cache local.
class AdaptiveNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext context)? placeholder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const AdaptiveNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return placeholder?.call(context) ??
              const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Erro ao carregar imagem (web): $imageUrl | $error');
          return errorBuilder?.call(context, error) ??
              const Icon(Icons.image_not_supported, color: Colors.white54);
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) =>
          placeholder?.call(context) ??
          const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      errorWidget: (context, url, error) {
        debugPrint('Erro ao carregar imagem: $url | $error');
        return errorBuilder?.call(context, error) ??
            const Icon(Icons.image_not_supported, color: Colors.white54);
      },
    );
  }
}
