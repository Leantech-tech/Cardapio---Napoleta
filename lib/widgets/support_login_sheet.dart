import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SupportLoginSheet extends StatefulWidget {
  const SupportLoginSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SupportLoginSheet(),
    );
    return result ?? false;
  }

  @override
  State<SupportLoginSheet> createState() => _SupportLoginSheetState();
}

class _SupportLoginSheetState extends State<SupportLoginSheet> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Calcura a senha esperada para o usuário Suporte:
  /// Dia da semana (Dom=1, Seg=2, Ter=3, Qua=4, Qui=5, Sex=6, Sáb=7)
  /// + Ano (4 dígitos)
  /// + Mês (2 dígitos)
  /// + Dia do mês (2 dígitos)
  /// Exemplo: Quinta-feira, 30/07/2026 => 520260730
  static String getExpectedSupportPassword({DateTime? date}) {
    final now = date ?? DateTime.now();
    final weekdayNum = now.weekday == 7 ? 1 : now.weekday + 1;
    final yearStr = now.year.toString();
    final monthStr = now.month.toString().padLeft(2, '0');
    final dayStr = now.day.toString().padLeft(2, '0');
    return '$weekdayNum$yearStr$monthStr$dayStr';
  }

  void _validateAndSubmit() {
    setState(() => _error = null);

    final user = _userController.text.trim();
    final password = _passwordController.text.trim();

    if (user.isEmpty || password.isEmpty) {
      setState(() => _error = 'Informe o usuário e a senha de Suporte.');
      return;
    }

    final expectedPassword = getExpectedSupportPassword();

    if (user.toLowerCase() == 'suporte' && password == expectedPassword) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = 'Usuário ou senha de Suporte incorretos.');
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
      child: SingleChildScrollView(
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
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppTheme.brandPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acesso de Suporte',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      Text(
                        'Obrigatório para acessar as configurações',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _userController,
              decoration: InputDecoration(
                hintText: 'Usuário',
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
                  Icons.person_outline,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textPrimary(context),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Senha',
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
                  Icons.lock_outline,
                  color: AppTheme.textSecondary(context),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textSecondary(context),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textPrimary(context),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _validateAndSubmit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateAndSubmit,
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
                  'Acessar Configurações',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
