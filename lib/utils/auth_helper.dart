import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Garante que o app está autenticado com as credenciais fixas do totem.
/// O cliente nunca vê uma tela de login — o login é sempre silencioso.
Future<bool> requireAuth(BuildContext context) async {
  final authProvider = context.read<AuthProvider>();
  if (authProvider.isLoggedIn) return true;

  // Tenta relogar silenciosamente com as credenciais fixas de cardápio.
  try {
    await authProvider.login(
      'cardapio@napoleta.com.br',
      '@J20r91s0',
    );
    return authProvider.isLoggedIn;
  } catch (e) {
    debugPrint('[AutoLogin] Falha no relogin silencioso: $e');
    return false;
  }
}
