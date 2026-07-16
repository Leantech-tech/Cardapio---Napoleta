import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/barcode_scanner_service.dart';

/// Widget que envolve o app e escuta leituras de scanner de código de barras
/// em modo teclado. Funciona apenas na web, pois em dispositivos móveis usamos
/// a câmera do mobile_scanner.
///
/// Usa [HardwareKeyboard] para capturar os eventos globalmente, sem precisar
/// de um [FocusNode], evitando conflitos de foco na interface.
class BarcodeKeyboardListener extends StatefulWidget {
  final Widget child;

  const BarcodeKeyboardListener({super.key, required this.child});

  @override
  State<BarcodeKeyboardListener> createState() =>
      _BarcodeKeyboardListenerState();
}

class _BarcodeKeyboardListenerState extends State<BarcodeKeyboardListener> {
  final _service = BarcodeScannerService();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        _service.submit();
      } else {
        final character = event.character;
        if (character != null && character.isNotEmpty) {
          _service.handleKey(character);
        }
      }
    }

    // Retorna false para não interceptar eventos de campos de texto.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
