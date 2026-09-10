/// Origem do preço resolvido pelo servidor (Minha Loja).
enum PrecoOrigem {
  padrao,
  tabela,
  promocao;

  /// Nome usado nos payloads e no snapshot do pedido.
  String get wire => switch (this) {
    PrecoOrigem.padrao => 'PADRAO',
    PrecoOrigem.tabela => 'TABELA',
    PrecoOrigem.promocao => 'PROMOCAO',
  };

  static PrecoOrigem parse(Object? valor) {
    final texto = valor?.toString().trim().toUpperCase() ?? '';
    return switch (texto) {
      'TABELA' => PrecoOrigem.tabela,
      'PROMOCAO' || 'PROMOÇÃO' => PrecoOrigem.promocao,
      _ => PrecoOrigem.padrao,
    };
  }
}

/// Preço resolvido para um produto, retornado pelo servidor.
class PrecoResolvido {
  final int produtoId;
  final double valor;
  final PrecoOrigem origem;

  /// Preço padrão (produto.vr_venda) de referência, quando informado.
  final double? precoPadrao;

  /// Tabela de preço aplicada (quando origem == TABELA).
  final int? tabelaPrecoId;
  final String? tabelaNome;

  /// Promoção aplicada (quando origem == PROMOCAO).
  final int? promocaoId;
  final String? promocaoNome;
  final String? promocaoTipo;
  final int? promocaoQtdMinima;

  const PrecoResolvido({
    required this.produtoId,
    required this.valor,
    required this.origem,
    this.precoPadrao,
    this.tabelaPrecoId,
    this.tabelaNome,
    this.promocaoId,
    this.promocaoNome,
    this.promocaoTipo,
    this.promocaoQtdMinima,
  });
}

/// Resultado da resolução de preços em lote (`POST /api/v1/sales/prices`).
class PricingResult {
  final Map<int, PrecoResolvido> precos;

  /// Cabeçalho da tabela de preço aplicada. O servidor envia esses dados na
  /// raiz da resposta (`tabela_id`, `nome`, `revisao`, `ativa`).
  final int? tabelaPrecoId;
  final String? tabelaNome;
  final int? tabelaRevisao;
  final bool tabelaAtiva;

  const PricingResult(
    this.precos, {
    this.tabelaPrecoId,
    this.tabelaNome,
    this.tabelaRevisao,
    this.tabelaAtiva = false,
  });

  PrecoResolvido? operator [](int produtoId) => precos[produtoId];

  /// Preços de origem TABELA por produto (para aplicar no cardápio/menu).
  Map<int, double> get precosDeTabela => {
    for (final entry in precos.entries)
      if (entry.value.origem == PrecoOrigem.tabela)
        entry.key: entry.value.valor,
  };

