import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/delivery_provider.dart';
import '../theme/app_theme.dart';

class DeliveryCalculatorSheet extends StatefulWidget {
  const DeliveryCalculatorSheet({super.key});

  @override
  State<DeliveryCalculatorSheet> createState() =>
      _DeliveryCalculatorSheetState();
}

class _DeliveryCalculatorSheetState extends State<DeliveryCalculatorSheet> {
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _calculate() {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;
    context.read<DeliveryProvider>().calculateFee(address);
  }

  void _clear() {
    _addressController.clear();
    context.read<DeliveryProvider>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final delivery = context.watch<DeliveryProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          Text(
            'Calcular taxa de entrega',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Digite seu endereço completo com bairro para saber o valor do frete.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Ex: Rua das Flores, 123 - Centro',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: AppTheme.inputBg(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: AppTheme.textSecondary(context),
              ),
              suffixIcon: delivery.address != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: _clear,
                    )
                  : null,
            ),
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary(context)),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: delivery.isCalculating ? null : _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tachaoRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: delivery.isCalculating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Calcular',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          if (delivery.deliveryFee != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.inputBg(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Endereço informado:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    delivery.address!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: AppTheme.tachaoRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Taxa de entrega:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'R\$ ${delivery.deliveryFee!.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.tachaoRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
