import 'dart:convert';
import 'package:http/http.dart' as http;

class CepService {
  static const String _baseUrl = 'https://viacep.com.br/ws';

  /// Busca o endereço a partir de um CEP contendo apenas números.
  /// Retorna um [CepResult] com os dados ou null em caso de erro/CEP inválido.
  static Future<CepResult?> buscar(String cep) async {
    final numeros = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length != 8) return null;

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$numeros/json/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['erro'] == true) return null;

      return CepResult.fromMap(data);
    } catch (_) {
      return null;
    }
  }
}

class CepResult {
  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String localidade;
  final String uf;

  const CepResult({
    required this.cep,
    required this.logradouro,
    required this.complemento,
    required this.bairro,
    required this.localidade,
    required this.uf,
  });

  factory CepResult.fromMap(Map<String, dynamic> map) {
    return CepResult(
      cep: (map['cep'] ?? '').toString(),
      logradouro: (map['logradouro'] ?? '').toString(),
      complemento: (map['complemento'] ?? '').toString(),
      bairro: (map['bairro'] ?? '').toString(),
      localidade: (map['localidade'] ?? '').toString(),
      uf: (map['uf'] ?? '').toString(),
    );
  }

  String get enderecoCompleto {
    final partes = [
      logradouro,
      bairro,
      localidade.isNotEmpty && uf.isNotEmpty ? '$localidade - $uf' : '',
      cep,
    ].where((p) => p.isNotEmpty);

    return partes.join(', ');
  }
}
