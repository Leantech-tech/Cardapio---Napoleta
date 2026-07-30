import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer.dart';
import '../models/customer_address.dart';
import '../models/order_checkout_data.dart';
import '../services/customer_service.dart';
import '../theme/app_theme.dart';
import 'address_manager_dialog.dart';

class OrderCheckoutDialog extends StatefulWidget {
  final int initialStep;
  final TipoEntrega? tipoEntregaInicial;
  final VoidCallback? onBack;

  const OrderCheckoutDialog({
    super.key,
    this.initialStep = 1,
    this.tipoEntregaInicial,
    this.onBack,
  });

  static Future<OrderCheckoutData?> show(
    BuildContext context, {
    int initialStep = 1,
    TipoEntrega? tipoEntregaInicial,
    VoidCallback? onBack,
  }) async {
    return showDialog<OrderCheckoutData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderCheckoutDialog(
        initialStep: initialStep,
        tipoEntregaInicial: tipoEntregaInicial,
        onBack: onBack,
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

  Customer? _customerLoaded;
  CustomerAddress? _selectedAddress;
  bool _isLoadingCustomer = false;

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();

  FormaPagamento _formaPagamento = FormaPagamento.dinheiro;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _tipoEntrega = widget.tipoEntregaInicial;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    super.dispose();
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

  Future<void> _buscarClientePorCpf() async {
    final cpfLimpo = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpfLimpo.length != 11) return;

    setState(() => _isLoadingCustomer = true);

    try {
      final customer = await CustomerService().buscarPorCpf(cpfLimpo);
      if (!mounted) return;

      setState(() {
        _customerLoaded = customer;
        _isLoadingCustomer = false;
      });

      if (customer != null) {
        if (_nomeController.text.trim().isEmpty) {
          _nomeController.text = customer.nome;
        }

        if (_tipoEntrega == TipoEntrega.entrega && customer.addresses.isNotEmpty) {
          _selecionarEndereco(customer.mainAddress!);
        }
      }
    } catch (e) {
      debugPrint('OrderCheckoutDialog: erro ao buscar cliente: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao buscar cliente: $e';
        _isLoadingCustomer = false;
      });
    }
  }

  void _selecionarEndereco(CustomerAddress? address) {
    setState(() => _selectedAddress = address);
  }

  Future<void> _abrirGerenciadorEnderecos() async {
    setState(() => _error = null);

    if (_cpfController.text.replaceAll(RegExp(r'[^0-9]'), '').length != 11) {
      setState(() => _error = 'Informe o CPF do cliente antes de cadastrar endereços.');
      return;
    }

    if (_nomeController.text.trim().isEmpty) {
      setState(() => _error = 'Informe o nome do cliente antes de cadastrar endereços.');
      return;
    }

    var customer = _customerLoaded;

    if (customer == null || customer.id == null) {
      setState(() => _isLoadingCustomer = true);
      try {
        customer = await CustomerService().criar(
          Customer(
            nome: _nomeController.text,
            cpf: _cpfController.text,
          ),
        );
        if (!mounted) return;
        setState(() {
          _customerLoaded = customer;
          _isLoadingCustomer = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = 'Erro ao criar cliente: $e';
          _isLoadingCustomer = false;
        });
        return;
      }
    }

    if (customer.id == null) return;

    final enderecosAtualizados = await AddressManagerDialog.show(
      context,
      pessoaId: customer.id!,
      existingAddresses: customer.addresses,
    );

    if (!mounted || enderecosAtualizados == null) return;

    setState(() {
      _customerLoaded = customer!.withAddresses(enderecosAtualizados);
      if (enderecosAtualizados.isNotEmpty) {
        _selectedAddress = enderecosAtualizados.last;
      }
    });
  }

