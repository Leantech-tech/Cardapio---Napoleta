import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AppConfigSheet extends StatefulWidget {
  const AppConfigSheet({super.key});

  @override
  State<AppConfigSheet> createState() => _AppConfigSheetState();
}

class _AppConfigSheetState extends State<AppConfigSheet> {
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addressController.text = context.read<AuthProvider>().storeAddress;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final useComanda = authProvider.useComandaFeature;

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
            'Configurações',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Controle o acesso às comandas no cardápio.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: useComanda,
            onChanged: (value) async {
              if (value != null) {
                await authProvider.setUseComandaFeature(value);
              }
            },
            title: Text(
              'Usar funcionalidade de comandas',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context),
              ),
            ),
            subtitle: Text(
              useComanda
                  ? 'Os pedidos serão vinculados a uma comanda.'
                  : 'Os pedidos serão enviados automaticamente pelo WhatsApp.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
                height: 1.4,
              ),
            ),
            activeColor: AppTheme.tachaoRed,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          Text(
            'Endereço da loja',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Exibido na mensagem do pedido para clientes que desejam retirar na loja.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressController,
            onChanged: (value) => authProvider.setStoreAddress(value),
            decoration: InputDecoration(
              hintText: 'Ex: Rua das Palmeiras, 123 - Centro',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: AppTheme.inputBg(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tachaoRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Concluir',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
