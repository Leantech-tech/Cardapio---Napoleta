import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/api_config.dart';
import '../models/payment_method.dart';

class PaymentMethodService {
  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/menu/payment-methods?empresa_id=${ApiConfig.empresaId}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao carregar formas de pagamento: ${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];

    return data
        .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
