import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class AppConfigSheet extends StatefulWidget {
  const AppConfigSheet({super.key});

  @override
  State<AppConfigSheet> createState() => _AppConfigSheetState();
}

class _AppConfigSheetState extends State<AppConfigSheet> {
  final _addressController = TextEditingController();
  final _whatsappController = TextEditingController();
  late bool _useComanda;
  late bool _useTotenMode;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final themeProvider = context.read<ThemeProvider>();
    _addressController.text = authProvider.storeAddress;
    _whatsappController.text = authProvider.whatsappNumber;
    _useComanda = authProvider.useComandaFeature;
    _useTotenMode = authProvider.useTotenMode;
    _isDarkMode = themeProvider.isDarkMode;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    final authProvider = context.read<AuthProvider>();
    final themeProvider = context.read<ThemeProvider>();

    await authProvider.setUseComandaFeature(_useComanda);
    await authProvider.setUseTotenMode(_useTotenMode);
    await authProvider.setStoreAddress(_addressController.text);
    await authProvider.setWhatsappNumber(_whatsappController.text);
    await themeProvider.setDarkMode(_isDarkMode);

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Configurações salvas',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.brandPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: AppTheme.fontSizeLg,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary(context),
      ),
    );
  }

  Widget _buildSectionDescription(BuildContext context, String description) {
    return Text(
      description,
      style: GoogleFonts.inter(
        fontSize: AppTheme.fontSizeSm,
        color: AppTheme.textSecondary(context),
        height: 1.4,
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget control,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.inputBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.brandPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.brandPurple, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSizeSm,
                      color: AppTheme.textSecondary(context),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          control,
        ],
      ),
    );
  }

  Widget _buildModeCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.brandPurple,
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSizeSm,
            color: AppTheme.textPrimary(context),
          ),
        ),
      ],
    );
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
      child: SingleChildScrollView(
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
              fontSize: AppTheme.fontSizeXl,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          _buildSectionDescription(
            context,
            'Controle o acesso às comandas, endereço da loja e aparência do cardápio.',
          ),
          const SizedBox(height: 20),
          _buildCard(
            context: context,
            icon: Icons.receipt_long_outlined,
            title: 'Usar comandas',
            subtitle: _useComanda
                ? 'Os pedidos serão vinculados a uma comanda.'
                : 'Os pedidos serão enviados automaticamente pelo WhatsApp.',
            control: Switch(
              value: _useComanda,
              onChanged: (value) => setState(() => _useComanda = value),
              activeThumbColor: AppTheme.brandPurple,
            ),
          ),
          if (!_useComanda) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'WhatsApp para Envio'),
                  const SizedBox(height: 6),
                  _buildSectionDescription(
                    context,
                    'DDD + número para onde os pedidos serão enviados.',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Ex: 5512988997924',
                      hintStyle: GoogleFonts.inter(
                        fontSize: AppTheme.fontSizeSm,
                        color: Colors.grey[400],
                      ),
                      prefixIcon: const Icon(Icons.phone, color: AppTheme.brandPurple, size: 20),
                      filled: true,
                      fillColor: AppTheme.inputBg(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    style: GoogleFonts.inter(fontSize: AppTheme.fontSizeMd),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
          _buildCard(
            context: context,
            icon: Icons.devices_outlined,
            title: 'Modo de uso',
            subtitle: _useTotenMode
                ? 'A identificação do cliente será ao entrar no app.'
                : 'A identificação do cliente será ao finalizar o pedido.',
            control: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeCheckbox(
                  label: 'Toten',
                  value: _useTotenMode,
                  onChanged: (value) {
                    if (value != null && value) {
                      setState(() => _useTotenMode = true);
                    }
                  },
                ),
                _buildModeCheckbox(
                  label: 'Link',
                  value: !_useTotenMode,
                  onChanged: (value) {
                    if (value != null && value) {
                      setState(() => _useTotenMode = false);
                    }
                  },
                ),
              ],
            ),
          ),
          _buildCard(
            context: context,
            icon: Icons.dark_mode_outlined,
            title: 'Tema escuro',
            subtitle: 'Muda a aparência do cardápio entre claro e escuro.',
            control: Switch(
              value: _isDarkMode,
              onChanged: (value) => setState(() => _isDarkMode = value),
              activeThumbColor: AppTheme.brandPurple,
            ),
          ),
          const SizedBox(height: 8),
          _buildSectionTitle(context, 'Endereço da loja'),
          const SizedBox(height: 6),
          _buildSectionDescription(
            context,
            'Exibido na mensagem do pedido para clientes que desejam retirar na loja.',
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Ex: Rua das Palmeiras, 123 - Centro',
              hintStyle: GoogleFonts.inter(
                fontSize: AppTheme.fontSizeSm,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: AppTheme.inputBg(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: AppTheme.fontSizeMd),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAndClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPurple,
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
                  fontSize: AppTheme.fontSizeMd,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
    );
  }
}
