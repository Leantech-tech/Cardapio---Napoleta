import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/delivery_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/menu_screen.dart';
import 'services/api_client.dart';
import 'services/kiosk_service.dart';
import 'widgets/barcode_keyboard_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiClient().init();

  await KioskService.initialize();

  final authProvider = AuthProvider();
  await authProvider.loadSettings();

  final themeProvider = ThemeProvider();
  await themeProvider.loadSettings();

  runApp(
    TachaoApp(
      authProvider: authProvider,
      themeProvider: themeProvider,
    ),
  );
}

class TachaoApp extends StatelessWidget {
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;

  const TachaoApp({
    super.key,
    required this.authProvider,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return BarcodeKeyboardListener(
            child: MaterialApp(
              title: 'Napoleta',
              debugShowCheckedModeBanner: false,
              scrollBehavior: AppScrollBehavior(),
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: const MenuScreen(),
              builder: (context, child) {
                return DefaultTextStyle.merge(
                  style: const TextStyle(
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                  child: child!,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
