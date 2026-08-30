import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/api_config.dart';
import '../models/order_checkout_data.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/balcao_pedido_service.dart';
import '../services/comanda_service.dart';
import '../services/delivery_pedido_service.dart';
import '../services/order_tracking_service.dart';
import '../services/print_queue_service.dart';
import '../theme/app_theme.dart';
import '../providers/delivery_provider.dart';
import '../widgets/barcode_scanner_screen.dart';
import '../widgets/comanda_order_sheet.dart';
import '../widgets/order_tracking_dialog.dart';

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
    OrderCheckoutData? checkoutData,
  }) async {
    final authProvider = context.read<AuthProvider>();
    debugPrint('[CartCheckoutService] sendOrder - useTotenMode=${authProvider.useTotenMode}, useComandaFeature=${authProvider.useComandaFeature}');

    if (checkoutData == null) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Identifique o cliente antes de finalizar o pedido.',
        Colors.orange[700],
      );
      return;
    }

    // No modo totem o pedido é salvo no módulo Balcão do Minha Loja. O
    // backend já cuida da fila de impressão na mesma transação, então o
    // Cardápio não deve inserir diretamente em fila_impressao.
    if (authProvider.useTotenMode) {
      try {
        await BalcaoPedidoService().salvarPedido(
          cart.items,
          checkoutData,
          usuarioId: authProvider.userId,
        );
      } catch (e) {
        if (!context.mounted) return;
        _showSnackBar(
          context,
          'Erro ao salvar pedido no balcão: $e',
          Colors.red[600],
        );
        return;
      }

      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Pedido enviado para o balcão!',
        Colors.green[600],
      );
      cart.clear();
      onSuccess?.call();
      return;
    }

    if (!context.mounted) return;

    if (!authProvider.useComandaFeature) {
      await sendOrderViaWhatsApp(
        context,
        cart,
        onSuccess: onSuccess,
        checkoutData: checkoutData,
      );
      return;
    }

    if (!context.mounted) return;

    await sendOrderViaComanda(
      context,
      cart,
      numeroComanda: numeroComanda,
      onSuccess: onSuccess,
      checkoutData: checkoutData,
    );
  }

  Future<void> sendOrderViaComanda(
    BuildContext context,
    CartProvider cart, {
    String? numeroComanda,
    VoidCallback? onSuccess,
    OrderCheckoutData? checkoutData,
  }) async {
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
          if (checkoutData != null) ...{
            'cliente_id': checkoutData.customerId,
            'cliente_nome': checkoutData.nome,
            'cliente_cpf': checkoutData.cpf,
            'cliente_endereco': checkoutData.endereco,
            'tipo_entrega': checkoutData.tipoEntregaLabel,
            'forma_pagamento': checkoutData.formaPagamentoLabel,
            'pagamento_na_entrega': checkoutData.isEntrega,
          },
        },
      );
      await service.adicionarFilaImpressao(
        comandaId,
        empresaId,
        cart.items,
        numero,
        observacao: checkoutData,
      );

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
    OrderCheckoutData? checkoutData,
  }) async {
    // Persiste o pedido nas tabelas delivery antes de enviar por WhatsApp.
    // Itens sem modificador ficam apenas em delivery_pedido + delivery_pedido_item;
    // itens com modificador também preenchem delivery_pedido_item_modificador.
    debugPrint('[CartCheckoutService] sendOrderViaWhatsApp iniciado');
    Map<String, dynamic>? savedOrder;
    if (checkoutData != null) {
      try {
        final deliveryFee = context.read<DeliveryProvider>().deliveryFee ?? 0.0;
        debugPrint('[CartCheckoutService] deliveryFee: $deliveryFee');
        savedOrder = await DeliveryPedidoService().salvarPedido(
          cart.items,
          checkoutData,
          taxaEntrega: deliveryFee,
        );
      } catch (e) {
        if (!context.mounted) return;
        _showSnackBar(
          context,
          'Erro ao salvar pedido no delivery: $e',
          Colors.red[600],
        );
        return;
      }
    }

    // No modo Link, exibe popup de acompanhamento quando houver um
    // delivery_pedido criado. O fluxo de WhatsApp continua normalmente.
    if (savedOrder != null && context.mounted) {
      final orderId = savedOrder['id'];
      if (orderId is int && orderId > 0) {
        // Guarda localmente o vínculo CPF → pedido para reabrir o
        // acompanhamento depois que o popup for fechado.
        if (checkoutData != null) {
          await OrderTrackingService.saveLastOrderByCpf(
            checkoutData.cpf,
            orderId,
          );
        }
        if (!context.mounted) return;
        // Não aguarda o fechamento do popup para não travar o envio pelo
        // WhatsApp; o usuário pode acompanhar o status enquanto isso.
        OrderTrackingDialog.show(
          context,
          orderId: orderId,
          isRetirada: checkoutData?.isRetirada,
        );
      }
    }

    if (!context.mounted) return;
    final authProvider = context.read<AuthProvider>();

    if (checkoutData != null) {
      try {
        final deliveryPedidoId = savedOrder != null ? savedOrder['id'] as int? : null;
        await PrintQueueService().adicionarPedido(
          itens: cart.items,
          checkoutData: checkoutData,
          isTotem: false,
          storeAddress: authProvider.storeAddress,
          deliveryPedidoId: deliveryPedidoId,
        );
      } catch (e) {
        if (!context.mounted) return;
        _showSnackBar(
          context,
          'Erro ao enfileirar pedido para impressão: $e',
          Colors.red[600],
        );
        return;
      }
    }

    if (!context.mounted) return;

    // Sempre busca o número mais atual da tabela empresa antes de enviar.
    if (authProvider.whatsappNumber.isEmpty) {
      await authProvider.refreshEmpresaData();
    }

    var rawPhoneNumber = authProvider.whatsappNumber;
    if (rawPhoneNumber.isEmpty) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Número do WhatsApp da loja não configurado.',
        Colors.orange[700],
      );
      return;
    }

    final phoneNumber = rawPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final storeAddress = authProvider.storeAddress;

    final buffer = StringBuffer();
    buffer.writeln('Pedido finalizado!');
    buffer.writeln();

    for (final item in cart.items) {
      buffer.writeln('• ${item.quantity}x ${item.name}');
    }

    buffer.writeln();
    buffer.writeln('Total de itens: ${cart.totalItems}');
    buffer.writeln(
      'Valor total: R\$ ${cart.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
    );

    if (checkoutData != null) {
      buffer.writeln();
      buffer.writeln('Tipo: ${checkoutData.tipoEntregaLabel}');
      buffer.writeln('Cliente: ${checkoutData.nome}');
      buffer.writeln('CPF: ${checkoutData.cpf}');
      if (checkoutData.endereco.isNotEmpty) {
        buffer.writeln('Endereço: ${checkoutData.endereco}');
      }
      buffer.writeln('Pagamento: ${checkoutData.formaPagamentoLabel}');
      if (checkoutData.isEntrega) {
        buffer.writeln('(O entregador receberá o pagamento na entrega)');
      }
    }

    if (storeAddress.isNotEmpty && (checkoutData == null || checkoutData.isRetirada)) {
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