  /// Parser tolerante da resposta do servidor. Aceita variações comuns de
  /// formato; quando nada é reconhecido, registra o payload via [onUnparsed].
  factory PricingResult.fromJson(
    Map<String, dynamic> body, {
    void Function(Map<String, dynamic> payload)? onUnparsed,
  }) {
    final data = body['data'];
    final root = data is Map<String, dynamic> ? data : body;

    final lista = _primeiraLista(root, [
      'items',
      'itens',
      'precos',
      'prices',
      'produtos',
      'products',
    ]);

    final precos = <int, PrecoResolvido>{};
    if (lista != null) {
      for (final raw in lista) {
        if (raw is! Map<String, dynamic>) continue;
        final produtoId = _intDe(raw, ['produto_id', 'produtoId', 'id']);
        final valor = _doubleDe(raw, [
          'valor',
          'preco',
          'valor_resolvido',
          'valor_unitario',
          'valor_final',
          'price',
        ]);
        if (produtoId == null || valor == null) continue;

        final promocao = raw['promocao'];
        final promocaoMap = promocao is Map<String, dynamic> ? promocao : null;

        precos[produtoId] = PrecoResolvido(
          produtoId: produtoId,
          valor: valor,
          origem: PrecoOrigem.parse(
            _valorDe(raw, [
              'origem',
              'preco_origem',
              'origem_preco',
              'price_origin',
            ]),
          ),
          precoPadrao: _doubleDe(raw, [
            'preco_padrao',
            'vr_venda',
            'valor_padrao',
            'precoPadrao',
          ]),
          tabelaPrecoId:
              _intDe(raw, ['tabela_preco_id', 'tabelaPrecoId']) ??
              _intDe(
                raw['tabela'] is Map<String, dynamic>
                    ? raw['tabela'] as Map<String, dynamic>
                    : const {},
                ['id'],
              ),
          tabelaNome:
              _textoDe(raw, ['tabela_nome', 'tabelaPrecoNome']) ??
              _textoDe(
                raw['tabela'] is Map<String, dynamic>
                    ? raw['tabela'] as Map<String, dynamic>
                    : const {},
                ['nome'],
              ),
          promocaoId:
              _intDe(raw, ['promocao_id', 'promocaoId']) ??
              _intDe(promocaoMap ?? const {}, ['id']),
          promocaoNome:
              _textoDe(raw, ['promocao_nome']) ??
              _textoDe(promocaoMap ?? const {}, ['nome']),
          promocaoTipo:
              _textoDe(raw, ['promocao_tipo']) ??
              _textoDe(promocaoMap ?? const {}, ['tipo']),
          promocaoQtdMinima:
              _intDe(raw, ['promocao_qtd_minima']) ??
              _intDe(promocaoMap ?? const {}, [
                'quantidade_minima',
                'qtd_minima',
              ]),
        );
      }
    }

    if (precos.isEmpty) {
      onUnparsed?.call(root);
    }

    // Cabeçalho da tabela na raiz da resposta; se ausente, tenta o id por item.
    final tabelaMap = root['tabela'] is Map<String, dynamic>
        ? root['tabela'] as Map<String, dynamic>
        : const <String, dynamic>{};
    var tabelaId =
        _intDe(root, ['tabela_id', 'tabelaPrecoId']) ??
        _intDe(tabelaMap, ['id']);
    tabelaId ??= () {
      for (final preco in precos.values) {
        if (preco.origem == PrecoOrigem.tabela && preco.tabelaPrecoId != null) {
          return preco.tabelaPrecoId;
        }
      }
      return null;
    }();
    final tabelaNome =
        _textoDe(root, ['tabela_nome']) ??
        _textoDe(tabelaMap, ['nome']) ??
        (tabelaId != null ? _textoDe(root, ['nome']) : null);
    final ativa =
        root['ativa'] as bool? ??
        root['tabela_ativa'] as bool? ??
        (tabelaId != null);

    // O contrato real de /sales/prices devolve os preços-base em `prices` e
    // as promoções aplicáveis em uma lista separada. A promoção só substitui
    // a base quando for estritamente menor, como no PDV do Minha Loja.
    final listaPromocoes = _primeiraLista(root, ['promotions', 'promocoes']);
    if (listaPromocoes != null) {
      for (final raw in listaPromocoes) {
        if (raw is! Map<String, dynamic>) continue;
        final produtoId = _intDe(raw, ['produto_id', 'produtoId']);
        final valorPromocional = _doubleDe(raw, [
          'valor_promocional',
          'valorPromocional',
          'valor',
          'preco',
        ]);
        if (produtoId == null || valorPromocional == null) continue;

        final base = precos[produtoId];
        if (base == null || valorPromocional + 0.0001 >= base.valor) continue;

        precos[produtoId] = PrecoResolvido(
          produtoId: produtoId,
          valor: valorPromocional,
          origem: PrecoOrigem.promocao,
          precoPadrao: base.precoPadrao,
          tabelaPrecoId:
              base.tabelaPrecoId ??
              (base.origem == PrecoOrigem.tabela ? tabelaId : null),
          tabelaNome:
              base.tabelaNome ??
              (base.origem == PrecoOrigem.tabela ? tabelaNome : null),
          promocaoId: _intDe(raw, ['id', 'promocao_id', 'promocaoId']),
          promocaoNome: _textoDe(raw, ['nome', 'promocao_nome']),
          promocaoTipo: _textoDe(raw, ['tipo', 'promocao_tipo']),
          promocaoQtdMinima: _intDe(raw, [
            'quantidade_minima',
            'qtd_minima',
            'promocao_qtd_minima',
          ]),
        );
      }
    }

    return PricingResult(
      precos,
      tabelaPrecoId: tabelaId,
      tabelaNome: tabelaNome,
      tabelaRevisao: _intDe(root, ['revisao', 'tabela_revisao']),
      tabelaAtiva: ativa,
    );
  }

  static List<dynamic>? _primeiraLista(
    Map<String, dynamic> map,
    List<String> chaves,
  ) {
    for (final chave in chaves) {
      final valor = map[chave];
      if (valor is List) return valor;
    }
    return null;
  }

  static Object? _valorDe(Map<String, dynamic> map, List<String> chaves) {
    for (final chave in chaves) {
      final valor = map[chave];
      if (valor != null) return valor;
    }
    return null;
  }

  static int? _intDe(Map<String, dynamic> map, List<String> chaves) {
    final valor = _valorDe(map, chaves);
    if (valor is num) return valor.toInt();
    if (valor is String) return int.tryParse(valor);
    return null;
  }

  static double? _doubleDe(Map<String, dynamic> map, List<String> chaves) {
    final valor = _valorDe(map, chaves);
    if (valor is num) return valor.toDouble();
    if (valor is String) return double.tryParse(valor.replaceAll(',', '.'));
    return null;
  }

  static String? _textoDe(Map<String, dynamic> map, List<String> chaves) {
    final valor = _valorDe(map, chaves);
    if (valor == null) return null;
    final texto = valor.toString().trim();
    return texto.isEmpty ? null : texto;
  }
}
