import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/store_status_helper.dart';
import '../widgets/screensaver_carousel.dart';
import '../widgets/product_card.dart';
import '../widgets/login_sheet.dart';
import '../widgets/app_config_sheet.dart';
import '../widgets/product_card_grid.dart';
import '../widgets/barcode_scanner_screen.dart';
import '../widgets/comanda_viewer_sheet.dart';
import '../widgets/cart_panel.dart';
import '../widgets/mini_cart_preview.dart';
import '../services/barcode_scanner_service.dart';
import '../services/comanda_service.dart';
import '../services/kiosk_service.dart';
import 'product_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with WidgetsBindingObserver {
  String selectedCategoryId = '';
  bool _isCartOpen = false;
  bool _showMiniCart = false;

  // Controle do gesto secreto para saída administrativa do modo quiosque.
  int _adminTapCount = 0;
  Timer? _adminTapResetTimer;

  // Controle de inatividade para o screensaver do carrossel.
  Timer? _inactivityTimer;
  bool _isScreensaverActive = false;
  static const _inactivityDuration = Duration(minutes: 1);

  // Listener para leituras de scanner de código de barras.
  StreamSubscription<String>? _barcodeSubscription;

  List<Product> getFilteredProducts(List<Product> allProducts) {
    return allProducts
        .where((p) => p.categoryId == selectedCategoryId)
        .toList();
  }

  String getSectionTitle(List<Category> categories) {
    if (categories.isEmpty) return '';
    return categories
        .firstWhere(
          (c) => c.id == selectedCategoryId,
          orElse: () => categories.first,
        )
        .displayName;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startInactivityTimer();
    final authProvider = context.read<AuthProvider>();
    _barcodeSubscription = BarcodeScannerService().onBarcode.listen((barcode) {
      if (!authProvider.useComandaFeature) return;
      final numero = BarcodeScannerService().extrairNumeroComanda(barcode);
      if (numero.isNotEmpty && mounted) {
        _consultarComanda(numeroComanda: numero);
      }
    });
  }

  @override
  void dispose() {
    _barcodeSubscription?.cancel();
    _adminTapResetTimer?.cancel();
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (mounted) {
        setState(() => _isScreensaverActive = true);
      }
    });
  }

  void _resetInactivityTimer() {
    if (_isScreensaverActive) {
      setState(() => _isScreensaverActive = false);
    }
    _startInactivityTimer();
  }

  void _handleUserInteraction([_]) {
    _resetInactivityTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quando o app volta para o primeiro plano, garante que as barras do sistema
    // permaneçam ocultas no modo quiosque.
    if (state == AppLifecycleState.resumed) {
      KioskService.restoreImmersiveMode();
    }
  }

  /// Gesto administrativo: tocar 5 vezes no logo em menos de 2 segundos
  /// permite sair do modo quiosque para manutenção.
  void _handleAdminLogoTap() {
    _adminTapCount++;
    _adminTapResetTimer?.cancel();
    _adminTapResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _adminTapCount = 0);
    });

    if (_adminTapCount >= 5) {
      _adminTapCount = 0;
      _adminTapResetTimer?.cancel();
      _showKioskExitDialog();
    }
  }

  void _showKioskExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Modo Quiosque'),
        content: const Text(
          'Deseja desativar o modo quiosque para realizar manutenção no tablet?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final messenger = ScaffoldMessenger.of(context);
              await KioskService.disable();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Modo quiosque desativado. Reinicie o app para reativar.'),
                  ),
                );
              }
            },
            child: const Text('SAIR DO QUIOSQUE'),
          ),
        ],
      ),
    );
  }

  void _openProductDetail(Product product) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
    if (added == true && mounted) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      if (screenWidth >= 700) {
        setState(() => _showMiniCart = true);
      }
    }
  }

  void _goToCart() {
    setState(() => _isCartOpen = true);
  }

  String _extrairNumeroComanda(String barcode) {
    final numeros = barcode.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.isEmpty) return '';

    const int maxInt32 = 2147483647;
    final valor = int.tryParse(numeros) ?? 0;

    if (valor > maxInt32) {
      return numeros.substring(numeros.length - 9);
    }
    return numeros;
  }

  Future<void> _consultarComanda({String? numeroComanda}) async {
    late String numero;

    if (numeroComanda != null && numeroComanda.isNotEmpty) {
      numero = numeroComanda;
    } else {
      final barcode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      );

      if (barcode == null || barcode.isEmpty) return;
      numero = _extrairNumeroComanda(barcode);
    }

    if (numero.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Código de barras inválido. Tente novamente.',
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
      }
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.tachaoRed),
      ),
    );

    try {
      final service = ComandaService();
      const empresaId = 7;

      final comanda = await service.buscarComanda(numero, empresaId);

      if (!mounted) return;
      Navigator.pop(context); // fecha loading

      if (comanda == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Comanda não encontrada.',
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

      final comandaId = comanda['id'] as int;
      final status = comanda['status'] as String? ?? 'ABERTA';
      final totalComanda = (comanda['valor_total'] as num?)?.toDouble() ?? 0.0;

      final itens = await service.buscarItensComanda(comandaId);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => ComandaViewerSheet(
          numeroComanda: numero,
          itens: itens,
          total: totalComanda,
          status: status,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // fecha loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao consultar comanda: \$e',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _openLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LoginSheet(),
    );
  }

  void _showLogoutMenu(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (authProvider.isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: AppTheme.tachaoRed),
                  title: Text(
                    'Configurações',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppTheme.surface(context),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => const AppConfigSheet(),
                    );
                  },
                ),
              const Divider(),
              if (!authProvider.isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.login, color: AppTheme.tachaoRed),
                  title: Text(
                    'Login do Garçom',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openLoginSheet();
                  },
                ),
              if (authProvider.isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Sair',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    authProvider.logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Você saiu.', style: GoogleFonts.inter(fontSize: 14)),
                        backgroundColor: AppTheme.tachaoRed,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
              if (authProvider.isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text(
                    'Sair do App',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    // Desativa o modo quiosque para permitir fechar o app.
                    try {
                      await stopKioskMode();
                    } catch (_) {
                      // Ignora erro: pode já estar fora do modo quiosque.
                    }
                    if (Platform.isAndroid) {
                      SystemNavigator.pop();
                    } else {
                      exit(0);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, bool isTablet) {
    final storeStatus = StoreStatusHelper.checkStatus(DateTime.now());

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Color dotColor;
    final IconData icon;

    if (storeStatus.isOpen) {
      if (storeStatus.isClosingSoon) {
        bgColor = const Color(0xFFFFF8E1);
        borderColor = const Color(0xFFFFB300);
        textColor = const Color(0xFFE65100);
        dotColor = const Color(0xFFFFB300);
        icon = Icons.access_time;
      } else {
        bgColor = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFF4CAF50);
        textColor = const Color(0xFF2E7D32);
        dotColor = const Color(0xFF4CAF50);
        icon = Icons.check_circle;
      }
    } else {
      bgColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFE31E24);
      textColor = const Color(0xFFB71C1C);
      dotColor = const Color(0xFFE31E24);
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: dotColor),
          const SizedBox(width: 6),
          Text(
            '${storeStatus.statusText} • ${storeStatus.nextChangeText}',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 12 : 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isTablet,
    AuthProvider authProvider,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 16,
        12,
        isTablet ? 24 : 16,
        14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.border(context)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleAdminLogoTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo.png',
                height: isTablet ? 52 : 44,
                width: isTablet ? 52 : 44,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Napoleta',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 20 : 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                _buildStatusChip(context, isTablet),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showLogoutMenu(context, authProvider),
                icon: Icon(
                  Icons.settings_outlined,
                  color: AppTheme.textSecondary(context),
                ),
                tooltip: 'Configurações',
                visualDensity: VisualDensity.compact,
              ),
              if (authProvider.useComandaFeature)
                IconButton(
                  onPressed: _consultarComanda,
                  icon: Icon(
                    Icons.receipt_long_outlined,
                    color: AppTheme.textSecondary(context),
                  ),
                  tooltip: 'Consultar Comanda',
                  visualDensity: VisualDensity.compact,
                ),
              IconButton(
                onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                icon: Icon(
                  AppTheme.isDark(context)
                      ? Icons.wb_sunny_outlined
                      : Icons.dark_mode_outlined,
                  color: AppTheme.textSecondary(context),
                ),
                tooltip: 'Alternar tema',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySidebar(
    BuildContext context,
    bool isTablet,
    List<Category> categories,
  ) {
    final sidebarWidth = isTablet ? 140.0 : 100.0;

    return Container(
      width: sidebarWidth,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(isTablet ? 20 : 16),
          bottomRight: Radius.circular(isTablet ? 20 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadow(context),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(isTablet ? 20 : 16),
          bottomRight: Radius.circular(isTablet ? 20 : 16),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category.id == selectedCategoryId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => selectedCategoryId = category.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.tachaoRed : AppTheme.inputBg(context),
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected
                        ? null
                        : Border.all(color: AppTheme.border(context)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.tachaoRed.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.icon,
                        size: isTablet ? 30 : 24,
                        color: isSelected ? Colors.white : AppTheme.tachaoRed,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.displayName,
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textPrimary(context),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductsArea(
    BuildContext context,
    bool isTablet,
    bool isDesktop,
    int crossAxisCount,
    bool isGrid,
    List<Product> filteredProducts,
    String sectionTitle,
    MenuProvider menuProvider,
    double availableHeight,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadow(context),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          child: RefreshIndicator(
            onRefresh: () async => menuProvider.refresh(),
            color: AppTheme.tachaoRed,
            backgroundColor: AppTheme.surface(context),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sectionTitle,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 22 : 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.inputBg(context),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${filteredProducts.length} item${filteredProducts.length != 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filteredProducts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum produto nesta categoria ainda.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textSecondary(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (isGrid)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: availableHeight < 500 ? 0.95 : 0.74,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = filteredProducts[index];
                          return ProductCardGrid(
                            key: ValueKey('grid_${product.id}'),
                            product: product,
                            index: index,
                            onTap: () => _openProductDetail(product),
                          );
                        },
                        childCount: filteredProducts.length,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = filteredProducts[index];
                          return ProductCard(
                            key: ValueKey('list_${product.id}'),
                            product: product,
                            index: index,
                            onTap: () => _openProductDetail(product),
                          );
                        },
                        childCount: filteredProducts.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().totalItems;
    final menuProvider = context.watch<MenuProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (menuProvider.isLoading) {
      return const PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppTheme.tachaoRed,
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (menuProvider.error != null) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppTheme.background(context),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  menuProvider.error!,
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary(context)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: menuProvider.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tachaoRed,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final categories = menuProvider.categories;
    final allProducts = menuProvider.products;

    if (selectedCategoryId.isEmpty && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedCategoryId = categories.first.id;
          });
        }
      });
    }

    final filteredProducts = getFilteredProducts(allProducts);
    final sectionTitle = getSectionTitle(categories);

    final screensaverWidget = _isScreensaverActive
        ? Positioned.fill(
            child: ScreensaverCarousel(
              products: allProducts,
              onInteract: _handleUserInteraction,
            ),
          )
        : const SizedBox.shrink();

    return Stack(
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handleUserInteraction,
          onPointerMove: _handleUserInteraction,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isTablet = width >= 700;
              final isDesktop = width >= 1100;
              final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
              final isGrid = crossAxisCount > 1;

              return PopScope(
                canPop: false,
                child: Scaffold(
                  backgroundColor: AppTheme.background(context),
                  body: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(context, isTablet, authProvider),
                        Expanded(
                          child: categories.isEmpty
                              ? const Center(
                                  child: Text('Nenhuma categoria disponível.'),
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCategorySidebar(
                                      context,
                                      isTablet,
                                      categories,
                                    ),
                                    _buildProductsArea(
                                      context,
                                      isTablet,
                                      isDesktop,
                                      crossAxisCount,
                                      isGrid,
                                      filteredProducts,
                                      sectionTitle,
                                      menuProvider,
                                      constraints.maxHeight,
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  floatingActionButton: cartItemCount > 0
                      ? TweenAnimationBuilder<double>(
                          key: ValueKey(cartItemCount),
                          tween: Tween(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: FloatingActionButton.extended(
                            onPressed: _goToCart,
                            backgroundColor: AppTheme.tachaoRed,
                            icon: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                            ),
                            label: Text(
                              '$cartItemCount',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        screensaverWidget,
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _showMiniCart
                ? MiniCartPreview(
                    key: const ValueKey('mini_cart_preview'),
                    onClose: () => setState(() => _showMiniCart = false),
                  )
                : const SizedBox.shrink(key: ValueKey('mini_cart_hidden')),
          ),
        ),
        CartPanelBarrier(
          isOpen: _isCartOpen,
          onClose: () => setState(() => _isCartOpen = false),
        ),
        CartPanel(
          isOpen: _isCartOpen,
          onClose: () => setState(() => _isCartOpen = false),
        ),
      ],
    );
  }
}
