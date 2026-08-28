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
    final isDesktop = screenWidth >= 1100;
    final isSmallPhone = screenWidth < 360;
    final imageWidth = isDesktop
        ? 220.0
        : (isTablet ? 180.0 : (isSmallPhone ? 80.0 : 96.0));
    final imageHeight = isDesktop
        ? 240.0
        : (isTablet ? 200.0 : (isSmallPhone ? 96.0 : 112.0));
    final contentPadding = isDesktop
        ? 18.0
        : (isTablet ? 14.0 : (isSmallPhone ? 8.0 : 10.0));
    final titleFontSize = isDesktop
        ? 19.0
        : (isTablet ? 17.0 : (isSmallPhone ? 13.0 : 15.0));
    final descriptionFontSize = isDesktop
        ? 13.0
        : (isTablet ? 12.0 : (isSmallPhone ? 10.0 : 11.0));
    final descriptionMaxLines = isSmallPhone ? 1 : (isTablet ? 3 : 2);
    final priceFontSize = isDesktop
        ? 18.0
        : (isTablet ? 17.0 : (isSmallPhone ? 14.0 : 15.0));
    final addButtonSize = isDesktop
        ? 46.0
        : (isTablet ? 42.0 : (isSmallPhone ? 32.0 : 36.0));
    final addIconSize = isDesktop
        ? 22.0
        : (isTablet ? 20.0 : (isSmallPhone ? 16.0 : 18.0));

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
                    contentPadding,
                    contentPadding,
                    contentPadding,
                    contentPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: titleFontSize,
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
                          fontSize: descriptionFontSize,
                          color: AppTheme.textSecondary(context),
                          height: 1.3,
                        ),
                        maxLines: descriptionMaxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.optionGroups.isNotEmpty && !isSmallPhone)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune,
                                size: isTablet ? 14 : 12,
                                color: AppTheme.brandPurple.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Personalizável',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 12 : 10,
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
                                fontSize: priceFontSize,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.brandPurple,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: addButtonSize,
                            height: addButtonSize,
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
                              size: addIconSize,
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
