import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _shadowController;
  late AnimationController _dotsController;
  late Animation<double> _floatAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();

    // Levitação suave do logo
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );
    _floatController.repeat(reverse: true);

    // Sombra que pulsa
    _shadowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _shadowAnimation = Tween<double>(begin: 0.08, end: 0.18).animate(
      CurvedAnimation(
        parent: _shadowController,
        curve: Curves.easeInOutSine,
      ),
    );
    _shadowController.repeat(reverse: true);

    // Dots loader
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _dotsController.repeat();

    Timer(const Duration(milliseconds: 3800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MenuScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shadowController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF8F8),
              Colors.white,
              Color(0xFFFFFBF0),
            ],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo com levitação
              FadeIn(
                duration: const Duration(milliseconds: 900),
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _floatController,
                    _shadowController,
                  ]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimation.value),
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.tachaoRed.withValues(
                                alpha: _shadowAnimation.value,
                              ),
                              blurRadius: 50,
                              spreadRadius: 2,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.restaurant,
                              size: 56,
                              color: AppTheme.tachaoRed,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 48),
              // Título
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 800),
                from: 24,
                child: Text(
                  'Tachão de Ubatuba',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Subtítulo com efeito de digitação
              FadeIn(
                delay: const Duration(milliseconds: 900),
                duration: const Duration(milliseconds: 600),
                child: _TypewriterText(
                  text: 'Sabores de Ubatuba desde 1977',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.greyText,
                    letterSpacing: 0.5,
                  ),
                  speed: const Duration(milliseconds: 45),
                ),
              ),
              const SizedBox(height: 56),
              // Loader com 3 dots pulsantes
              FadeIn(
                delay: const Duration(milliseconds: 1400),
                duration: const Duration(milliseconds: 500),
                child: _PulsingDots(controller: _dotsController),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Efeito de digitação letra por letra
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration speed;

  const _TypewriterText({
    required this.text,
    required this.style,
    required this.speed,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayed = '';
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.speed, (_) {
      if (_index < widget.text.length) {
        setState(() {
          _displayed = widget.text.substring(0, _index + 1);
          _index++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _displayed,
          style: widget.style,
        ),
        if (_index < widget.text.length)
          Container(
            width: 2,
            height: 16,
            margin: const EdgeInsets.only(left: 2),
            color: AppTheme.tachaoRed.withValues(alpha: 0.6),
          ),
      ],
    );
  }
}

/// 3 dots com animação de onda pulsante
class _PulsingDots extends StatelessWidget {
  final AnimationController controller;

  const _PulsingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final double delay = index * 0.33;
            double value = (controller.value - delay) % 1.0;
            if (value < 0) value += 1.0;

            final double scale = 0.6 + (0.4 * (1 - value).clamp(0.0, 1.0));
            final double opacity = 0.3 + (0.7 * (1 - value).clamp(0.0, 1.0));

            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: AppTheme.tachaoRed.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.tachaoRed.withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
