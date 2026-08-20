enum TipoEntrega { retirada, entrega }

enum FormaPagamento { dinheiro, pix, credito, debito }

class OrderCheckoutData {
  final TipoEntrega tipoEntrega;
  final String nome;
  final String cpf;
  final String rua;
  final String numero;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;
  final FormaPagamento formaPagamento;
  final int? customerId;
  final int? addressId;

  const OrderCheckoutData({
    required this.tipoEntrega,
    required this.nome,
    required this.cpf,
    this.rua = '',
    this.numero = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.cep = '',
    required this.formaPagamento,
    this.customerId,
    this.addressId,
  });

  bool get isEntrega => tipoEntrega == TipoEntrega.entrega;
  bool get isRetirada => tipoEntrega == TipoEntrega.retirada;

  String get tipoEntregaLabel => isEntrega ? 'Entrega' : 'Retirar na loja';

  String get formaPagamentoLabel => labelForFormaPagamento(formaPagamento);

  /// Endereco completo formatado a partir dos campos separados.
  String get endereco {
    final partes = <String>[
      '${rua.trim()}${numero.trim().isNotEmpty ? ', ${numero.trim()}' : ''}',
      bairro.trim(),
      if (cidade.trim().isNotEmpty && estado.trim().isNotEmpty)
        '${cidade.trim()} - ${estado.trim().toUpperCase()}'
      else if (cidade.trim().isNotEmpty)
        cidade.trim()
      else if (estado.trim().isNotEmpty)
        estado.trim().toUpperCase(),
      cep.trim(),
    ].where((p) => p.isNotEmpty);

    return partes.join(', ');
  }

  static String labelForFormaPagamento(FormaPagamento forma) {
    switch (forma) {
      case FormaPagamento.dinheiro:
        return 'Dinheiro';
      case FormaPagamento.pix:
        return 'Pix';
      case FormaPagamento.credito:
        return 'Crédito';
      case FormaPagamento.debito:
        return 'Débito';
    }
  }
}
