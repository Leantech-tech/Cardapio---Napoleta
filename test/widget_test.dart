// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tachao_menu/main.dart';
import 'package:tachao_menu/providers/auth_provider.dart';
import 'package:tachao_menu/providers/theme_provider.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    await authProvider.loadSettings();
    final themeProvider = ThemeProvider();
    await themeProvider.loadSettings();

    await tester.pumpWidget(
      TachaoApp(
        authProvider: authProvider,
        themeProvider: themeProvider,
      ),
    );

    // Simple smoke check that the app builds.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
