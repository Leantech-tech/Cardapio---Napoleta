import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/order_tracking_service.dart';
import '../theme/app_theme.dart';
import 'order_tracking_dialog.dart';

/// Diálogo para o cliente informar o CPF e reabrir o acompanhamento do
/// último pedido delivery em aberto vinculado ao documento.
class OrderTrackingCpfDialog extends StatefulWidget {
  const OrderTrackingCpfDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OrderTrackingCpfDialog(),
    );
  }

  @override
  State<OrderTrackingCpfDialog> createState() => _OrderTrackingCpfDialogState();
}

class _OrderTrackingCpfDialogState extends State<OrderTrackingCpfDialog> {
  final _cpfController = TextEditingController();
  final _service = OrderTrackingService();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  String _formatarCpf(String texto) {
    final numeros = texto.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length > 11) return numeros.substring(0, 11);

    final buffer = StringBuffer();
    for (int i = 0; i < numeros.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(numeros[i]);
    }
    return buffer.toString();
  }

  Future<void> _buscarPedido() async {
    final cpfLimpo = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');

    setState(() => _error = null);

    if (cpfLimpo.length != 11) {
      setState(() => _error = 'Digite um CPF válido com 11 dígitos.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderId = await _service.findLatestOpenOrderByCpf(cpfLimpo);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (orderId == null) {
        setState(() => _error = 'Nenhum pedido em aberto encontrado para este CPF.');
        return;
      }

      Navigator.of(context).pop();

      if (mounted) {
        await OrderTrackingDialog.show(context, orderId: orderId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Erro ao buscar pedido: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxDialogWidth = screenWidth < 680 ? screenWidth * 0.95 : 480.0;

    return Dialog(
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxDialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search_outlined,
                      color: AppTheme.brandPurple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acompanhe seu pedido',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Informe o CPF usado na compra',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _cpfController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = _formatarCpf(newValue.text);
                    return TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                  }),
                ],
                decoration: InputDecoration(
                  labelText: 'CPF',
                  hintText: '000.000.000-00',
                  filled: true,
                  fillColor: AppTheme.inputBg(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.brandPurple, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textPrimary(context),
                ),
                onSubmitted: (_) => _buscarPedido(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.red[600],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _buscarPedido,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: AppTheme.brandPurple.withValues(alpha: 0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Buscar pedido',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary(context),
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(color: AppTheme.border(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
