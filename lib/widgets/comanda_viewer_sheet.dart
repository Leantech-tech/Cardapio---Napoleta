import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'adaptive_image.dart';

class ComandaViewerSheet extends StatelessWidget {
  final String numeroComanda;
  final List<Map<String, dynamic>> itens;
  final double total;
  final String status;

  const ComandaViewerSheet({
    super.key,
    required this.numeroComanda,
    required this.itens,
    required this.total,
    required this.status,
  });

  String _formatPrice(double price) {
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Color _statusColor() {
    switch (status.toUpperCase()) {
      case 'ABERTA':
        return const Color(0xFF4CAF50);
      case 'FECHADA':
        return const Color(0xFFE31E24);
      case 'PAGA':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (status.toUpperCase()) {
      case 'ABERTA':
        return 'Aberta';
      case 'FECHADA':
        return 'Fechada';
      case 'PAGA':
        return 'Paga';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFFFF9800),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comanda nº $numeroComanda',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor().withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          // Items list
          if (itens.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 56,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum item pedido nesta comanda ainda.',
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
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: itens.length,
                itemBuilder: (context, index) {
                  final item = itens[index];
                  final quantidade = (item['quantidade'] as num?)?.toInt() ?? 0;
                  final valorTotal = (item['valor_total_item'] as num?)?.toDouble() ?? 0.0;
                  final observacao = item['observacao'] as String?;
                  final produto = item['produto'] as Map<String, dynamic>?;
                  final nomeProduto = produto?['nome'] as String? ?? 'Produto';
                  final fotoUrl = produto?['foto_url'] as String? ?? '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Foto do produto
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: fotoUrl.isNotEmpty
                              ? AdaptiveNetworkImage(
                                  key: ValueKey(fotoUrl),
                                  imageUrl: fotoUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  placeholder: (context) => Container(
                                    width: 56,
                                    height: 56,
                                    color: AppTheme.inputBg(context),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.tachaoRed,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorBuilder: (context, error) => Container(
                                    width: 56,
                                    height: 56,
                                    color: AppTheme.inputBg(context),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: AppTheme.textSecondary(context),
                                      size: 24,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  color: AppTheme.inputBg(context),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: AppTheme.textSecondary(context),
                                    size: 24,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nomeProduto,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              if (observacao != null && observacao.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Obs: $observacao',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary(context),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.inputBg(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${quantidade}x',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.tachaoRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatPrice(valorTotal),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 12),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total gasto',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              Text(
                _formatPrice(total),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tachaoRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tachaoRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              'Fechar',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
