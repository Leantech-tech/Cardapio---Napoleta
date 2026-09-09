import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/pricing.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  /// Preço base original (sem tabela de preço) por produto, capturado quando
  /// o item entra no carrinho. Permite recalcular/restaurar preços quando o
  /// cliente é identificado com tabela de preço depois de montar o carrinho.
  final Map<int, double> _precosBase = {};

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.total);

  void addItem(
    Product product,
    int quantity,
    String? observation,
    Map<String, List<String>> selectedOptions,
    Map<String, double> selectedOptionPrices,
    double optionsPrice, {
    Map<String, int> selectedOptionQuantities = const {},
  }) {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.productId == product.id &&
          item.observation == observation &&
          _selectedOptionsEqual(item.selectedOptions, selectedOptions) &&
          _selectedOptionQuantitiesEqual(
            item.selectedOptionQuantities,
            selectedOptionQuantities,
          ),
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      final produtoId = int.tryParse(product.id);
      if (produtoId != null) {
        _precosBase.putIfAbsent(produtoId, () => product.price);
      }
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
        selectedOptionQuantities: selectedOptionQuantities,
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
    _precosBase.clear();
    notifyListeners();
  }

  /// Aplica no carrinho os preços resolvidos pelo servidor.
  /// Produtos ausentes do resultado mantêm o preço base normal (PADRAO).
  void aplicarPrecosResolvidos(PricingResult resultado) {
    for (final item in _items) {
      final produtoId = int.tryParse(item.productId);
      if (produtoId == null) continue;
      final resolvido = resultado[produtoId];
      if (resolvido != null) {
        item.basePrice = resolvido.valor;
        item.precoOrigem = resolvido.origem;
        item.tabelaPrecoId = resolvido.tabelaPrecoId;
        item.promocaoId = resolvido.promocaoId;
        item.promocaoNome = resolvido.promocaoNome;
        item.precoPadrao = resolvido.precoPadrao;
      } else {
        final base = _precosBase[produtoId];
        if (base != null) item.basePrice = base;
        item.precoOrigem = PrecoOrigem.padrao;
        item.tabelaPrecoId = null;
        item.promocaoId = null;
        item.promocaoNome = null;
        item.precoPadrao = base;
      }
    }
    notifyListeners();
  }

  /// Restaura o preço normal dos itens do carrinho e limpa o snapshot.
  void restaurarPrecosNormais() {
    for (final item in _items) {
      final produtoId = int.tryParse(item.productId);
      final base = produtoId != null ? _precosBase[produtoId] : null;
      if (base != null) item.basePrice = base;
      item.precoOrigem = PrecoOrigem.padrao;
      item.tabelaPrecoId = null;
      item.promocaoId = null;
      item.promocaoNome = null;
      item.precoPadrao = base;
    }
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

  bool _selectedOptionQuantitiesEqual(
    Map<String, int> a,
    Map<String, int> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
