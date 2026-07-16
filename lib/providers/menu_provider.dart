import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _menuService = MenuService();

  List<Category> _categories = [];
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  List<Category> get categories => _categories;
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MenuProvider() {
    loadMenu();
  }

  Future<void> loadMenu() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _menuService.fetchCategories(),
        _menuService.fetchProducts(),
      ]);

      _categories = results[0] as List<Category>;
      _products = results[1] as List<Product>;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar o cardápio: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void refresh() {
    loadMenu();
  }
}
