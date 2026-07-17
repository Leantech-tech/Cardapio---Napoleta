import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'cart_view.dart';

class CartPanel extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const CartPanel({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final double panelWidth;
    if (width >= 1200) {
      panelWidth = 500.0;
    } else if (width >= 800) {
      panelWidth = width * 0.5;
    } else {
      panelWidth = width * 0.88;
    }
    final borderRadius = width >= 800 ? 24.0 : 20.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      right: isOpen ? 0 : -panelWidth,
      width: panelWidth,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background(context),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            bottomLeft: Radius.circular(borderRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(-6, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            bottomLeft: Radius.circular(borderRadius),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.border(context)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Meu Carrinho',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: Icon(
                          Icons.close,
                          color: AppTheme.textSecondary(context),
                        ),
                        tooltip: 'Fechar',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CartView(
                    onCheckoutComplete: onClose,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CartPanelBarrier extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const CartPanelBarrier({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isOpen
          ? GestureDetector(
              onTap: onClose,
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
