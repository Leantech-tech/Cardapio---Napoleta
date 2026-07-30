import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum TotemMode { acai, paleta }

class TotemModeSelector extends StatelessWidget {
  const TotemModeSelector({super.key});

  static Future<TotemMode?> show(BuildContext context) async {
    return showDialog<TotemMode>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TotemModeSelector(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 700;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: AppTheme.background(context),
      child: SizedBox.expand(
        child: SafeArea(
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
                                icon: Icons.local_dining,
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
                                icon: Icons.icecream,
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
                                icon: Icons.local_dining,
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
                                icon: Icons.icecream,
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
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
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
              child: Icon(
                icon,
                size: 72,
                color: color,
              ),
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
