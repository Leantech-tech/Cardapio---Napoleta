import 'package:flutter/material.dart';
import '../models/payment_method.dart';
import '../services/payment_method_service.dart';

class PaymentMethodProvider extends ChangeNotifier {
  final PaymentMethodService _service = PaymentMethodService();

  List<PaymentMethod> _methods = [];
  bool _isLoading = false;
  String? _error;

  List<PaymentMethod> get methods => _methods;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPaymentMethods() async {
    if (_methods.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _methods = await _service.fetchPaymentMethods();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar formas de pagamento: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void refresh() {
    _methods = [];
    loadPaymentMethods();
  }
}
