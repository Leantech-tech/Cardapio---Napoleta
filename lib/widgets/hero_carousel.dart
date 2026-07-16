import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class HeroCarousel extends StatefulWidget {
  final List<Product>? products;

  const HeroCarousel({super.key, this.products});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  List<Map<String, dynamic>> get _banners {
    if (widget.products != null && widget.products!.isNotEmpty) {
      final produtosComFoto = widget.products!
          .where((p) => p.imagePath.isNotEmpty)
          .take(5)
          .toList();

      if (produtosComFoto.isNotEmpty) {
        return produtosComFoto.map((p) {
          return {
            'title': p.name,
            'subtitle': p.description.isNotEmpty
                ? p.description
                : 'R\$ ${p.price.toStringAsFixed(2).replaceAll('.', ',')}',
            'image': p.imagePath,
          };
        }).toList();
      }
    }

    return [
      {
        'title': 'Combo do Dia',
        'subtitle': '2 Coxinhas + Refrigerante por apenas R\$ 18,90',
        'image': 'assets/images/carousel_combo.png',
      },
      {
        'title': 'Café Especial',
        'subtitle': 'Nova safra de grãos 100% arábica',
        'image': 'assets/images/carousel_cafe.png',
      },
      {
        'title': 'Doces Artesanais',
        'subtitle': 'Receitas da vó com goiabada cascão',
        'image': 'assets/images/carousel_doces.png',
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final next = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
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

  Widget _buildBannerImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppTheme.tachaoRed,
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 48,
            ),
          ),
        ),
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppTheme.tachaoRed,
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.white54,
            size: 48,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 700;
    final horizontalPadding = isTablet
        ? (width >= 1100 ? width * 0.08 : 32.0)
        : 20.0;
    final height = isTablet ? 280.0 : 200.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              PageView.builder(
                key: const ValueKey('hero_page_view'),
                controller: _pageController,
                onPageChanged: (index) {
                  if (mounted) {
                    setState(() => _currentPage = index);
                  }
                },
                itemCount: _banners.length,
                itemBuilder: (context, index) {
                  final banner = _banners[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image
                      _buildBannerImage(banner['image'] as String),
                      // Dark gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Text content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE31E24),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'DESTAQUE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              banner['title'],
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 28 : 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner['subtitle'],
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 15 : 13,
                                color: Colors.white.withValues(alpha: 0.95),
                                height: 1.4,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Dots indicator
              Positioned(
                bottom: 12,
                right: 20,
                child: Row(
                  children: List.generate(_banners.length, (index) {
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
            ],
          ),
        ),
      ),
    );
  }
}
