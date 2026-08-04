import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_lock_service.dart';

/// Provider checking if device hardware supports Biometrics (Fingerprint / Face ID).
final isDeviceBiometricsSupportedProvider = FutureProvider<bool>((ref) async {
  return await AppLockService.instance.canCheckBiometrics();
});

/// Notifier managing App Lock feature toggle (Phone Lock PIN/Pattern/Password/Biometrics).
class AppLockEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    _init();
    return false;
  }

  Future<void> _init() async {
    final val = await AppLockService.instance.loadAppLockEnabled();
    state = val;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await AppLockService.instance.saveAppLockEnabled(enabled);
  }
}

final isAppLockEnabledProvider =
    NotifierProvider<AppLockEnabledNotifier, bool>(AppLockEnabledNotifier.new);

/// Notifier managing runtime lock gate status (true = app screen locked by security gate).
class AppLockedStateNotifier extends Notifier<bool> {
  @override
  bool build() {
    final isLockEnabled = ref.watch(isAppLockEnabledProvider);
    return isLockEnabled;
  }

  void lock() {
    state = true;
  }

  void unlock() {
    state = false;
  }
}

final isAppLockedProvider =
    NotifierProvider<AppLockedStateNotifier, bool>(AppLockedStateNotifier.new);
