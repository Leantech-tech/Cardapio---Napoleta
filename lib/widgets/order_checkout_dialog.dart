import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/customer_address.dart';
import '../models/order_checkout_data.dart';
import '../models/payment_method.dart';
import '../providers/payment_method_provider.dart';
import '../services/customer_service.dart';
import '../theme/app_theme.dart';
import 'address_manager_dialog.dart';

class OrderCheckoutDialog extends StatefulWidget {
  final int initialStep;
  final TipoEntrega? tipoEntregaInicial;
  final VoidCallback? onBack;
  final bool isTotem;

  const OrderCheckoutDialog({
    super.key,
    this.initialStep = 1,
    this.tipoEntregaInicial,
    this.onBack,
    this.isTotem = false,
  });

  static Future<OrderCheckoutData?> show(
    BuildContext context, {
    int initialStep = 1,
    TipoEntrega? tipoEntregaInicial,
    VoidCallback? onBack,
    bool isTotem = false,
  }) async {
    return showDialog<OrderCheckoutData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderCheckoutDialog(
        initialStep: initialStep,
        tipoEntregaInicial: tipoEntregaInicial,
        onBack: onBack,
        isTotem: isTotem,
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
  final _trocoController = TextEditingController();

  PaymentMethod? _selectedPaymentMethod;
  bool _isLoadingPaymentMethods = false;
  bool? _precisaTroco;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _tipoEntrega = widget.tipoEntregaInicial;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPaymentMethods());
  }

  Future<void> _loadPaymentMethods() async {
    final provider = context.read<PaymentMethodProvider>();
    setState(() => _isLoadingPaymentMethods = true);
    try {
      await provider.loadPaymentMethods();
      if (!mounted) return;
      final methods = provider.methods;
      setState(() {
        _selectedPaymentMethod = methods.isNotEmpty ? methods.first : null;
        _isLoadingPaymentMethods = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPaymentMethods = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _trocoController.dispose();
    super.dispose();
  }

  void _selecionarTipo(TipoEntrega tipo) {
    setState(() {
      _tipoEntrega = tipo;
      _step = 2;
      if (tipo == TipoEntrega.retirada) {
        _precisaTroco = null;
        _trocoController.clear();
      }
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

  bool _isDinheiro(PaymentMethod? method) {
    if (method == null) return false;
    return method.descricao.toUpperCase().contains('DINHEIRO');
  }

  String _formatarValorMonetario(String texto) {
    final numeros = texto.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.isEmpty) return 'R\$ 0,00';

    // Evita overflow e mantém no máximo 2 decimais.
    final value = int.tryParse(numeros) ?? 0;
    final reais = (value / 100).floor();
    final centavos = value % 100;

    final reaisFormatados = reais.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
    final centavosFormatados = centavos.toString().padLeft(2, '0');
    return 'R\$ $reaisFormatados,$centavosFormatados';
  }

  double _parseValorMonetario(String texto) {
    final numeros = texto.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.isEmpty) return 0.0;
    final value = int.tryParse(numeros) ?? 0;
    return value / 100;
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
        _error = customer == null ? 'CPF incorreto' : null;
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

    if (_selectedPaymentMethod == null) {
      setState(() => _error = 'Selecione uma forma de pagamento.');
      return;
    }

    if (_tipoEntrega == TipoEntrega.entrega && _isDinheiro(_selectedPaymentMethod)) {
      if (_precisaTroco == null) {
        setState(() => _error = 'Informe se precisa de troco.');
        return;
      }
      if (_precisaTroco == true) {
        final valorTroco = _parseValorMonetario(_trocoController.text);
        if (valorTroco <= 0) {
          setState(() => _error = 'Informe o valor para o troco.');
          return;
        }
      }
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

      final valorTroco = _tipoEntrega == TipoEntrega.entrega &&
              _isDinheiro(_selectedPaymentMethod) &&
              _precisaTroco == true
          ? _parseValorMonetario(_trocoController.text)
          : 0.0;

      final data = OrderCheckoutData(
        tipoEntrega: _tipoEntrega!,
        nome: cadastrado.nome,
        cpf: cadastrado.cpfFormatado,
        rua: enderecoUsado?.rua ?? '',
        numero: enderecoUsado?.numero ?? '',
        bairro: enderecoUsado?.bairro ?? '',
        cidade: enderecoUsado?.cidade ?? '',
        estado: enderecoUsado?.estado ?? '',
        cep: enderecoUsado?.cep ?? '',
        paymentMethod: _selectedPaymentMethod!,
        customerId: cadastrado.id,
        addressId: enderecoUsado?.id,
        precisaTroco: _precisaTroco ?? false,
        valorTroco: valorTroco,
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
            } else if (_error != null && numeros.length < 11) {
              setState(() => _error = null);
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
        if (isEntrega && _isDinheiro(_selectedPaymentMethod)) ...[
          const SizedBox(height: 16),
          _buildTrocoSection(),
        ],
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
                    widget.isTotem ? 'Identificar cliente' : 'Confirmar pedido',
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

  Widget _buildTrocoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Troco?',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTrocoOption(
                label: 'Sim',
                selected: _precisaTroco == true,
                onTap: () => setState(() => _precisaTroco = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTrocoOption(
                label: 'Não',
                selected: _precisaTroco == false,
                onTap: () => setState(() {
                  _precisaTroco = false;
                  _trocoController.clear();
                }),
              ),
            ),
          ],
        ),
        if (_precisaTroco == true) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _trocoController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                final formatted = _formatarValorMonetario(newValue.text);
                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
            decoration: InputDecoration(
              labelText: 'Troco para quanto?',
              hintText: 'R\$ 0,00',
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
              ),
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
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrocoOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.brandPurple.withValues(alpha: 0.12)
              : AppTheme.inputBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.brandPurple : AppTheme.border(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppTheme.brandPurple : AppTheme.textSecondary(context),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.brandPurple : AppTheme.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
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
    if (_isLoadingPaymentMethods) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.inputBg(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Carregando formas de pagamento...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      );
    }

    final methods = context.watch<PaymentMethodProvider>().methods;

    if (methods.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.inputBg(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Nenhuma forma de pagamento disponível',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary(context),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.inputBg(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PaymentMethod>(
          value: _selectedPaymentMethod ?? methods.first,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary(context)),
          dropdownColor: AppTheme.surface(context),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textPrimary(context),
          ),
          items: methods.map((method) {
            return DropdownMenuItem<PaymentMethod>(
              value: method,
              child: Text(
                method.descricao,
                style: GoogleFonts.inter(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedPaymentMethod = value);
            }
          },
        ),
      ),
    );
  }
}
