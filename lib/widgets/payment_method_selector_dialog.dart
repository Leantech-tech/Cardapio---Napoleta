import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/order_checkout_data.dart';
import '../models/payment_method.dart';
import '../providers/checkout_provider.dart';
import '../providers/payment_method_provider.dart';
import '../theme/app_theme.dart';

/// Diálogo para seleção da forma de pagamento no modo totem.
///
/// Ao confirmar, atualiza o [CheckoutProvider] com a nova forma de pagamento
/// escolhida e retorna os dados atualizados.
class PaymentMethodSelectorDialog extends StatefulWidget {
  final OrderCheckoutData checkoutData;

  const PaymentMethodSelectorDialog({
    super.key,
    required this.checkoutData,
  });

  static Future<OrderCheckoutData?> show(
    BuildContext context, {
    required OrderCheckoutData checkoutData,
  }) async {
    return showDialog<OrderCheckoutData?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentMethodSelectorDialog(checkoutData: checkoutData),
    );
  }

  @override
  State<PaymentMethodSelectorDialog> createState() =>
      _PaymentMethodSelectorDialogState();
}

class _PaymentMethodSelectorDialogState
    extends State<PaymentMethodSelectorDialog> {
  PaymentMethod? _selectedMethod;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final provider = context.read<PaymentMethodProvider>();
    try {
      await provider.loadPaymentMethods();
      if (!mounted) return;

      final methods = provider.methods;
      final current = widget.checkoutData.paymentMethod;
      setState(() {
        _selectedMethod = methods.firstWhere(
          (m) => m.id == current.id,
          orElse: () => methods.isNotEmpty ? methods.first : current,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar formas de pagamento: $e';
        _isLoading = false;
      });
    }
  }

  void _confirmar() {
    if (_selectedMethod == null) return;

    final updated = widget.checkoutData.copyWithPaymentMethod(_selectedMethod!);
    context.read<CheckoutProvider>().setCheckoutData(updated);
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxDialogWidth = screenWidth < 680 ? screenWidth * 0.95 : 420.0;

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
                      color: AppTheme.brandPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.payment_outlined,
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
                          'Forma de pagamento',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Escolha como o cliente vai pagar',
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
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppTheme.brandPurple),
                  ),
                )
              else if (_error != null)
                Text(
                  _error!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.red[600],
                  ),
                )
              else
                Consumer<PaymentMethodProvider>(
                  builder: (context, provider, _) {
                    final methods = provider.methods;
                    if (methods.isEmpty) {
                      return Text(
                        'Nenhuma forma de pagamento cadastrada.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary(context),
                        ),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.inputBg(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: _selectedMethod,
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppTheme.textSecondary(context),
                          ),
                          dropdownColor: AppTheme.surface(context),
                          hint: Text(
                            'Selecione uma forma de pagamento',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textPrimary(context),
                          ),
                          items: methods.map((method) {
                            return DropdownMenuItem<PaymentMethod>(
                              value: method,
                              child: Text(
                                method.descricao,
                                style: GoogleFonts.inter(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedMethod = value);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading || _selectedMethod == null ? null : _confirmar,
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
                        'Confirmar',
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
