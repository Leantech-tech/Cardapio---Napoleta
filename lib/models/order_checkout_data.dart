enum TipoEntrega { retirada, entrega }

enum FormaPagamento { dinheiro, pix, credito, debito }

class OrderCheckoutData {
  final TipoEntrega tipoEntrega;
  final String nome;
  final String cpf;
  final String endereco;
  final FormaPagamento formaPagamento;
  final int? customerId;

  const OrderCheckoutData({
    required this.tipoEntrega,
    required this.nome,
    required this.cpf,
    required this.endereco,
    required this.formaPagamento,
    this.customerId,
  });

  bool get isEntrega => tipoEntrega == TipoEntrega.entrega;
  bool get isRetirada => tipoEntrega == TipoEntrega.retirada;

  String get tipoEntregaLabel => isEntrega ? 'Entrega' : 'Retirar na loja';

  String get formaPagamentoLabel => labelForFormaPagamento(formaPagamento);

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
