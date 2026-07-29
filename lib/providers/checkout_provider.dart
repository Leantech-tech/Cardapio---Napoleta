import 'package:flutter/material.dart';
import '../models/order_checkout_data.dart';

class CheckoutProvider with ChangeNotifier {
  OrderCheckoutData? _checkoutData;

  OrderCheckoutData? get checkoutData => _checkoutData;

  bool get hasCheckoutData => _checkoutData != null;

  void setCheckoutData(OrderCheckoutData data) {
    _checkoutData = data;
    notifyListeners();
  }

  void clear() {
    _checkoutData = null;
    notifyListeners();
  }
}
