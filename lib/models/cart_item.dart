import 'pricing.dart';

class CartItem {
  final String id;
  final String productId;
  final String name;
  final String imagePath;
  double basePrice;
  int quantity;
  String? observation;
  final Map<String, List<String>> selectedOptions;
  final Map<String, double> selectedOptionPrices;
  final Map<String, int> selectedOptionQuantities;
  final double optionsPrice;

  /// Snapshot da origem do preço no momento da compra (PADRAO/TABELA/PROMOCAO).
  PrecoOrigem precoOrigem;

  /// Tabela de preço aplicada ao item, quando houver.
  int? tabelaPrecoId;

  /// Promoção aplicada ao item, quando houver.
  int? promocaoId;
  String? promocaoNome;

  /// Preço padrão (vr_venda) de referência no momento da resolução.
  double? precoPadrao;

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
    this.precoOrigem = PrecoOrigem.padrao,
    this.tabelaPrecoId,
    this.promocaoId,
    this.promocaoNome,
    this.precoPadrao,
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
