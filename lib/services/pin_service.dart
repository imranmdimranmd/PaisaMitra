import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of checking an entered PIN.
class PinVerifyResult {
  final bool ok;
  final int attemptsLeft;

  /// > 0 when too many wrong attempts were made and the PIN is temporarily
  /// locked. Value is the number of seconds left.
  final int lockedSeconds;

  const PinVerifyResult({
    required this.ok,
    this.attemptsLeft = 0,
    this.lockedSeconds = 0,
  });

  String get message {
    if (lockedSeconds > 0) {
      return 'Too many attempts. Try again in ${lockedSeconds}s';
    }
    return 'Wrong PIN. $attemptsLeft ${attemptsLeft == 1 ? 'attempt' : 'attempts'} left';
  }
}

/// Stores a salted, iterated SHA-256 hash of the PIN (never the PIN itself).
class PinService {
  PinService._();

  static final PinService instance = PinService._();

  static const int pinLength = 4;
  static const int maxAttempts = 5;
  static const int lockSeconds = 30;

  static const String _hashKey = 'pin_hash';
  static const String _saltKey = 'pin_salt';
  static const String _failKey = 'pin_failed_attempts';
  static const String _lockUntilKey = 'pin_locked_until';

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_hashKey) != null && prefs.getString(_saltKey) != null;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final rng = Random.secure();
    final salt = base64Encode(List<int>.generate(16, (_) => rng.nextInt(256)));
    await prefs.setString(_saltKey, salt);
    await prefs.setString(_hashKey, _hash(pin, salt));
    await prefs.remove(_failKey);
    await prefs.remove(_lockUntilKey);
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hashKey);
    await prefs.remove(_saltKey);
    await prefs.remove(_failKey);
    await prefs.remove(_lockUntilKey);
  }

  Future<PinVerifyResult> verify(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    final lockUntil = prefs.getInt(_lockUntilKey) ?? 0;
    if (lockUntil > now) {
      return PinVerifyResult(
        ok: false,
        lockedSeconds: ((lockUntil - now) / 1000).ceil(),
      );
    }

    final salt = prefs.getString(_saltKey);
    final stored = prefs.getString(_hashKey);
    if (salt == null || stored == null) {
      return const PinVerifyResult(ok: true); // no PIN set
    }

    if (_constantTimeEquals(_hash(pin, salt), stored)) {
      await prefs.remove(_failKey);
      await prefs.remove(_lockUntilKey);
      return const PinVerifyResult(ok: true);
    }

    final failed = (prefs.getInt(_failKey) ?? 0) + 1;
    if (failed >= maxAttempts) {
      await prefs.setInt(_failKey, 0);
      await prefs.setInt(_lockUntilKey, now + lockSeconds * 1000);
      return const PinVerifyResult(ok: false, lockedSeconds: lockSeconds);
    }
    await prefs.setInt(_failKey, failed);
    return PinVerifyResult(ok: false, attemptsLeft: maxAttempts - failed);
  }

  String _hash(String pin, String salt) {
    final saltBytes = utf8.encode(salt);
    List<int> digest = sha256.convert(utf8.encode('$salt:$pin')).bytes;
    for (var i = 0; i < 10000; i++) {
      digest = sha256.convert([...digest, ...saltBytes]).bytes;
    }
    return base64Encode(digest);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
