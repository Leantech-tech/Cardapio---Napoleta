import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/barcode_scanner_service.dart';
import '../services/cart_checkout_service.dart';
import '../widgets/adaptive_image.dart';

class CartView extends StatefulWidget {
  final VoidCallback? onCheckoutComplete;

  const CartView({super.key, this.onCheckoutComplete});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  late ConfettiController _confettiController;
  StreamSubscription<String>? _barcodeSubscription;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    final authProvider = context.read<AuthProvider>();
    _barcodeSubscription = BarcodeScannerService().onBarcode.listen((barcode) {
      if (!authProvider.useComandaFeature) return;
      final numero = BarcodeScannerService().extrairNumeroComanda(barcode);
      if (numero.isNotEmpty && mounted) {
        _sendOrder(context.read<CartProvider>(), numeroComanda: numero);
      }
    });
  }

  @override
  void dispose() {
    _barcodeSubscription?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _sendOrder(CartProvider cart, {String? numeroComanda}) async {
    await const CartCheckoutService().sendOrder(
      context,
      cart,
      numeroComanda: numeroComanda,
      onSuccess: () {
        _confettiController.play();
        widget.onCheckoutComplete?.call();
      },
    );
  }

  String _formatPrice(double price) {
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _buildCartItemImage(BuildContext context, String imagePath) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 700;
    final imageSize = isTablet ? 90.0 : 76.0;
    final iconSize = isTablet ? 34.0 : 28.0;

    if (imagePath.isEmpty) {
      return Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          color: AppTheme.inputBg(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: AppTheme.textSecondary(context),
          size: iconSize,
        ),
      );
    }

    if (imagePath.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AdaptiveNetworkImage(
          key: ValueKey(imagePath),
          imageUrl: imagePath,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          placeholder: (context) => Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              color: AppTheme.inputBg(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.brandPurple, strokeWidth: 2),
            ),
          ),
          errorBuilder: (context, error) => Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              color: AppTheme.inputBg(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.image_not_supported,
              color: AppTheme.textSecondary(context),
              size: iconSize,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        imagePath,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: AppTheme.inputBg(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.image_not_supported,
            color: AppTheme.textSecondary(context),
            size: iconSize,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final items = cart.items;
        final isEmpty = items.isEmpty;

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  isEmpty
                      ? _buildEmptyState(context)
                      : _buildCartList(context, cart),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      particleDrag: 0.05,
                      emissionFrequency: 0.05,
                      numberOfParticles: 30,
                      gravity: 0.2,
                      shouldLoop: false,
                      colors: const [
                        AppTheme.brandPurple,
                        AppTheme.honeyGold,
                        Colors.green,
                        Colors.orange,
                        Colors.blue,
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isEmpty) _buildBottomBar(context, cart),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.inputBg(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 56,
                color: AppTheme.brandPurple.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Seu carrinho está vazio',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore o cardápio e adicione seus produtos favoritos!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: widget.onCheckoutComplete,
              icon: const Icon(Icons.restaurant_menu),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: Text(
                'Ver Cardápio',
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
  }

  Widget _buildCartList(BuildContext context, CartProvider cart) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final isTablet = width >= 700;
        final crossAxisCount = isTablet ? 2 : 1;
        final horizontalPadding = isTablet ? 20.0 : 16.0;
        final aspectRatio = height < 400 ? 3.4 : 2.8;

        if (crossAxisCount > 1) {
          return GridView.builder(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              20,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
            ),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              return _buildCartItemCard(context, cart, cart.items[index]);
            },
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            20,
          ),
          itemCount: cart.items.length,
          itemBuilder: (context, index) {
            return _buildCartItemCard(context, cart, cart.items[index]);
          },
        );
      },
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartProvider cart,
    dynamic item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context).withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.isDark(context)
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCartItemImage(context, item.imagePath),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.selectedOptions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.selectedOptionsDisplay,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (item.observation != null && item.observation!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Obs: ${item.observation}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.inputBg(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Row(
                        children: [
                          _buildIconButton(
                            icon: Icons.remove,
                            onTap: () => cart.updateQuantity(
                              item.id,
                              item.quantity - 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${item.quantity}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ),
                          _buildIconButton(
                            icon: Icons.add,
                            onTap: () => cart.updateQuantity(
                              item.id,
                              item.quantity + 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatPrice(item.total),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => cart.removeItem(item.id),
            icon: Icon(
              Icons.delete_outline,
              color: AppTheme.textSecondary(context),
              size: 22,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: AppTheme.brandPurple,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(
          top: BorderSide(color: AppTheme.border(context)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadow(context),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${cart.totalItems} item${cart.totalItems != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Total: ',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    Text(
                      _formatPrice(cart.totalPrice),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => _sendOrder(cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Finalizar Pedido',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
