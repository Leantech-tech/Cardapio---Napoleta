import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_option.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_badge.dart';
import '../widgets/product_image.dart';
import '../utils/option_group_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int quantity = 1;
  final TextEditingController _obsController = TextEditingController();
  bool _added = false;
  late Map<String, List<String>> _selectedOptions;
  late Map<String, double> _selectedOptionPrices;

  double get _totalOptionsPrice {
    return _selectedOptionPrices.values.fold(0.0, (sum, p) => sum + p);
  }

  double get total => (widget.product.price + _totalOptionsPrice) * quantity;

  @override
  void initState() {
    super.initState();
    _selectedOptions = {};
    _selectedOptionPrices = {};
    for (final group in widget.product.optionGroups) {
      if (group.options.isNotEmpty) {
        if (group.isSingleChoice) {
          final first = group.options.first;
          _selectedOptions[group.id] = [first.id];
          _selectedOptionPrices[first.id] = first.priceModifier;
        } else {
          _selectedOptions[group.id] = [];
        }
      }
    }
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  int _effectiveQtdMax(ProductOptionGroup group) {
    return OptionGroupHelper.effectiveQtdMax(
      group,
      _selectedOptions,
      widget.product.optionGroups,
    );
  }

  void _enforceEffectiveMax() {
    for (final group in widget.product.optionGroups) {
      final effectiveMax = _effectiveQtdMax(group);
      final currentList = _selectedOptions[group.id] ?? [];
      if (currentList.length > effectiveMax) {
        final toRemove = currentList.sublist(effectiveMax);
        for (final id in toRemove) {
          _selectedOptionPrices.remove(id);
        }
        _selectedOptions[group.id] = currentList.sublist(0, effectiveMax);
      }
    }
  }

  bool _isEffectivelyMultipleChoice(ProductOptionGroup group) {
    return _effectiveQtdMax(group) > 1 || group.isMultipleChoice;
  }

  void _toggleOption(ProductOptionGroup group, ProductOption option) {
    setState(() {
      final currentList = _selectedOptions[group.id] ?? [];
      final effectiveMax = _effectiveQtdMax(group);
      final isMulti = _isEffectivelyMultipleChoice(group);

      if (!isMulti) {
        if (currentList.isNotEmpty) {
          _selectedOptionPrices.remove(currentList.first);
        }
        _selectedOptions[group.id] = [option.id];
        _selectedOptionPrices[option.id] = option.priceModifier;
      } else {
        if (currentList.contains(option.id)) {
          if (currentList.length > group.qtdMin) {
            currentList.remove(option.id);
            _selectedOptionPrices.remove(option.id);
          }
        } else {
          if (currentList.length < effectiveMax) {
            currentList.add(option.id);
            _selectedOptionPrices[option.id] = option.priceModifier;
          }
        }
        _selectedOptions[group.id] = List.from(currentList);
      }
      _enforceEffectiveMax();
    });
  }

  bool _isSelected(ProductOptionGroup group, ProductOption option) {
    final list = _selectedOptions[group.id] ?? [];
    return list.contains(option.id);
  }

  String _getOptionDisplayName() {
    if (_selectedOptions.isEmpty) return '';
    final parts = <String>[];
    for (final group in widget.product.optionGroups) {
      final selectedIds = _selectedOptions[group.id] ?? [];
      for (final id in selectedIds) {
        final option = group.options.firstWhere(
          (o) => o.id == id,
          orElse: () => ProductOption(id: '', name: ''),
        );
        if (option.name.isNotEmpty) parts.add(option.name);
      }
    }
    return parts.join(' / ');
  }

  bool _canAddToCart() {
    for (final group in widget.product.optionGroups) {
      final selectedCount = (_selectedOptions[group.id] ?? []).length;
      final effectiveMax = _effectiveQtdMax(group);
      if (group.isObrigatorio && selectedCount < group.qtdMin) {
        return false;
      }
      if (selectedCount < group.qtdMin) {
        return false;
      }
      if (selectedCount > effectiveMax) {
        return false;
      }
    }
    return true;
  }

  String? _validationMessage() {
    for (final group in widget.product.optionGroups) {
      final selectedCount = (_selectedOptions[group.id] ?? []).length;
      final effectiveMax = _effectiveQtdMax(group);
      if (group.isObrigatorio && selectedCount < group.qtdMin) {
        return 'Selecione pelo menos ${group.qtdMin} opção(ões) em "${group.name}"';
      }
      if (selectedCount < group.qtdMin) {
        return 'Selecione pelo menos ${group.qtdMin} opção(ões) em "${group.name}"';
      }
      if (selectedCount > effectiveMax) {
        return 'Selecione no máximo $effectiveMax opção(ões) em "${group.name}"';
      }
    }
    return null;
  }

  void _addToCart() async {
    final validation = _validationMessage();
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            validation,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();

    final cartProvider = context.read<CartProvider>();
    final observation = _obsController.text.trim();

    cartProvider.addItem(
      widget.product,
      quantity,
      observation.isEmpty ? null : observation,
      _selectedOptions,
      _selectedOptionPrices,
      _totalOptionsPrice,
    );

    setState(() => _added = true);

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.product.name} (x$quantity) adicionado ao carrinho!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.tachaoRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildProductImage(BuildContext context, {double size = 260}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: size,
        height: size,
        child: Transform.scale(
          scale: 1.12,
          child: ProductImage(
            product: widget.product,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithBadge(BuildContext context, {double size = 260}) {
    return Stack(
      children: [
        _buildProductImage(context, size: size),
        if (widget.product.badge != null)
          Positioned(
            top: 10,
            left: 10,
            child: ProductBadge(badge: widget.product.badge!),
          ),
      ],
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    final hasOptions = widget.product.optionGroups.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              widget.product.priceDisplay,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.tachaoRed,
              ),
            ),
            if (hasOptions)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '+ opções',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    if (widget.product.description.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Descrição'),
        const SizedBox(height: 8),
        Text(
          widget.product.description,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary(context),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildIngredientsChip(BuildContext context) {
    if (widget.product.isRefrigerante) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () => _showIngredientsSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.inputBg(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 16,
              color: AppTheme.textSecondary(context),
            ),
            const SizedBox(width: 6),
            Text(
              'Ingredientes',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIngredientsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ingredientes',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: widget.product.ingredients.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum ingrediente informado.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: widget.product.ingredients.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: AppTheme.tachaoRed,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.product.ingredients[index],
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppTheme.textPrimary(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onTap: () {
              if (quantity > 1) {
                setState(() => quantity--);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              '$quantity',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onTap: () => setState(() => quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildObservation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Observação'),
        const SizedBox(height: 8),
        TextField(
          controller: _obsController,
          decoration: InputDecoration(
            hintText: 'Ex: Sem açúcar, troque o sorvete...',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[400],
            ),
            prefixIcon: Icon(Icons.edit_note, color: AppTheme.textSecondary(context)),
            filled: true,
            fillColor: AppTheme.inputBg(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
          maxLines: 2,
          style: GoogleFonts.inter(fontSize: 14),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOptionGroups(BuildContext context) {
    if (widget.product.optionGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.product.optionGroups.map((group) {
          final selectedCount = (_selectedOptions[group.id] ?? []).length;
          final effectiveMax = _effectiveQtdMax(group);
          final isValid = selectedCount >= group.qtdMin &&
              selectedCount <= effectiveMax;
          final isBolas = group.name.trim().toLowerCase() == 'bolas';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border(context)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadow(context),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isBolas)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                      if (group.qtdMin > 0 || effectiveMax > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isValid
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            group.qtdMin == effectiveMax
                                ? 'Escolha ${group.qtdMin}'
                                : group.qtdMin > 0
                                    ? 'Min ${group.qtdMin} / Max $effectiveMax'
                                    : 'Max $effectiveMax',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isValid
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                if (!isBolas) const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: group.options.map((option) {
                    final isSelected = _isSelected(group, option);
                    return GestureDetector(
                      onTap: () => _toggleOption(group, option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.tachaoRed
                              : AppTheme.inputBg(context),
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: AppTheme.border(context),
                                ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isEffectivelyMultipleChoice(group))
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary(context),
                                ),
                              ),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textPrimary(context),
                                    ),
                                  ),
                                  if (option.priceModifier > 0)
                                    Text(
                                      '+ ${option.priceModifier.toStringAsFixed(2).replaceAll('.', ',')}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isSelected
                                            ? Colors.white.withValues(alpha: 0.9)
                                            : AppTheme.textSecondary(context),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _canAddToCart();

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: AppTheme.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Adicionar pedido',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          final imageSize = isWide
              ? (maxWidth * 0.30).clamp(200.0, 300.0).toDouble()
              : (maxWidth * 0.55).clamp(200.0, 280.0).toDouble();
          final clampedImageSize = maxHeight > 0
              ? imageSize.clamp(160.0, maxHeight * 0.45)
              : imageSize;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: clampedImageSize,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageWithBadge(context, size: clampedImageSize),
                            const SizedBox(height: 20),
                            _buildProductInfo(context),
                            const SizedBox(height: 20),
                            _buildDescription(context),
                            _buildIngredientsChip(context),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildObservation(context),
                            _buildSectionTitle(context, 'Quantidade'),
                            const SizedBox(height: 8),
                            _buildQuantityStepper(context),
                            const SizedBox(height: 24),
                            _buildOptionGroups(context),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _buildImageWithBadge(context, size: clampedImageSize),
                      ),
                      const SizedBox(height: 20),
                      _buildProductInfo(context),
                      const SizedBox(height: 16),
                      _buildDescription(context),
                      Row(
                        children: [
                          _buildIngredientsChip(context),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildObservation(context),
                      _buildSectionTitle(context, 'Quantidade'),
                      const SizedBox(height: 8),
                      _buildQuantityStepper(context),
                      const SizedBox(height: 24),
                      _buildOptionGroups(context),
                    ],
                  ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
              if (_selectedOptions.isNotEmpty && _getOptionDisplayName().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _getOptionDisplayName(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ElevatedButton(
                onPressed: (_added || !canAdd) ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _added ? Colors.green[600] : AppTheme.tachaoRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _added
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          key: const ValueKey('added'),
                          children: [
                            const Icon(Icons.check_circle, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Adicionado!',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          key: const ValueKey('add'),
                          children: [
                            Text(
                              'Adicionar',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: AppTheme.tachaoRed,
          size: 22,
        ),
      ),
    );
  }
}
