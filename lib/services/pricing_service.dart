import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/api_config.dart';
import '../models/pricing.dart';
import 'api_client.dart';

/// Item do contrato de preços enviado ao servidor.
class PricingItemRequest {
  final int produtoId;
  final int quantidade;
  final double valorAdicional;
  final bool aplicaPromocao;

  const PricingItemRequest({
    required this.produtoId,
    required this.quantidade,
    this.valorAdicional = 0,
    this.aplicaPromocao = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'produto_id': produtoId,
      'quantidade': quantidade,
      'valor_adicional': valorAdicional,
      'aplica_promocao': aplicaPromocao,
    };
  }
}

/// Serviço de resolução de preços do Cardápio.
///
/// Delegada ao Minha Loja a decisão final de preço: tabela de preço do cliente
/// (quando ativa), promoções aplicáveis (De/Por e Atacado) e preço padrão. O
/// aplicativo apenas aplica e exibe o resultado — nunca é a autoridade do preço.
///
/// Usa a rota `POST /api/v1/sales/prices` documentada em
/// DOCUMENTACAO_TABELA_PRECOS.md / DOCUMENTACAO_PROMOCOES.md.
class PricingService {
  final ApiClient _api;

  PricingService({ApiClient? api}) : _api = api ?? ApiClient();

  static const Duration timeout = Duration(seconds: 10);

  /// Resolve em lote os preços dos itens informados. [pessoaId] é opcional:
  /// promoções são avaliadas mesmo sem cliente identificado.
  ///
  /// As linhas são preservadas no envio. O servidor soma as quantidades por
  /// produto para avaliar Atacado e usa o adicional de cada linha ao verificar
  /// eventual valor mínimo da promoção.
  Future<PricingResult> resolverPrecos({
    required List<PricingItemRequest> items,
    int? pessoaId,
  }) async {
    final itensValidos = items
        .where((item) => item.produtoId > 0 && item.quantidade > 0)
        .toList(growable: false);
    if (itensValidos.isEmpty) return const PricingResult({});

    final payload = <String, dynamic>{
      'empresa_id': ApiConfig.empresaId,
      'pessoa_id': ?pessoaId,
      'items': itensValidos.map((item) => item.toJson()).toList(),
    };

    final uri = _api.buildUri('/api/v1/sales/prices');
    final response = await _api
        .post(uri, body: payload)
        .timeout(timeout, onTimeout: () => throw PricingTimeoutException());

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Resposta de /sales/prices inválida');
    }

    return PricingResult.fromJson(
      body,
      onUnparsed: (payloadBruto) => debugPrint(
        '[PricingService] resposta não reconhecida: ${jsonEncode(payloadBruto)}',
      ),
    );
  }
}

/// A consulta de preços excedeu o tempo limite.
class PricingTimeoutException implements Exception {
  @override
  String toString() => 'Tempo esgotado ao consultar os preços no servidor.';
}
