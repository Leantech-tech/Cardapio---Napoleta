import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'screensaver_carousel.dart';

enum TotemMode { acai, paleta }

class TotemModeSelector extends StatefulWidget {
  final List<Product>? products;

  const TotemModeSelector({
    super.key,
    this.products,
  });

  static Future<TotemMode?> show(
    BuildContext context, {
    List<Product>? products,
  }) async {
    return showDialog<TotemMode>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TotemModeSelector(products: products),
    );
  }

  @override
  State<TotemModeSelector> createState() => _TotemModeSelectorState();
}

class _TotemModeSelectorState extends State<TotemModeSelector> {
  Timer? _inactivityTimer;
  bool _isScreensaverActive = false;
  static const _inactivityDuration = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (mounted) {
        setState(() => _isScreensaverActive = true);
      }
    });
  }

  void _resetInactivityTimer() {
    if (_isScreensaverActive) {
      setState(() => _isScreensaverActive = false);
    }
    _startInactivityTimer();
  }

  void _handleUserInteraction([_]) {
    _resetInactivityTimer();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 700;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: AppTheme.background(context),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handleUserInteraction,
        onPointerMove: _handleUserInteraction,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bem-vindo!',
                        style: GoogleFonts.poppins(
                          fontSize: isWide ? 36 : 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escolha uma opção para começar',
                        style: GoogleFonts.inter(
                          fontSize: isWide ? 20 : 16,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Flexible(
                        child: isWide
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _buildOptionCard(
                                      context,
                                      iconWidget: Icon(
                                        Icons.ramen_dining,
                                        size: 72,
                                        color: AppTheme.brandPurple,
                                      ),
                                      title: 'Açaí',
                                      subtitle: 'Monte seu açaí do seu jeito',
                                      color: AppTheme.brandPurple,
                                      onTap: () => Navigator.of(context).pop(TotemMode.acai),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildOptionCard(
                                      context,
                                      iconWidget: PopsicleIcon(
                                        size: 72,
                                        color: Colors.orangeAccent,
                                      ),
                                      title: 'Paleta',
                                      subtitle: 'Escolha suas paletas favoritas',
                                      color: Colors.orangeAccent,
                                      onTap: () => Navigator.of(context).pop(TotemMode.paleta),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: _buildOptionCard(
                                      context,
                                      iconWidget: Icon(
                                        Icons.ramen_dining,
                                        size: 72,
                                        color: AppTheme.brandPurple,
                                      ),
                                      title: 'Açaí',
                                      subtitle: 'Monte seu açaí do seu jeito',
                                      color: AppTheme.brandPurple,
                                      onTap: () => Navigator.of(context).pop(TotemMode.acai),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: _buildOptionCard(
                                      context,
                                      iconWidget: PopsicleIcon(
                                        size: 72,
                                        color: Colors.orangeAccent,
                                      ),
                                      title: 'Paleta',
                                      subtitle: 'Escolha suas paletas favoritas',
                                      color: Colors.orangeAccent,
                                      onTap: () => Navigator.of(context).pop(TotemMode.paleta),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isScreensaverActive)
                Positioned.fill(
                  child: ScreensaverCarousel(
                    products: widget.products,
                    onInteract: _handleUserInteraction,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.border(context), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: iconWidget,
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícone customizado de picolé/paleta desenhado com CustomPaint.
///
/// Não há ícone nativo de picolé no Material Design nem no Lucide,
/// então desenhamos um diretamente no Flutter.
class PopsicleIcon extends StatelessWidget {
  final double size;
  final Color color;

  const PopsicleIcon({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PopsiclePainter(color: color),
      ),
    );
  }
}

class _PopsiclePainter extends CustomPainter {
  final Color color;

  _PopsiclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final stickWidth = size.width * 0.18;
    final stickHeight = size.height * 0.28;
    final bodyTop = size.height * 0.12;
    final bodyBottom = size.height * 0.65;
    final bodyWidth = size.width * 0.42;
    final cornerRadius = size.width * 0.12;

    final bodyRect = RRect.fromLTRBR(
      centerX - bodyWidth / 2,
      bodyTop,
      centerX + bodyWidth / 2,
      bodyBottom,
      Radius.circular(cornerRadius),
    );

    // Corpo do picolé.
    canvas.drawRRect(bodyRect, paint);
    canvas.drawRRect(bodyRect, fillPaint);

    // Mordida no canto superior direito.
    final bitePaint = Paint()..color = Colors.transparent;
    final bitePath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(centerX + bodyWidth * 0.35, bodyTop + bodyWidth * 0.25),
        radius: size.width * 0.12,
      ));
    canvas.drawPath(bitePath, bitePaint);

    // Bastão de madeira.
    final stickRect = RRect.fromLTRBR(
      centerX - stickWidth / 2,
      bodyBottom - size.height * 0.04,
      centerX + stickWidth / 2,
      bodyBottom + stickHeight,
      Radius.circular(stickWidth / 2),
    );
    canvas.drawRRect(stickRect, paint);
    canvas.drawRRect(stickRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
