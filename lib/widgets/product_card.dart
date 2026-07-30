import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final int index;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 700;
    final isSmallPhone = screenWidth < 360;
    final imageWidth = isTablet ? 160.0 : (isSmallPhone ? 80.0 : 96.0);
    final imageHeight = isTablet ? 180.0 : (isSmallPhone ? 96.0 : 112.0);

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: index * 80),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border(context).withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.isDark(context)
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: ProductImage(
                    product: product,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isSmallPhone ? 8 : 10,
                    isSmallPhone ? 8 : 10,
                    isSmallPhone ? 8 : 10,
                    isSmallPhone ? 8 : 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallPhone ? 13 : 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.description,
                        style: GoogleFonts.inter(
                          fontSize: isSmallPhone ? 10 : 11,
                          color: AppTheme.textSecondary(context),
                          height: 1.3,
                        ),
                        maxLines: isSmallPhone ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.optionGroups.isNotEmpty && !isSmallPhone)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune,
                                size: 12,
                                color: AppTheme.brandPurple.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Personalizável',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppTheme.brandPurple.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              product.priceDisplay,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallPhone ? 14 : 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.brandPurple,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: isSmallPhone ? 32 : 36,
                            height: isSmallPhone ? 32 : 36,
                            decoration: BoxDecoration(
                              color: AppTheme.brandPurple,
                              borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.brandPurple.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: isSmallPhone ? 16 : 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
