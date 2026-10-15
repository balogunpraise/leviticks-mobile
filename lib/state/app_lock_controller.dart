import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mobile-only app-open lock — no web equivalent to mirror. When [enabled],
/// the app shows [isUnlocked] gated content behind a biometric prompt on
/// cold start and whenever it resumes from the background.
class AppLockController extends ChangeNotifier {
  static const _key = 'biometric_lock_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  bool enabled = false;
  bool isUnlocked = false;
  bool _bootstrapped = false;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_key) ?? false;
    isUnlocked = !enabled;
    _bootstrapped = true;
    notifyListeners();
  }

  /// Whether this device can even show a biometric/PIN prompt.
  Future<bool> isSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final deviceSupported = await _auth.isDeviceSupported();
      return canCheck || deviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Turns the lock on — requires a successful scan first, so a user can't
  /// lock themselves out with a prompt that never actually works on their device.
  Future<bool> enable() async {
    final ok = await _authenticate('Confirm your fingerprint or face to turn on app lock');
    if (!ok) return false;
    enabled = true;
    isUnlocked = true;
    await (await SharedPreferences.getInstance()).setBool(_key, true);
    notifyListeners();
    return true;
  }

  Future<void> disable() async {
    enabled = false;
    isUnlocked = true;
    await (await SharedPreferences.getInstance()).setBool(_key, false);
    notifyListeners();
  }

  /// Called when the prompt should appear (cold start, foreground resume).
  Future<bool> tryUnlock() async {
    if (!enabled || isUnlocked) return true;
    final ok = await _authenticate('Unlock Leviticks');
    if (ok) {
      isUnlocked = true;
      notifyListeners();
    }
    return ok;
  }

  /// Called when the app goes to the background, so it's locked again next time.
  void lock() {
    if (!_bootstrapped || !enabled || !isUnlocked) return;
    isUnlocked = false;
    notifyListeners();
  }

  Future<bool> _authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
