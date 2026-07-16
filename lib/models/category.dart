import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;

  Category({
    required this.id,
    required this.name,
    required this.icon,
  });

  String get displayName => name.trim().replaceAll(RegExp(r'\.+$'), '');

  factory Category.fromJson(Map<String, dynamic> json) {
    final nome = json['nome'] as String? ?? 'Sem nome';
    return Category(
      id: json['id'].toString(),
      name: nome,
      icon: _iconFromName(nome),
    );
  }

  static IconData _iconFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('doce')) return Icons.cake_outlined;
    if (lower.contains('famil')) return Icons.people_outline;
    if (lower.contains('salg')) return Icons.local_pizza_outlined;
    if (lower.contains('combo')) return Icons.fastfood_outlined;
    if (lower.contains('gelad') || lower.contains('bebida')) return Icons.local_drink_outlined;
    if (lower.contains('quent') || lower.contains('cafe')) return Icons.coffee_outlined;
    return Icons.restaurant_menu;
  }
}
