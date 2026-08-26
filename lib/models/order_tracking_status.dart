/// Status possíveis de um pedido delivery no acompanhamento.
enum OrderStatus {
  aguardandoConfirmacao,
  confirmado,
  emTransito,
  entregue,
  cancelado,
}

/// Representação de um passo da timeline de acompanhamento.
class OrderTrackingStep {
  final OrderStatus status;
  final String label;
  final String description;
  final DateTime? timestamp;

  const OrderTrackingStep({
    required this.status,
    required this.label,
    required this.description,
    this.timestamp,
  });
}

/// Configuração fixa dos passos exibidos no popup.
class OrderTrackingConfig {
  static const List<OrderTrackingStep> steps = [
    OrderTrackingStep(
      status: OrderStatus.aguardandoConfirmacao,
      label: 'Aguardando confirmação',
      description: 'Seu pedido foi recebido e aguarda aprovação da loja.',
    ),
    OrderTrackingStep(
      status: OrderStatus.confirmado,
      label: 'Confirmado',
      description: 'O pedido foi confirmado e em breve sai para entrega.',
    ),
    OrderTrackingStep(
      status: OrderStatus.emTransito,
      label: 'Em rota de entrega',
      description: 'Seu pedido saiu para entrega.',
    ),
    OrderTrackingStep(
      status: OrderStatus.entregue,
      label: 'Pedido entregue',
      description: 'Pedido entregue. Bom apetite!',
    ),
  ];

  /// Mapeia o valor textual vindo do backend para o enum interno.
  ///
  /// Aceita os formatos usados pelo cardápio digital e pelo app Minha Loja,
  /// ignorando caixa, espaços extras, hífens ou underscores.
  static OrderStatus fromString(String? value) {
    final normalized = value
        ?.toUpperCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    switch (normalized) {
      case 'AGUARDANDO_CONFIRMACAO':
      case 'AGUARDANDO_CONFIRMAÇÃO':
      case 'PENDENTE':
      case 'RECEBIDO':
      case 'NOVO':
        return OrderStatus.aguardandoConfirmacao;
      case 'CONFIRMADO':
      case 'CONFIRMACAO':
      case 'CONFIRMAÇÃO':
      case 'ACEITO':
        return OrderStatus.confirmado;
      case 'EM_PREPARO':
      case 'PREPARO':
      case 'PREPARANDO':
        return OrderStatus.confirmado;
      case 'EM_TRANSITO':
      case 'EM_TRÂNSITO':
      case 'SAIU_PARA_ENTREGA':
      case 'SAIU_PARA_ENTREGA_':
      case 'ROTA':
      case 'DESPACHADO':
      case 'A_CAMINHO':
        return OrderStatus.emTransito;
      case 'ENTREGUE':
      case 'CONCLUIDO':
      case 'CONCLUÍDO':
      case 'FINALIZADO':
      case 'COMPLETO':
        return OrderStatus.entregue;
      case 'CANCELADO':
      case 'CANCELADA':
      case 'RECUSADO':
        return OrderStatus.cancelado;
      default:
        return OrderStatus.aguardandoConfirmacao;
    }
  }

  /// Indica se o status é terminal (não precisa mais de polling).
  static bool isTerminal(OrderStatus status) {
    return status == OrderStatus.entregue || status == OrderStatus.cancelado;
  }
}
