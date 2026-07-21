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
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.inputBg(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: AppTheme.textSecondary(context),
          size: 26,
        ),
      );
    }

    if (imagePath.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AdaptiveNetworkImage(
          imageUrl: imagePath,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          placeholder: (context) => Container(
            width: 64,
            height: 64,
            color: AppTheme.inputBg(context),
          ),
          errorBuilder: (context, error) => Container(
            width: 64,
            height: 64,
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
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        imagePath,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 64,
          height: 64,
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(context, item.imagePath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSizeMd,
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
                    fontSize: AppTheme.fontSizeMd,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brandPurple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => cart.removeItem(item.id),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.delete_outline,
                  size: 22,
                  color: AppTheme.textSecondary(context),
                ),
              ),
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
            final itemCount = cart.totalItems;

            return Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.surface(context),
              child: Container(
                width: panelWidth.clamp(260.0, 420.0),
                height: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 16,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: AppTheme.brandPurple,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mostruário',
                            style: GoogleFonts.poppins(
                              fontSize: AppTheme.fontSizeLg,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                        ),
                        if (!isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.brandPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$itemCount ${itemCount == 1 ? 'item' : 'itens'}',
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSizeSm,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.brandPurple,
                              ),
                            ),
                          ),
                      ],
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
                                    size: 56,
                                    color: AppTheme.textSecondary(context).withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Carrinho vazio',
                                    style: GoogleFonts.poppins(
                                      fontSize: AppTheme.fontSizeMd,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Adicione produtos ao cardápio',
                                    style: GoogleFonts.inter(
                                      fontSize: AppTheme.fontSizeSm,
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
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.inputBg(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.poppins(
                              fontSize: AppTheme.fontSizeSm,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                          Text(
                            _formatPrice(cart.totalPrice),
                            style: GoogleFonts.poppins(
                              fontSize: AppTheme.fontSize2Xl,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: isEmpty ? null : onCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.inputBg(context),
                        disabledForegroundColor: AppTheme.textSecondary(context),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Finalizar pedido',
                        style: GoogleFonts.poppins(
                          fontSize: AppTheme.fontSizeMd,
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
