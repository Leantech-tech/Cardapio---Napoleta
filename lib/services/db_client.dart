import 'dart:convert';
import 'api_client.dart';

class DbClient {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, String>? filters,
    String? columns,
    String? order,
    int? limit,
  }) async {
    final query = <String, String>{};
    if (columns != null && columns.isNotEmpty) {
      query['select'] = columns;
    }
    if (order != null && order.isNotEmpty) {
      query['order'] = order;
    }
    if (limit != null) {
      query['limit'] = limit.toString();
    }
    if (filters != null) {
      query.addAll(filters);
    }

    final uri = _api.buildUri('/api/v1/db/$table', queryParams: query);
    final response = await _api.get(uri);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> selectSingle(
    String table, {
    Map<String, String>? filters,
    String? columns,
  }) async {
    final results = await select(
      table,
      filters: filters,
      columns: columns,
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  Future<List<Map<String, dynamic>>> insert(
    String table,
    Object payload,
  ) async {
    final uri = _api.buildUri('/api/v1/db/$table');
    final response = await _api.post(uri, body: payload);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> insertSingle(
    String table,
    Map<String, dynamic> payload,
  ) async {
    final results = await insert(table, payload);
    if (results.isEmpty) {
      throw Exception('Insert não retornou registros');
    }
    return results.first;
  }

  Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> payload, {
    required Map<String, String> filters,
  }) async {
    final uri = _api.buildUri('/api/v1/db/$table', queryParams: filters);
    final response = await _api.patch(uri, body: payload);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> delete(
    String table, {
    required Map<String, String> filters,
  }) async {
    final uri = _api.buildUri('/api/v1/db/$table', queryParams: filters);
    final response = await _api.delete(uri);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }
}
