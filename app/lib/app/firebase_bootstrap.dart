import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool isInitialized = false;
  static Object? initializationError;
  static Future<void>? _initializingFuture;

  static Future<void> ensureInitialized() {
    if (kIsWeb || isInitialized) {
      return Future<void>.value();
    }

    if (_initializingFuture != null) {
      return _initializingFuture!;
    }

    _initializingFuture = _initialize();
    return _initializingFuture!;
  }

  static Future<void> _initialize() async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
      isInitialized = true;
      initializationError = null;
    } catch (error) {
      initializationError = error;
    }
  }
}
