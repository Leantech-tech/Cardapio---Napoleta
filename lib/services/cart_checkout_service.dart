import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/comanda_service.dart';
import '../theme/app_theme.dart';
import '../widgets/barcode_scanner_screen.dart';
import '../widgets/comanda_order_sheet.dart';

class CartCheckoutService {
  const CartCheckoutService();

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

  Future<void> sendOrder(
    BuildContext context,
    CartProvider cart, {
    String? numeroComanda,
    VoidCallback? onSuccess,
  }) async {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.useComandaFeature) {
      await sendOrderViaWhatsApp(context, cart, onSuccess: onSuccess);
      return;
    }

    late String numero;

    if (numeroComanda != null && numeroComanda.isNotEmpty) {
      numero = numeroComanda;
    } else {
      final navigator = Navigator.of(context);
      final barcode = await navigator.push<String>(
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      );

      if (barcode == null || barcode.isEmpty) return;
      numero = _extrairNumeroComanda(barcode);
    }

    if (!context.mounted) return;

    if (numero.isEmpty) {
      _showSnackBar(
        context,
        'Código de barras inválido. Tente novamente.',
        Colors.orange[700],
      );
      return;
    }

    try {
      final service = ComandaService();
      const empresaId = ApiConfig.empresaId;

      var comanda = await service.buscarComanda(numero, empresaId);
      comanda ??= await service.criarComanda(numero, empresaId);

      final comandaId = comanda['id'] as int;
      final mesaId = comanda['mesa_id'] as int?;

      await service.adicionarItens(comandaId, empresaId, cart.items);
      await service.atualizarTotalComanda(comandaId);
      await service.registrarLog(
        comandaId,
        mesaId,
        empresaId,
        'LANCAMENTO_ITEM',
        {
          'numero_comanda': numero,
          'qtd_itens': cart.items.length,
          'valor_total': cart.totalPrice,
        },
      );
      await service.adicionarFilaImpressao(comandaId, empresaId, cart.items, numero);

      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => ComandaOrderSheet(
          numeroComanda: numero,
          itens: cart.items,
          total: cart.totalPrice,
        ),
      );

      _showSnackBar(
        context,
        'Pedido enviado com sucesso!',
        Colors.green[600],
      );
      cart.clear();
      onSuccess?.call();
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Erro ao enviar pedido: $e',
        Colors.red[600],
      );
    }
  }

  Future<void> sendOrderViaWhatsApp(
    BuildContext context,
    CartProvider cart, {
    VoidCallback? onSuccess,
  }) async {
    const phoneNumber = '5512988997924';
    final authProvider = context.read<AuthProvider>();
    final storeAddress = authProvider.storeAddress;

    final buffer = StringBuffer();
    buffer.writeln('Pedido finalizado!');
    buffer.writeln();

    for (final item in cart.items) {
      buffer.writeln('• ${item.quantity}x ${item.name}');
    }

    buffer.writeln();
    buffer.writeln('Total de itens: ${cart.totalItems}');

    if (storeAddress.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Endereço da loja para retirada:');
      buffer.writeln(storeAddress);
    }

    final message = buffer.toString();
    final uri = Uri.parse(
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Não foi possível abrir o WhatsApp.');
      }

      if (!context.mounted) return;

      _showSnackBar(
        context,
        'Pedido enviado pelo WhatsApp!',
        Colors.green[600],
      );
      cart.clear();
      onSuccess?.call();
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Erro ao enviar pedido: $e',
        Colors.red[600],
      );
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    Color? backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
