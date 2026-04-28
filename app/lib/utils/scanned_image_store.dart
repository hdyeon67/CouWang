import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannedImageStore {
  ScannedImageStore._();

  static const _rejectedKey = 'rejected_image_hashes';
  static const _registeredKey = 'registered_image_hashes';
  static const _lastScanKey = 'last_scan_timestamp';

  static Future<Set<String>> getRejectedHashes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_rejectedKey) ?? <String>[]).toSet();
  }

  static Future<void> addRejectedHash(String hash) async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getStringList(_rejectedKey) ?? <String>[]).toSet();
    next.add(hash);
    await prefs.setStringList(_rejectedKey, next.toList()..sort());
  }

  static Future<void> addRegisteredHash(String hash) async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getStringList(_registeredKey) ?? <String>[]).toSet();
    next.add(hash);
    await prefs.setStringList(_registeredKey, next.toList()..sort());
  }

  static Future<bool> isProcessed(String hash) async {
    final prefs = await SharedPreferences.getInstance();
    final rejected = (prefs.getStringList(_rejectedKey) ?? <String>[]).toSet();
    if (rejected.contains(hash)) {
      return true;
    }
    final registered =
        (prefs.getStringList(_registeredKey) ?? <String>[]).toSet();
    return registered.contains(hash);
  }

  static Future<void> saveLastScanTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastScanKey, time.toIso8601String());
  }

  static Future<DateTime?> getLastScanTime() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastScanKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  static Future<void> clearProcessedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rejectedKey);
    await prefs.remove(_registeredKey);
    await prefs.remove(_lastScanKey);
  }
}

String generateImageHash(Uint8List bytes) {
  return md5.convert(bytes).toString();
}
