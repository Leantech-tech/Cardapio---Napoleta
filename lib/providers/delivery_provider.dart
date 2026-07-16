import 'dart:math';
import 'package:flutter/material.dart';

class DeliveryProvider extends ChangeNotifier {
  String? _address;
  double? _deliveryFee;
  bool _isCalculating = false;

  String? get address => _address;
  double? get deliveryFee => _deliveryFee;
  bool get isCalculating => _isCalculating;

  static const double minimumOrder = 50.0;

  // Zonas de entrega simuladas (Ubatuba/SP e região como exemplo)
  static final Map<String, double> _zones = {
    // Zona 1 - Próxima (R$ 5,00)
    'centro': 5.0,
    'itaquera': 5.0,
    'maranduba': 5.0,
    'sertão': 5.0,
    'perequê': 5.0,
    'tenório': 5.0,
    // Zona 2 - Média (R$ 8,00)
    'lagoinha': 8.0,
    'praia grande': 8.0,
    'praia das toninhas': 8.0,
    'ipiranga': 8.0,
    'itanhaém': 8.0,
    'são francisco': 8.0,
    // Zona 3 - Distante (R$ 12,00)
    'ubatumirim': 12.0,
    'picinguaba': 12.0,
    'almada': 12.0,
    'corcovado': 12.0,
    'prumirim': 12.0,
    'domingas dias': 12.0,
    // Zona 4 - Muito distante (R$ 15,00)
    'fazenda': 15.0,
    'sertão da quina': 15.0,
    'picinguaba alta': 15.0,
  };

  Future<void> calculateFee(String address) async {
    _isCalculating = true;
    notifyListeners();

    // Simula delay de "cálculo"
    await Future.delayed(const Duration(milliseconds: 800));

    final lower = address.toLowerCase();
    double? fee;

    for (final entry in _zones.entries) {
      if (lower.contains(entry.key)) {
        fee = entry.value;
        break;
      }
    }

    // Se não encontrou bairro, gera um valor "pseudo-aleatório"
    // baseado no hash do endereço para ser consistente
    if (fee == null) {
      final hash = lower.hashCode.abs();
      final random = Random(hash);
      fee = 5.0 + random.nextDouble() * 12.0; // Entre 5,00 e 17,00
      fee = (fee * 2).round() / 2; // Arredonda para .0 ou .5
    }

    _address = address;
    _deliveryFee = fee;
    _isCalculating = false;
    notifyListeners();
  }

  void clear() {
    _address = null;
    _deliveryFee = null;
    _isCalculating = false;
    notifyListeners();
  }
}
