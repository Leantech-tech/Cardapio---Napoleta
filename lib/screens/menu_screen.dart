import 'dart:async';
import 'dart:io' show exit, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_checkout_data.dart';
import '../theme/app_theme.dart';
import '../data/api_config.dart';
import '../widgets/screensaver_carousel.dart';
import '../widgets/product_card.dart';
import '../widgets/login_sheet.dart';
import '../widgets/app_config_sheet.dart';
import '../widgets/support_login_sheet.dart';
import '../widgets/product_card_grid.dart';
import '../widgets/barcode_scanner_screen.dart';
import '../widgets/comanda_viewer_sheet.dart';
import '../widgets/cart_panel.dart';
import '../widgets/mini_cart_preview.dart';
import '../widgets/order_checkout_dialog.dart';
import '../widgets/totem_mode_selector.dart';
import '../services/cart_checkout_service.dart';
import '../services/barcode_scanner_service.dart';
import '../services/comanda_service.dart';
import '../services/kiosk_service.dart';
import '../utils/auth_helper.dart';
import 'product_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with WidgetsBindingObserver {
  String selectedCategoryId = '';
  bool _isCartOpen = false;

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

    if (authProvider.useTotenMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mostrarSeletorModalidadeTotem();
        }
      });
    }
  }

  Future<void> _mostrarSeletorModalidadeTotem() async {
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }

    final modo = await TotemModeSelector.show(context);
    if (!mounted) return;

    switch (modo) {
      case TotemMode.acai:
        await _solicitarIdentificacaoCliente();
      case TotemMode.paleta:
        // TODO: vincular ao fluxo específico de paletas.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Opção Paleta será integrada em breve.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppTheme.brandPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      case null:
        // Usuário fechou o seletor sem escolher; nada a fazer.
        break;
    }
  }

  Future<void> _solicitarIdentificacaoCliente() async {
    if (!mounted) return;

    final autenticado = await requireAuth(context);
    if (!mounted || !autenticado) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      // Aguarda caso haja alguma rota/modal em transição.
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }

    final checkoutData = await OrderCheckoutDialog.show(
      context,
      initialStep: 2,
      tipoEntregaInicial: TipoEntrega.retirada,
      onBack: () async {
        Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          await _mostrarSeletorModalidadeTotem();
        }
      },
    );
    if (!mounted) return;

    if (checkoutData != null) {
      context.read<CheckoutProvider>().setCheckoutData(checkoutData);
    }
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
        context.read<CheckoutProvider>().clear();
      }
    });
  }

  void _resetInactivityTimer() {
    final estavaAtivo = _isScreensaverActive;
    if (_isScreensaverActive) {
      setState(() => _isScreensaverActive = false);
    }
    _startInactivityTimer();

    if (estavaAtivo && mounted) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.useTotenMode) {
        _mostrarSeletorModalidadeTotem();
      }
    }
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
      // Mostruário é exibido automaticamente enquanto houver itens no carrinho.
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
        child: CircularProgressIndicator(color: AppTheme.brandPurple),
      ),
    );

    try {
      final service = ComandaService();
      const empresaId = ApiConfig.empresaId;

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
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: AppTheme.brandPurple),
                title: Text(
                  'Configurações',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  final isAuthorized = await SupportLoginSheet.show(context);
                  if (isAuthorized && context.mounted) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppTheme.surface(context),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => const AppConfigSheet(),
                    );
                  }
                },
              ),
              const Divider(),
              if (!authProvider.isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.login, color: AppTheme.brandPurple),
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
                        backgroundColor: AppTheme.brandPurple,
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
                    await authProvider.logout();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Você saiu da conta.', style: GoogleFonts.inter(fontSize: 14)),
                          backgroundColor: AppTheme.brandPurple,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                    // Desativa o modo quiosque para permitir fechar o app.
                    try {
                      await stopKioskMode();
                    } catch (_) {
                      // Ignora erro: pode já estar fora do modo quiosque.
                    }
                    if (!kIsWeb && Platform.isAndroid) {
                      SystemNavigator.pop();
                    } else if (!kIsWeb) {
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

  Widget _buildHeader(
    BuildContext context,
    bool isTablet,
    AuthProvider authProvider,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallPhone = screenWidth < 360;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : (isSmallPhone ? 12 : 16),
        12,
        isTablet ? 24 : (isSmallPhone ? 12 : 16),
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
                height: isTablet ? 52 : (isSmallPhone ? 36 : 44),
                width: isTablet ? 52 : (isSmallPhone ? 36 : 44),
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
                    fontSize: isTablet ? 20 : (isSmallPhone ? 15 : 17),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
              ),
              if (authProvider.useComandaFeature)
                IconButton(
                  onPressed: _consultarComanda,
                  icon: Icon(
                    Icons.receipt_long_outlined,
                    color: AppTheme.textSecondary(context),
                  ),
                  tooltip: 'Consultar Comanda',
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallPhone = screenWidth < 360;
    final sidebarWidth = isTablet ? 160.0 : (isSmallPhone ? 92.0 : 120.0);

    return Container(
      width: sidebarWidth,
      margin: EdgeInsets.only(right: isSmallPhone ? 8 : 12),
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
          padding: EdgeInsets.symmetric(
            vertical: isSmallPhone ? 12 : 16,
            horizontal: isSmallPhone ? 6 : 10,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category.id == selectedCategoryId;
            return Padding(
              padding: EdgeInsets.only(bottom: isSmallPhone ? 8 : 12),
              child: GestureDetector(
                onTap: () => setState(() => selectedCategoryId = category.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallPhone ? 10 : 14,
                    horizontal: isSmallPhone ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.brandPurple : AppTheme.inputBg(context),
                    borderRadius: BorderRadius.circular(isSmallPhone ? 12 : 16),
                    border: isSelected
                        ? null
                        : Border.all(color: AppTheme.border(context)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.brandPurple.withValues(alpha: 0.35),
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
                        size: isTablet ? 34 : (isSmallPhone ? 22 : 28),
                        color: isSelected ? Colors.white : AppTheme.brandPurple,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        category.displayName,
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 14 : (isSmallPhone ? 10 : 12),
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
    bool useCompactCards,
    List<Product> filteredProducts,
    String sectionTitle,
    MenuProvider menuProvider,
    double availableHeight,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallPhone = screenWidth < 360;

    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: useCompactCards ? 8 : (isSmallPhone ? 10 : 16)),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(isTablet ? 20 : (isSmallPhone ? 12 : 16)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadow(context),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isTablet ? 20 : (isSmallPhone ? 12 : 16)),
          child: RefreshIndicator(
            onRefresh: () async => menuProvider.refresh(),
            color: AppTheme.brandPurple,
            backgroundColor: AppTheme.surface(context),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isSmallPhone ? 12 : 16,
                      isSmallPhone ? 12 : 16,
                      isSmallPhone ? 12 : 16,
                      8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            sectionTitle,
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 22 : (isSmallPhone ? 15 : 18),
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 72,
                              color: AppTheme.textSecondary(context).withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Nenhum produto nesta categoria ainda',
                              style: GoogleFonts.poppins(
                                fontSize: AppTheme.fontSizeLg,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Que tal escolher outra categoria ou atualizar o cardápio?',
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSizeMd,
                                color: AppTheme.textSecondary(context),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => menuProvider.refresh(),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Atualizar cardápio'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (isGrid)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isSmallPhone ? 12 : 16,
                      8,
                      useCompactCards ? 10 : (isSmallPhone ? 12 : 16),
                      32,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: availableHeight < 500
                            ? 1.1
                            : (useCompactCards ? 1.0 : (isSmallPhone ? 0.82 : 0.9)),
                        crossAxisSpacing: isSmallPhone ? 12 : 16,
                        mainAxisSpacing: isSmallPhone ? 12 : 16,
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
                    padding: EdgeInsets.fromLTRB(
                      isSmallPhone ? 12 : 16,
                      8,
                      useCompactCards ? 10 : (isSmallPhone ? 12 : 16),
                      32,
                    ),
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
          backgroundColor: AppTheme.brandPurple,
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
                    backgroundColor: AppTheme.brandPurple,
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

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1100;
    final showMiniCart = screenWidth >= 700;

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
              final useCompactCards = isTablet && !isDesktop;
              final crossAxisCount = isDesktop ? 3 : (useCompactCards ? 1 : (isTablet ? 2 : 1));
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
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.category_outlined,
                                          size: 64,
                                          color: AppTheme.textSecondary(context).withValues(alpha: 0.4),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Nenhuma categoria disponível',
                                          style: GoogleFonts.poppins(
                                            fontSize: AppTheme.fontSizeLg,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary(context),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Verifique a conexão ou tente atualizar o cardápio.',
                                          style: GoogleFonts.inter(
                                            fontSize: AppTheme.fontSizeMd,
                                            color: AppTheme.textSecondary(context),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
                                        ElevatedButton.icon(
                                          onPressed: () => menuProvider.refresh(),
                                          icon: const Icon(Icons.refresh, size: 18),
                                          label: const Text('Tentar novamente'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.brandPurple,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                      useCompactCards,
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
                            backgroundColor: AppTheme.brandPurple,
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
        if (showMiniCart && !_isScreensaverActive)
          Positioned(
            top: 90,
            right: 16,
            bottom: 16,
            child: SizedBox(
              width: isDesktop ? 320 : 280,
              child: MiniCartPreview(
                onCheckout: () async {
                  final authProvider = context.read<AuthProvider>();
                  final checkoutProvider = context.read<CheckoutProvider>();

                  final autenticado = await requireAuth(context);
                  if (!context.mounted || !autenticado) return;

                  OrderCheckoutData? checkoutData;

                  if (authProvider.useTotenMode && checkoutProvider.hasCheckoutData) {
                    checkoutData = checkoutProvider.checkoutData;
                  } else {
                    checkoutData = await OrderCheckoutDialog.show(context);
                  }

                  if (checkoutData == null || !context.mounted) return;

                  final cart = context.read<CartProvider>();
                  await const CartCheckoutService().sendOrder(
                    context,
                    cart,
                    checkoutData: checkoutData,
                  );
                },
              ),
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
