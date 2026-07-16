import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.total);

  void addItem(
    Product product,
    int quantity,
    String? observation,
    Map<String, List<String>> selectedOptions,
    Map<String, double> selectedOptionPrices,
    double optionsPrice,
  ) {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.productId == product.id &&
          item.observation == observation &&
          _selectedOptionsEqual(item.selectedOptions, selectedOptions),
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      final cartItem = CartItem(
        id: '${product.id}_${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        name: product.name,
        imagePath: product.imagePath,
        basePrice: product.price,
        quantity: quantity,
        observation: observation?.trim().isEmpty == true ? null : observation?.trim(),
        selectedOptions: selectedOptions,
        selectedOptionPrices: selectedOptionPrices,
        optionsPrice: optionsPrice,
      );
      _items.add(cartItem);
    }
    notifyListeners();
  }

  void removeItem(String cartItemId) {
    _items.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
  }

  void updateQuantity(String cartItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(cartItemId);
      return;
    }
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool _selectedOptionsEqual(
    Map<String, List<String>> a,
    Map<String, List<String>> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final listA = a[key]!..sort();
      final listB = b[key]!..sort();
      if (listA.length != listB.length) return false;
      for (int i = 0; i < listA.length; i++) {
        if (listA[i] != listB[i]) return false;
      }
    }
    return true;
  }
}