  Widget _buildAddressDropdown() {
    final addresses = _customerLoaded?.addresses ?? [];

    if (addresses.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.inputBg(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Nenhum endereço cadastrado',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildAddAddressButton(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.inputBg(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CustomerAddress>(
                value: _selectedAddress,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary(context)),
                dropdownColor: AppTheme.surface(context),
                hint: Text(
                  'Selecione um endereço',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textPrimary(context),
                ),
                items: addresses.map((address) {
                  return DropdownMenuItem<CustomerAddress>(
                    value: address,
                    child: Text(
                      address.endereco,
                      style: GoogleFonts.inter(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _selecionarEndereco,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildAddAddressButton(),
      ],
    );
  }

  Widget _buildAddAddressButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.brandPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: _isLoadingCustomer ? null : _abrirGerenciadorEnderecos,
        icon: _isLoadingCustomer
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
        tooltip: 'Cadastrar endereços',
      ),
    );
  }

  Future<void> _confirmar() async {
    debugPrint('OrderCheckoutDialog: _confirmar iniciado');
    setState(() => _error = null);

    final cpfLimpo = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
    debugPrint('OrderCheckoutDialog: nome="${_nomeController.text}" cpf=$cpfLimpo');

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

    if (_tipoEntrega == TipoEntrega.entrega && _selectedAddress == null) {
      setState(() => _error = 'Selecione ou cadastre um endereço para entrega.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customer = Customer(
        nome: _nomeController.text,
        cpf: _cpfController.text,
      );

      final tipoEndereco = _tipoEntrega == TipoEntrega.retirada ? 'retirada' : 'entrega';
      debugPrint('OrderCheckoutDialog: chamando CustomerService para CPF $cpfLimpo (tipo=$tipoEndereco)');

      Customer cadastrado;
      CustomerAddress? enderecoUsado;
      if (_tipoEntrega == TipoEntrega.entrega) {
        cadastrado = await CustomerService().salvarClienteEEndereco(
          customer,
          _selectedAddress!,
          tipoEndereco: tipoEndereco,
        );
        enderecoUsado = cadastrado.addresses.isNotEmpty
            ? cadastrado.addresses.lastWhere(
                (a) => a.isSameAddress(_selectedAddress!),
                orElse: () => cadastrado.mainAddress!,
              )
            : null;
      } else {
        cadastrado = await CustomerService().buscarOuCriar(
          customer,
          tipoEndereco: tipoEndereco,
        );
      }
      debugPrint('OrderCheckoutDialog: customer retornado - id=${cadastrado.id}, nome=${cadastrado.nome}, enderecos=${cadastrado.addresses.length}');

      if (!mounted) return;

      final data = OrderCheckoutData(
        tipoEntrega: _tipoEntrega!,
        nome: cadastrado.nome,
        cpf: cadastrado.cpfFormatado,
        rua: enderecoUsado?.rua ?? '',
        bairro: enderecoUsado?.bairro ?? '',
        cidade: enderecoUsado?.cidade ?? '',
        estado: enderecoUsado?.estado ?? '',
        cep: enderecoUsado?.cep ?? '',
        formaPagamento: _formaPagamento,
        customerId: cadastrado.id,
        addressId: enderecoUsado?.id,
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isSmallPhone = screenWidth < 360;
    final horizontalPadding = isSmallPhone ? 16.0 : 20.0;
    final maxWidth = screenWidth < 420 ? screenWidth * 0.92 : 420.0;
    final maxHeight = screenHeight * 0.92;

    return Dialog(
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallPhone ? 12 : 20,
        vertical: isSmallPhone ? 16 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: SingleChildScrollView(
            child: _step == 1 ? _buildStep1() : _buildStep2(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    final onBack = widget.onBack;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack ?? () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              color: AppTheme.textPrimary(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Como deseja receber?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  setState(() => _step = 1);
                }
              },
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
          suffixIcon: _isLoadingCustomer
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onSubmitted: (_) => _buscarClientePorCpf(),
          onChanged: (value) {
            final numeros = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (numeros.length == 11 && !_isLoadingCustomer) {
              _buscarClientePorCpf();
            }
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _nomeController,
          label: 'Nome do cliente',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        if (isEntrega) ...[
          const SizedBox(height: 20),
          Text(
            'Endereço de entrega',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          _buildAddressDropdown(),
        ],
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
