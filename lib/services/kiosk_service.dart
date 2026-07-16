import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Serviço responsável por configurar e controlar o modo quiosque (kiosk mode)
/// do aplicativo nos tablets do restaurante.
class KioskService {
  KioskService._();

  static final KioskService _instance = KioskService._();
  static KioskService get instance => _instance;

  /// Inicializa o modo quiosque: tela cheia, orientação fixa, tela ligada e lock task.
  static Future<void> initialize() async {
    log('[KioskService] Inicializando modo quiosque...');

    // Mantém a tela ligada enquanto o app estiver aberto.
    try {
      await WakelockPlus.enable();
    } catch (e, stackTrace) {
      log('[KioskService] Erro ao ativar wakelock: $e', stackTrace: stackTrace);
    }

    // Fixa a orientação em landscape (modo paisagem), ideal para tablets na mesa.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Ativa o modo imersivo: esconde status bar e navigation bar.
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    // Ativa o lock task nativo do Android (kiosk mode).
    try {
      await startKioskMode();
      log('[KioskService] Lock task ativado com sucesso.');
    } catch (e, stackTrace) {
      log('[KioskService] Erro ao ativar lock task: $e', stackTrace: stackTrace);
    }
  }

  /// Sai do modo quiosque. Útil para manutenção/administração.
  static Future<void> disable() async {
    log('[KioskService] Desativando modo quiosque...');

    try {
      await stopKioskMode();
    } catch (e, stackTrace) {
      log('[KioskService] Erro ao desativar lock task: $e', stackTrace: stackTrace);
    }

    await WakelockPlus.disable();
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  /// Reaplica o modo imersivo caso o usuário consiga exibir as barras do sistema.
  static Future<void> restoreImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  /// Stream que informa se o kiosk mode está ativo ou não.
  static Stream<KioskMode> get modeStream => watchKioskMode();
}
