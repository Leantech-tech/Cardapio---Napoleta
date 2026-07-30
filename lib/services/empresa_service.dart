import 'package:flutter/foundation.dart';
import '../data/api_config.dart';
import 'db_client.dart';

class EmpresaService {
  final DbClient _db = DbClient();

  Future<Map<String, dynamic>?> buscarPorId(int empresaId) async {
    try {
      final result = await _db.select(
        'empresa',
        filters: {'eq_id': empresaId.toString()},
        limit: 1,
      );
      return result.isEmpty ? null : result.first;
    } on Exception catch (e) {
      debugPrint('EmpresaService: erro ao buscar empresa: $e');
      rethrow;
    }
  }

  Future<String?> buscarWhatsapp() async {
    final empresa = await buscarPorId(ApiConfig.empresaId);
    if (empresa == null) return null;

    final whatsapp = empresa['whatsapp'] as String?;
    if (whatsapp == null || whatsapp.trim().isEmpty) return null;

    return whatsapp.trim();
  }
}
