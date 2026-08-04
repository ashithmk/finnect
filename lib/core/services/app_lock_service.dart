import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Core Service handling Device Phone Lock (PIN / Pattern / Password / Biometrics) and App Lock preferences.
class AppLockService {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _prefAppLockKey = 'app_lock_enabled';

  /// Checks if device hardware supports biometric authentication (Fingerprint / Face ID).
  Future<bool> canCheckBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();

      debugPrint('Biometrics diagnostic: canCheck=$canAuthenticateWithBiometrics, isSupported=$isDeviceSupported, available=$availableBiometrics');

      return (canAuthenticateWithBiometrics || isDeviceSupported) && availableBiometrics.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics support: $e');
      return false;
    } catch (e) {
      debugPrint('Unexpected biometrics check error: $e');
      return false;
    }
  }

  /// Triggers system Phone Lock authentication prompt (Phone PIN / Pattern / Password / Biometrics).
  Future<bool> authenticateWithDeviceLock({
    String reason = 'Enter your phone lock PIN, pattern, or biometrics to unlock Finnect',
  }) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Prompts Phone Lock Screen PIN / Pattern / Password or Biometrics!
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('PlatformException during device lock authentication: $e');
      return false;
    } catch (e) {
      debugPrint('Unexpected error during device lock authentication: $e');
      return false;
    }
  }

  // Preference Storage Operations
  Future<bool> loadAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefAppLockKey) ?? false;
  }

  Future<void> saveAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAppLockKey, enabled);
  }
}
