import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductBadge extends StatelessWidget {
  final String badge;

  const ProductBadge({super.key, required this.badge});

  Color get _badgeColor {
    final lower = badge.toLowerCase();
    if (lower.contains('promo')) return const Color(0xFFE31E24);
    if (lower.contains('novo')) return const Color(0xFF2E7D32);
    if (lower.contains('premium') || lower.contains('chef')) return const Color(0xFFFFB300);
    if (lower.contains('mais vendido') || lower.contains('top')) return const Color(0xFF1565C0);
    return const Color(0xFFE31E24);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _badgeColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _badgeColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        badge,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
