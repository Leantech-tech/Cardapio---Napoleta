import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'product_image.dart';

class ProductCardGrid extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final int index;

  const ProductCardGrid({
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

    final contentPadding = isDesktop
        ? 18.0
        : (isTablet ? 16.0 : (isSmallPhone ? 10.0 : 14.0));
    final titleFontSize = isDesktop
        ? 20.0
        : (isTablet ? 18.0 : (isSmallPhone ? 14.0 : 16.0));
    final descriptionFontSize = isDesktop
        ? 14.0
        : (isTablet ? 13.0 : (isSmallPhone ? 10.0 : 12.0));
    final priceFontSize = isDesktop
        ? 20.0
        : (isTablet ? 18.0 : (isSmallPhone ? 16.0 : AppTheme.fontSize2Xl));
    final addButtonSize = isDesktop
        ? 48.0
        : (isTablet ? 46.0 : (isSmallPhone ? 38.0 : 44.0));
    final addIconSize = isDesktop
        ? 24.0
        : (isTablet ? 22.0 : (isSmallPhone ? 18.0 : 22.0));
    final badgeIconSize = isTablet ? 16.0 : 14.0;
    final badgeFontSize = isTablet ? 13.0 : AppTheme.fontSizeXs;

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: index * 80),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ProductImage(
                    product: product,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    placeholderSize: 56,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    contentPadding,
                    contentPadding * 0.8,
                    contentPadding,
                    contentPadding * 0.6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (product.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          style: GoogleFonts.inter(
                            fontSize: descriptionFontSize,
                            color: AppTheme.textSecondary(context),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      if (product.optionGroups.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune,
                                size: badgeIconSize,
                                color: AppTheme.brandPurple.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Personalizável',
                                style: GoogleFonts.inter(
                                  fontSize: badgeFontSize,
                                  color: AppTheme.brandPurple.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                              borderRadius: BorderRadius.circular(isSmallPhone ? 10 : 12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.brandPurple.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
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
