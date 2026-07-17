import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'adaptive_image.dart';

class MiniCartPreview extends StatelessWidget {
  final VoidCallback? onClose;
  final VoidCallback onCheckout;

  const MiniCartPreview({
    super.key,
    this.onClose,
    required this.onCheckout,
  });

  String _formatPrice(double price) {
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _buildImage(BuildContext context, String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.inputBg(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: AppTheme.textSecondary(context),
          size: 22,
        ),
      );
    }

    if (imagePath.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AdaptiveNetworkImage(
          imageUrl: imagePath,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (context) => Container(
            width: 56,
            height: 56,
            color: AppTheme.inputBg(context),
          ),
          errorBuilder: (context, error) => Container(
            width: 56,
            height: 56,
            color: AppTheme.inputBg(context),
            child: Icon(
              Icons.image_not_supported,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        imagePath,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 56,
          height: 56,
          color: AppTheme.inputBg(context),
          child: Icon(
            Icons.image_not_supported,
            color: AppTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, CartItem item, CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildImage(context, item.imagePath),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity}x ${_formatPrice(item.unitPrice)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.tachaoRed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => cart.removeItem(item.id),
            child: Icon(
              Icons.delete_outline,
              size: 20,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final panelWidth = (screenWidth >= 800 ? 360.0 : screenWidth * 0.85) - 8;

        return Consumer<CartProvider>(
          builder: (context, cart, child) {
            final isEmpty = cart.items.isEmpty;

            return Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: AppTheme.surface(context),
              child: Container(
                width: panelWidth.clamp(240.0, 400.0),
                height: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 12,
                  left: 12,
                  right: 12,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mostruário',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 48,
                                    color: AppTheme.textSecondary(context).withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Carrinho vazio',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Adicione produtos ao cardápio',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary(context).withValues(alpha: 0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: cart.items.length,
                              itemBuilder: (context, index) {
                                return _buildItem(context, cart.items[index], cart);
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.inputBg(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Total: ${_formatPrice(cart.totalPrice)}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isEmpty ? null : onCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tachaoRed,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.inputBg(context),
                        disabledForegroundColor: AppTheme.textSecondary(context),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Finalizar pedido',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
