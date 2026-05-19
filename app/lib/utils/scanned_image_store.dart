// 갤러리 자동 감지에서 이미 처리한 이미지를 기억하는 경량 저장소.
//
// SQLite까지 갈 정도는 아니라 SharedPreferences로 해시와 마지막 스캔 시각만 저장한다.
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 갤러리 자동 감지에서 처리한 이미지 해시를 보관하는 저장소.
class ScannedImageStore {
  ScannedImageStore._();

  static const _rejectedKey = 'rejected_image_hashes';
  static const _registeredKey = 'registered_image_hashes';
  static const _lastScanKey = 'last_scan_timestamp';

  static Future<Set<String>> getRejectedHashes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_rejectedKey) ?? <String>[]).toSet();
  }

  // addRejectedHash 관련 처리를 수행한다.
  static Future<void> addRejectedHash(String hash) async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getStringList(_rejectedKey) ?? <String>[]).toSet();
    next.add(hash);
    await prefs.setStringList(_rejectedKey, next.toList()..sort());
  }

  // addRegisteredHash 관련 처리를 수행한다.
  static Future<void> addRegisteredHash(String hash) async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getStringList(_registeredKey) ?? <String>[]).toSet();
    next.add(hash);
    await prefs.setStringList(_registeredKey, next.toList()..sort());
  }

  // 주어진 값이나 상태가 조건을 만족하는지 검사한다.
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

  // 변경된 데이터나 상태를 저장한다.
  static Future<void> saveLastScanTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastScanKey, time.toIso8601String());
  }

  // getLastScanTime 관련 처리를 수행한다.
  static Future<DateTime?> getLastScanTime() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastScanKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  // clearProcessedState 관련 처리를 수행한다.
  static Future<void> clearProcessedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rejectedKey);
    await prefs.remove(_registeredKey);
    await prefs.remove(_lastScanKey);
  }
}

// generateImageHash 관련 처리를 수행한다.
String generateImageHash(Uint8List bytes) {
  // 원본 전체 파일 대신 thumbnail bytes 기준으로 해시를 만들어
  // 속도와 중복 판정의 균형을 맞춘다.
  return md5.convert(bytes).toString();
}
