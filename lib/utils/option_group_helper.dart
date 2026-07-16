import '../models/product_option.dart';

class OptionGroupHelper {
  /// Retorna a quantidade máxima efetiva para um grupo de opções.
  /// Se o grupo for de "sabor", busca nos grupos de "bola" a quantidade
  /// selecionada e usa esse número como novo máximo.
  static int effectiveQtdMax(
    ProductOptionGroup group,
    Map<String, List<String>> selectedOptions,
    List<ProductOptionGroup> allGroups,
  ) {
    if (!_isFlavorGroup(group)) {
      return group.qtdMax;
    }

    final ballCount = _extractBallCountFromSelections(selectedOptions, allGroups);
    if (ballCount > 0) {
      return ballCount;
    }
    return group.qtdMax;
  }

  static bool _isFlavorGroup(ProductOptionGroup group) {
    return group.name.toLowerCase().contains('sabor');
  }

  static bool _isBallGroup(ProductOptionGroup group) {
    return group.name.toLowerCase().contains('bola');
  }

  static int _extractBallCountFromSelections(
    Map<String, List<String>> selectedOptions,
    List<ProductOptionGroup> allGroups,
  ) {
    int count = 0;
    for (final g in allGroups) {
      if (_isBallGroup(g)) {
        final selectedIds = selectedOptions[g.id] ?? [];
        if (selectedIds.isNotEmpty) {
          final option = g.options.firstWhere(
            (o) => o.id == selectedIds.first,
            orElse: () => g.options.first,
          );
          final number = _extractFirstNumber(option.name);
          if (number != null && number > count) {
            count = number;
          }
        }
      }
    }
    return count;
  }

  static int? _extractFirstNumber(String text) {
    final match = RegExp(r'\d+').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }
    return null;
  }
}
