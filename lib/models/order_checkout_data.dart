import 'payment_method.dart';

enum TipoEntrega { retirada, entrega }

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
  final PaymentMethod paymentMethod;
  final int? customerId;
  final int? addressId;
  final bool precisaTroco;
  final double valorTroco;

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
    required this.paymentMethod,
    this.customerId,
    this.addressId,
    this.precisaTroco = false,
    this.valorTroco = 0.0,
  });

  bool get isEntrega => tipoEntrega == TipoEntrega.entrega;
  bool get isRetirada => tipoEntrega == TipoEntrega.retirada;

  String get tipoEntregaLabel => isEntrega ? 'Entrega' : 'Retirar na loja';

  String get formaPagamentoLabel {
    final buffer = StringBuffer(paymentMethod.descricao);
    if (precisaTroco && valorTroco > 0) {
      buffer.write(
        ' (troco para R\$ ${valorTroco.toStringAsFixed(2).replaceAll('.', ',')})',
      );
    }
    return buffer.toString();
  }

  /// Cria uma cópia dos dados trocando apenas a forma de pagamento.
  OrderCheckoutData copyWithPaymentMethod(PaymentMethod method) {
    return OrderCheckoutData(
      tipoEntrega: tipoEntrega,
      nome: nome,
      cpf: cpf,
      rua: rua,
      numero: numero,
      bairro: bairro,
      cidade: cidade,
      estado: estado,
      cep: cep,
      paymentMethod: method,
      customerId: customerId,
      addressId: addressId,
      precisaTroco: precisaTroco,
      valorTroco: valorTroco,
    );
  }

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
}
