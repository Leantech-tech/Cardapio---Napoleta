import 'dart:async';
import 'dart:math' as math;

/// Serviço que detecta leituras de scanners de código de barras em modo teclado.
///
/// Scanners emulam digitação rápida de caracteres seguida de Enter. O serviço
/// escuta eventos de teclado, agrupa caracteres digitados em curto espaço de
/// tempo e emite o código completo quando detecta o Enter.
class BarcodeScannerService {
  static final BarcodeScannerService _instance = BarcodeScannerService._internal();
  factory BarcodeScannerService() => _instance;
  BarcodeScannerService._internal();

  final _controller = StreamController<String>.broadcast();
  Stream<String> get onBarcode => _controller.stream;

  String _buffer = '';
  DateTime? _lastKeyTime;

  /// Tempo máximo entre caracteres para considerar parte do mesmo código.
  static const _maxGap = Duration(milliseconds: 100);

  /// Comprimento mínimo de um código de barras válido.
  static const _minLength = 3;

  void handleKey(String character) {
    final now = DateTime.now();
    if (_lastKeyTime != null && now.difference(_lastKeyTime!) > _maxGap) {
      _buffer = '';
    }
    _lastKeyTime = now;
    _buffer += character;
  }

  void submit() {
    final code = _buffer.trim();
    _buffer = '';
    _lastKeyTime = null;
    if (code.length >= _minLength) {
      _controller.add(code);
    }
  }

  String extrairNumeroComanda(String barcode) {
    final numeros = barcode.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.isEmpty) return '';

    const int maxInt32 = 2147483647;
    final valor = int.tryParse(numeros) ?? 0;

    if (valor > maxInt32) {
      return numeros.substring(math.max(0, numeros.length - 9));
    }
    return numeros;
  }
}
