import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/api_config.dart';
import '../models/category.dart';
import '../models/product.dart';

class MenuService {
  Future<List<Category>> fetchCategories() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/menu/categories?empresa_id=${ApiConfig.empresaId}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao carregar categorias: ${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;

    return data
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> fetchProducts() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/menu/products?empresa_id=${ApiConfig.empresaId}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao carregar produtos: ${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;

    return data
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
