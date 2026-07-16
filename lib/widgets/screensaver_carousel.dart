import 'dart:async';
import 'dart:math' show max;
import 'package:flutter/material.dart';
import '../models/product.dart';

/// Carrossel em tela cheia que funciona como screensaver.
/// As imagens são exibidas sem cortar (BoxFit.contain).
class ScreensaverCarousel extends StatefulWidget {
  final List<Product>? products;
  final VoidCallback? onInteract;

  const ScreensaverCarousel({
    super.key,
    this.products,
    this.onInteract,
  });

  @override
  State<ScreensaverCarousel> createState() => _ScreensaverCarouselState();
}

class _ScreensaverCarouselState extends State<ScreensaverCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  List<String> get _images {
    if (widget.products != null && widget.products!.isNotEmpty) {
      final produtosComFoto = widget.products!
          .where((p) => p.imagePath.isNotEmpty)
          .take(10)
          .toList();

      if (produtosComFoto.isNotEmpty) {
        return produtosComFoto.map((p) => p.imagePath).toList();
      }
    }

    return [
      'assets/images/carousel_combo.png',
      'assets/images/carousel_cafe.png',
      'assets/images/carousel_doces.png',
    ];
  }

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_pageController.hasClients && _images.length > 1) {
        final next = (_currentPage + 1) % _images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(String imagePath) {
    final imageWidget = imagePath.startsWith('http')
        ? Image.network(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _fallbackImage(),
          )
        : Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _fallbackImage(),
          );

    return Container(
      color: Colors.black,
      child: Center(child: imageWidget),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.white54,
          size: 64,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onInteract,
      onPanDown: (_) => widget.onInteract?.call(),
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                if (mounted) setState(() => _currentPage = index);
              },
              itemCount: max(_images.length, 1),
              itemBuilder: (context, index) {
                if (_images.isEmpty) return _fallbackImage();
                return _buildImage(_images[index]);
              },
            ),
            // Indicador sutil de progresso
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_images.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Dica sutil para voltar
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Toque na tela para voltar ao cardápio',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
