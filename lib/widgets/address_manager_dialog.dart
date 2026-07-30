import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer_address.dart';
import '../services/customer_service.dart';
import '../services/cep_service.dart';
import '../theme/app_theme.dart';

class AddressManagerDialog extends StatefulWidget {
  final int pessoaId;
  final List<CustomerAddress> existingAddresses;

  const AddressManagerDialog({
    super.key,
    required this.pessoaId,
    this.existingAddresses = const [],
  });

  static Future<List<CustomerAddress>?> show(
    BuildContext context, {
    required int pessoaId,
    List<CustomerAddress> existingAddresses = const [],
  }) async {
    return showDialog<List<CustomerAddress>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddressManagerDialog(
        pessoaId: pessoaId,
        existingAddresses: existingAddresses,
      ),
    );
  }

  @override
  State<AddressManagerDialog> createState() => _AddressManagerDialogState();
}

class _AddressManagerDialogState extends State<AddressManagerDialog> {
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _cepFocusNode = FocusNode();

  bool _isLoadingCep = false;
  bool _isSaving = false;
  String? _error;

  final List<CustomerAddress> _pendingAddresses = [];
  final List<CustomerAddress> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    _cepFocusNode.addListener(_onCepFocusChange);
    _savedAddresses.addAll(widget.existingAddresses);
  }

  @override
  void dispose() {
    _cepFocusNode.removeListener(_onCepFocusChange);
    _cepFocusNode.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  void _onCepFocusChange() {
    if (!_cepFocusNode.hasFocus) {
      _buscarEnderecoPorCep(_cepController.text);
    }
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

    final campos = resultado.camposSeparados;
    _ruaController.text = campos['rua'] ?? '';
    _bairroController.text = campos['bairro'] ?? '';
    _cidadeController.text = campos['cidade'] ?? '';
    _estadoController.text = campos['estado'] ?? '';
    _cepController.text = campos['cep'] ?? '';
  }

  void _adicionarEnderecoLocal() {
    setState(() => _error = null);

    if (_cepController.text.replaceAll(RegExp(r'[^0-9]'), '').length != 8) {
      setState(() => _error = 'Informe um CEP válido.');
      return;
    }
    if (_ruaController.text.trim().isEmpty ||
        _bairroController.text.trim().isEmpty ||
        _cidadeController.text.trim().isEmpty ||
        _estadoController.text.trim().isEmpty) {
      setState(() => _error = 'Preencha rua, bairro, cidade e estado.');
      return;
    }

    final address = CustomerAddress(
      rua: _ruaController.text,
      bairro: _bairroController.text,
      cidade: _cidadeController.text,
      estado: _estadoController.text,
      cep: _cepController.text,
      principal: _savedAddresses.isEmpty && _pendingAddresses.isEmpty,
    );

    setState(() {
      _pendingAddresses.add(address);
      _cepController.clear();
      _ruaController.clear();
      _bairroController.clear();
      _cidadeController.clear();
      _estadoController.clear();
    });
  }

  void _removerEnderecoLocal(int index) {
    setState(() => _pendingAddresses.removeAt(index));
  }

  Future<void> _salvar() async {
    if (_pendingAddresses.isEmpty) {
      Navigator.of(context).pop(_savedAddresses);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final service = CustomerService();
      final List<CustomerAddress> novos = [];

      for (final address in _pendingAddresses) {
        final saved = await service.criarEndereco(widget.pessoaId, address);
        novos.add(saved);
      }

      if (!mounted) return;
      Navigator.of(context).pop([..._savedAddresses, ...novos]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao salvar endereços: $e';
        _isSaving = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
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

  Widget _buildAddressTile(CustomerAddress address, {VoidCallback? onRemove}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.inputBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              address.endereco,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textPrimary(context),
                height: 1.4,
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isSmallPhone = screenWidth < 360;
    final maxWidth = screenWidth < 420 ? screenWidth * 0.94 : 420.0;
    final maxHeight = screenHeight * 0.92;

    return Dialog(
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallPhone ? 10 : 20,
        vertical: isSmallPhone ? 14 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.all(isSmallPhone ? 16 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: AppTheme.textPrimary(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cadastrar endereços',
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
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildTextField(
                              controller: _estadoController,
                              label: 'Estado',
                              icon: Icons.flag_outlined,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                TextInputFormatter.withFunction((oldValue, newValue) {
                                  final texto = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
                                  if (texto.length > 2) return oldValue;
                                  return TextEditingValue(
                                    text: texto,
                                    selection: TextSelection.collapsed(offset: texto.length),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _cidadeController,
                              label: 'Cidade',
                              icon: Icons.location_city_outlined,
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _bairroController,
                        label: 'Bairro',
                        icon: Icons.map_outlined,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _ruaController,
                        label: 'Rua',
                        icon: Icons.location_on_outlined,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _adicionarEnderecoLocal,
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(
                            'Adicionar endereço',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.brandPurple,
                            side: BorderSide(color: AppTheme.brandPurple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_pendingAddresses.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Endereços a salvar',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._pendingAddresses.asMap().entries.map((entry) {
                          return _buildAddressTile(
                            entry.value,
                            onRemove: () => _removerEnderecoLocal(entry.key),
                          );
                        }),
                      ],
                      if (_savedAddresses.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Endereços já cadastrados',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._savedAddresses.map(_buildAddressTile),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _pendingAddresses.isEmpty ? 'Fechar' : 'Salvar endereços',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
