class CartItem {
  final String id;
  final String productId;
  final String name;
  final String imagePath;
  final double basePrice;
  int quantity;
  String? observation;
  final Map<String, List<String>> selectedOptions;
  final Map<String, double> selectedOptionPrices;
  final Map<String, int> selectedOptionQuantities;
  final double optionsPrice;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imagePath,
    required this.basePrice,
    this.quantity = 1,
    this.observation,
    this.selectedOptions = const {},
    this.selectedOptionPrices = const {},
    this.selectedOptionQuantities = const {},
    this.optionsPrice = 0.0,
  });

  double get total => (basePrice + optionsPrice) * quantity;

  double get unitPrice => basePrice + optionsPrice;

  /// Retorna uma lista plana de todos os IDs de opções selecionados
  List<String> get allSelectedOptionIds {
    return selectedOptions.values.expand((list) => list).toList();
  }

  /// Retorna o nome de exibição das opções selecionadas
  String get selectedOptionsDisplay {
    if (selectedOptions.isEmpty) return '';
    final parts = <String>[];
    for (final groupEntry in selectedOptions.entries) {
      for (final optionId in groupEntry.value) {
        final qty = selectedOptionQuantities[optionId] ?? 1;
        if (qty > 1) {
          parts.add('$optionId x$qty');
        } else {
          parts.add(optionId);
        }
      }
    }
    return parts.join(' / ');
  }

  /// Retorna o preço de um optionId específico
  double priceForOption(String optionId) {
    return selectedOptionPrices[optionId] ?? 0.0;
  }
}
