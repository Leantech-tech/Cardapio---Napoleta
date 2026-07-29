import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer.dart';
import '../models/order_checkout_data.dart';
import '../services/cep_service.dart';
import '../services/customer_service.dart';
import '../theme/app_theme.dart';

class OrderCheckoutDialog extends StatefulWidget {
  final int initialStep;
  final TipoEntrega? tipoEntregaInicial;

  const OrderCheckoutDialog({
    super.key,
    this.initialStep = 1,
    this.tipoEntregaInicial,
  });

  static Future<OrderCheckoutData?> show(
    BuildContext context, {
    int initialStep = 1,
    TipoEntrega? tipoEntregaInicial,
  }) async {
    return showDialog<OrderCheckoutData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderCheckoutDialog(
        initialStep: initialStep,
        tipoEntregaInicial: tipoEntregaInicial,
      ),
    );
  }

  @override
  State<OrderCheckoutDialog> createState() => _OrderCheckoutDialogState();
}

class _OrderCheckoutDialogState extends State<OrderCheckoutDialog> {
  late int _step;
  bool _isLoading = false;
  String? _error;

  TipoEntrega? _tipoEntrega;

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cepController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _cepFocusNode = FocusNode();

  bool _isLoadingCep = false;

  FormaPagamento _formaPagamento = FormaPagamento.dinheiro;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _tipoEntrega = widget.tipoEntregaInicial;
    _cepFocusNode.addListener(_onCepFocusChange);
  }

  @override
  void dispose() {
    _cepFocusNode.removeListener(_onCepFocusChange);
    _cepFocusNode.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  void _onCepFocusChange() {
    if (!_cepFocusNode.hasFocus) {
      _buscarEnderecoPorCep(_cepController.text);
    }
  }

  void _selecionarTipo(TipoEntrega tipo) {
    setState(() {
      _tipoEntrega = tipo;
      _step = 2;
    });
  }

  String _formatarCpf(String texto) {
    final numeros = texto.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length > 11) return numeros.substring(0, 11);

    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < numeros.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(numeros[i]);
    }
    return buffer.toString();
  }

  String _formatarCep(String texto) {
    final numeros = texto.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length > 8) return numeros.substring(0, 8);

    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < numeros.length; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(numeros[i]);
    }
    return buffer.toString();
  }

  Future<void> _buscarEnderecoPorCep(String texto) async {
    final numeros = texto.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length != 8) return;

    setState(() => _isLoadingCep = true);

    final resultado = await CepService.buscar(numeros);

    if (!mounted) return;

    setState(() => _isLoadingCep = false);

    if (resultado == null) {
      setState(() => _error = 'CEP não encontrado.');
      return;
    }

    setState(() => _error = null);

    _enderecoController.text = resultado.enderecoCompleto;
  }

  Future<void> _confirmar() async {
    debugPrint('OrderCheckoutDialog: _confirmar iniciado');
    setState(() => _error = null);

    final cpfLimpo = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
    debugPrint('OrderCheckoutDialog: nome="${_nomeController.text}" cpf=$cpfLimpo endereco="${_enderecoController.text}"');

    if (_nomeController.text.trim().isEmpty) {
      setState(() => _error = 'O nome do cliente é obrigatório.');
      return;
    }

    if (cpfLimpo.isEmpty) {
      setState(() => _error = 'O CPF é obrigatório.');
      return;
    }

    if (cpfLimpo.length != 11) {
      setState(() => _error = 'Digite um CPF válido com 11 dígitos.');
      return;
    }

    if (_tipoEntrega == TipoEntrega.entrega &&
        _enderecoController.text.trim().isEmpty) {
      setState(() => _error = 'Informe o endereço completo para entrega.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customer = Customer(
        nome: _nomeController.text,
        cpf: _cpfController.text,
        endereco: _enderecoController.text,
      );

      debugPrint('OrderCheckoutDialog: chamando CustomerService para CPF $cpfLimpo');
      final cadastrado = await CustomerService().buscarOuCriar(customer);
      debugPrint('OrderCheckoutDialog: customer retornado - id=${cadastrado.id}, nome=${cadastrado.nome}');

      if (!mounted) return;

      final data = OrderCheckoutData(
        tipoEntrega: _tipoEntrega!,
        nome: cadastrado.nome,
        cpf: cadastrado.cpfFormatado,
        endereco: cadastrado.endereco,
        formaPagamento: _formaPagamento,
        customerId: cadastrado.id,
      );

      Navigator.of(context).pop(data);
    } catch (e) {
      debugPrint('OrderCheckoutDialog: erro ao confirmar: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao identificar cliente: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: _step == 1 ? _buildStep1() : _buildStep2(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Como deseja receber?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 20),
        _buildTipoCard(
          icon: Icons.storefront_outlined,
          title: 'Retirar na loja',
          description: 'Você busca o pedido no balcão.',
          tipo: TipoEntrega.retirada,
        ),
        const SizedBox(height: 12),
        _buildTipoCard(
          icon: Icons.delivery_dining_outlined,
          title: 'Entrega',
          description: 'O pedido será entregue no endereço informado.',
          tipo: TipoEntrega.entrega,
        ),
      ],
    );
  }

  Widget _buildTipoCard({
    required IconData icon,
    required String title,
    required String description,
    required TipoEntrega tipo,
  }) {
    return InkWell(
      onTap: () => _selecionarTipo(tipo),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.inputBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.brandPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.brandPurple, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final isEntrega = _tipoEntrega == TipoEntrega.entrega;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _step = 1),
              icon: const Icon(Icons.arrow_back),
              color: AppTheme.textPrimary(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Identificação do cliente',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isEntrega ? 'Entrega' : 'Retirar na loja',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.brandPurple,
          ),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _nomeController,
          label: 'Nome do cliente',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _cpfController,
          label: 'CPF *',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              final formatado = _formatarCpf(newValue.text);
              return TextEditingValue(
                text: formatado,
                selection: TextSelection.collapsed(offset: formatado.length),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _cepController,
          focusNode: _cepFocusNode,
          label: 'CEP',
          icon: Icons.location_searching_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              final formatado = _formatarCep(newValue.text);
              return TextEditingValue(
                text: formatado,
                selection: TextSelection.collapsed(offset: formatado.length),
              );
            }),
          ],
          suffixIcon: _isLoadingCep
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onSubmitted: _buscarEnderecoPorCep,
          onChanged: (value) {
            final numeros = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (numeros.length == 8 && !_isLoadingCep) {
              _buscarEnderecoPorCep(value);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _enderecoController,
          label: isEntrega ? 'Endereço completo *' : 'Endereço (opcional)',
          icon: Icons.location_on_outlined,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Text(
          'Forma de pagamento',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        _buildPaymentDropdown(),
        if (isEntrega) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.brandPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.brandPurple, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O entregador receberá o pagamento no momento da entrega.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.red[600],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Confirmar pedido',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppTheme.textPrimary(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppTheme.textSecondary(context),
        ),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary(context)),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: suffixIcon,
              )
            : null,
        filled: true,
        fillColor: AppTheme.inputBg(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPaymentDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.inputBg(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FormaPagamento>(
          value: _formaPagamento,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary(context)),
          dropdownColor: AppTheme.surface(context),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textPrimary(context),
          ),
          items: FormaPagamento.values.map((forma) {
            return DropdownMenuItem<FormaPagamento>(
              value: forma,
              child: Text(
                OrderCheckoutData.labelForFormaPagamento(forma),
                style: GoogleFonts.inter(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _formaPagamento = value);
            }
          },
        ),
      ),
    );
  }
}
