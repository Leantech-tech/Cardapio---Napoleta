import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/api_config.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserName = 'auth_user_name';
  static const String _keyUseComandaFeature = 'use_comanda_feature';
  static const String _keyStoreAddress = 'store_address';
  static const String _keyUseTotenMode = 'use_toten_mode';
  static const String _keyWhatsappNumber = 'whatsapp_number';

  Map<String, dynamic>? _perfil;
  Map<String, dynamic>? _empresa;
  bool _isLoading = false;
  String? _error;
  bool _useComandaFeature = true;
  bool _useTotenMode = false;
  String _storeAddress = '';
  String _whatsappNumber = '';

  bool get isLoggedIn => _perfil != null;
  Map<String, dynamic>? get perfil => _perfil;
  Map<String, dynamic>? get empresa => _empresa;
  String get userName => _perfil?['nome'] ?? '';
  String get userId => _perfil?['user_id']?.toString() ?? '';
  String get storeAddress => _storeAddress;
  String get whatsappNumber => _whatsappNumber;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get useComandaFeature => _useComandaFeature;
  bool get useTotenMode => _useTotenMode;

  AuthProvider() {
    checkSession();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _useComandaFeature = prefs.getBool(_keyUseComandaFeature) ?? true;
    _useTotenMode = prefs.getBool(_keyUseTotenMode) ?? false;
    _storeAddress = prefs.getString(_keyStoreAddress) ?? '';
    _whatsappNumber = prefs.getString(_keyWhatsappNumber) ?? '5512988997924';
    notifyListeners();
  }

  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();

    await ApiClient().init();

    await loadSettings();

    if (ApiClient().isAuthenticated) {
      await _fetchMe();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchMe() async {
    try {
      final uri = ApiClient().buildUri('/api/v1/auth/me');
      final response = await ApiClient().get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      _perfil = body['usuario'] as Map<String, dynamic>?;
      _empresa = body['empresa'] as Map<String, dynamic>?;

      if (_perfil != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserId, userId);
        await prefs.setString(_keyUserName, userName);
      }
    } catch (e) {
      debugPrint('Erro ao buscar sessão: $e');
      await ApiClient().clearToken();
      _perfil = null;
      _empresa = null;
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = ApiClient().buildUri('/api/v1/auth/login');
      final response = await ApiClient().post(uri, body: {
        'email': email.trim(),
        'senha': password.trim(),
      });

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['token'] as String?;

      if (token == null || token.isEmpty) {
        throw Exception('Credenciais inválidas');
      }

      await ApiClient().setToken(token);

      _perfil = (body['session'] as Map<String, dynamic>?)?['usuario']
          as Map<String, dynamic>?;
      _empresa = (body['session'] as Map<String, dynamic>?)?['empresa']
          as Map<String, dynamic>?;

      if (_perfil == null) {
        await ApiClient().clearToken();
        throw Exception('Usuário sem acesso à empresa ${ApiConfig.empresaId}');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyUserName, userName);
    } on ApiException catch (e) {
      _error = e.message ?? 'Erro ao fazer login';
      throw Exception(_error);
    } catch (e) {
      _error = 'Erro ao fazer login: $e';
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiClient().clearToken();
    _perfil = null;
    _empresa = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);

    notifyListeners();
  }

  Future<void> setUseComandaFeature(bool value) async {
    _useComandaFeature = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseComandaFeature, value);
    notifyListeners();
  }

  Future<void> setStoreAddress(String value) async {
    _storeAddress = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStoreAddress, _storeAddress);
    notifyListeners();
  }

  Future<void> setUseTotenMode(bool value) async {
    _useTotenMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseTotenMode, value);
    notifyListeners();
  }

  Future<void> setWhatsappNumber(String value) async {
    _whatsappNumber = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWhatsappNumber, _whatsappNumber);
    notifyListeners();
  }
}
