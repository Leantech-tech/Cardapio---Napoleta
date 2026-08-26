import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_tracking_status.dart';
import '../services/order_tracking_service.dart';
import '../theme/app_theme.dart';

/// Popup de acompanhamento de pedido no modo Link.
///
/// Exibe uma linha do tempo com os status do pedido e faz polling no backend
/// para refletir mudanças feitas pelo app Minha Loja.
class OrderTrackingDialog extends StatefulWidget {
  final int orderId;
  final bool? initialIsRetirada;

  const OrderTrackingDialog({
    super.key,
    required this.orderId,
    this.initialIsRetirada,
  });

  static Future<void> show(
    BuildContext context, {
    required int orderId,
    bool? isRetirada,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderTrackingDialog(
        orderId: orderId,
        initialIsRetirada: isRetirada,
      ),
    );
  }

  @override
  State<OrderTrackingDialog> createState() => _OrderTrackingDialogState();
}

class _OrderTrackingDialogState extends State<OrderTrackingDialog> {
  final OrderTrackingService _service = OrderTrackingService();
  Timer? _timer;

  OrderStatus _currentStatus = OrderStatus.aguardandoConfirmacao;
  DateTime? _lastUpdatedAt;
  bool _isLoading = false;
  bool _isRetirada = false;

  static const Duration _pollingInterval = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(_pollingInterval, (_) => _fetchStatus());
  }

  Future<void> _fetchStatus() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final order = await _service.fetchOrder(widget.orderId);
    final isRetirada = widget.initialIsRetirada ?? _service.extractIsRetirada(order);
    var newStatus = _service.extractStatus(order);

    if (isRetirada && newStatus == OrderStatus.entregue) {
      newStatus = OrderStatus.prontoParaRetirada;
    }

    final updatedAt = _service.extractUpdatedAt(order);

    if (mounted) {
      setState(() {
        _currentStatus = newStatus;
        _isRetirada = isRetirada;
        _lastUpdatedAt = updatedAt;
        _isLoading = false;
      });
    }

    if (OrderTrackingConfig.isTerminal(newStatus)) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxDialogWidth = screenWidth < 680 ? screenWidth * 0.95 : 680.0;

    return Dialog(
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxDialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delivery_dining_outlined,
                      color: AppTheme.brandPurple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalhes do envio',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pedido nº ${widget.orderId}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Status badge
              _buildStatusBadge(context),
              const SizedBox(height: 20),
              // Timeline
              _buildTimeline(context),
              const SizedBox(height: 20),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_lastUpdatedAt != null)
                    Expanded(
                      child: Text(
                        'Atualizado às ${_formatTime(_lastUpdatedAt!)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (_isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Fechar',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final color = _statusColor(_currentStatus);
    final label = _statusLabel(_currentStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _statusIcon(_currentStatus),
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final steps = OrderTrackingConfig.stepsFor(isRetirada: _isRetirada);
    final currentIndex = steps.indexWhere((s) => s.status == _currentStatus);

    return SizedBox(
      height: 132,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(steps.length, (index) {
            final step = steps[index];
            final bool isCompleted = currentIndex >= 0 &&
                index <= currentIndex &&
                _currentStatus != OrderStatus.cancelado;
            final bool isCurrent = step.status == _currentStatus;
            final bool isCancelled = _currentStatus == OrderStatus.cancelado;

            return _TimelineStep(
              step: step,
              isFirst: index == 0,
              isCompleted: isCompleted || (isCancelled && index == 0),
              isCurrent: isCurrent,
              isCancelled: isCancelled,
              isLast: index == steps.length - 1,
            );
          }),
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.aguardandoConfirmacao:
        return const Color(0xFFF59E0B); // amber
      case OrderStatus.confirmado:
        return const Color(0xFF3B82F6); // blue
      case OrderStatus.emTransito:
        return const Color(0xFF00A650); // green
      case OrderStatus.entregue:
        return const Color(0xFF00A650); // green
      case OrderStatus.prontoParaRetirada:
        return const Color(0xFF00A650); // green
      case OrderStatus.cancelado:
        return const Color(0xFFE31E24); // red
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.aguardandoConfirmacao:
        return Icons.hourglass_top_outlined;
      case OrderStatus.confirmado:
        return Icons.check_circle_outline;
      case OrderStatus.emTransito:
        return Icons.moped_outlined;
      case OrderStatus.entregue:
        return Icons.done_all_outlined;
      case OrderStatus.prontoParaRetirada:
        return Icons.storefront_outlined;
      case OrderStatus.cancelado:
        return Icons.cancel_outlined;
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.aguardandoConfirmacao:
        return 'Aguardando confirmação';
      case OrderStatus.confirmado:
        return 'Confirmado';
      case OrderStatus.emTransito:
        return 'Em rota de entrega';
      case OrderStatus.entregue:
        return 'Pedido entregue';
      case OrderStatus.prontoParaRetirada:
        return 'Pronto para retirada';
      case OrderStatus.cancelado:
        return 'Pedido cancelado';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _TimelineStep extends StatelessWidget {
  final OrderTrackingStep step;
  final bool isFirst;
  final bool isCompleted;
  final bool isCurrent;
  final bool isCancelled;
  final bool isLast;

  const _TimelineStep({
    required this.step,
    required this.isFirst,
    required this.isCompleted,
    required this.isCurrent,
    required this.isCancelled,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isCancelled
        ? const Color(0xFFE31E24)
        : isCompleted
            ? const Color(0xFF00A650)
            : AppTheme.brandPurple;
    final Color inactiveColor = AppTheme.border(context);
    final Color dotColor = isCurrent || isCompleted ? activeColor : inactiveColor;
    final Color lineColor = isCompleted ? activeColor : inactiveColor;

    final bool showCancelled = isCancelled && isFirst;
    final String label = showCancelled ? 'Cancelado' : step.label;
    final String description = showCancelled
        ? 'O pedido foi cancelado pela loja.'
        : step.description;

    return SizedBox(
      width: 124,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isFirst)
                Expanded(
                  child: Container(
                    height: 2,
                    color: lineColor,
                  ),
                ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isCurrent || isCompleted)
                      ? activeColor.withValues(alpha: 0.15)
                      : AppTheme.inputBg(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: dotColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted && !isCurrent
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: activeColor,
                        )
                      : (showCancelled
                          ? Icon(
                              Icons.cancel_outlined,
                              size: 16,
                              color: activeColor,
                            )
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            )),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: lineColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isCurrent || isCompleted
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isCurrent || isCompleted
                    ? AppTheme.textPrimary(context)
                    : AppTheme.textSecondary(context),
              ),
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
