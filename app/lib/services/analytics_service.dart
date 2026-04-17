import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._internal();

  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  static const bool _firebaseEnabled = bool.fromEnvironment(
    'ENABLE_FIREBASE',
  );

  bool _initialized = false;
  bool _available = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!_firebaseEnabled || kIsWeb) {
      return;
    }

    try {
      await Firebase.initializeApp();
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      _available = true;
    } catch (error, stackTrace) {
      debugPrint('Firebase analytics disabled: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void configureCrashReporting() {
    if (!_available) {
      return;
    }

    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: true,
      );
      return true;
    };
  }

  Future<void> logCouponCreated({
    required String category,
    required String couponType,
    required String entryType,
    required bool hasImage,
    required int dday,
  }) {
    return _logEvent(
      'coupon_created',
      {
        'category': category,
        'coupon_type': couponType,
        'entry_type': entryType,
        'has_image': hasImage,
        'dday': dday,
      },
    );
  }

  Future<void> logCouponUsed({
    required String category,
    required int dday,
  }) {
    return _logEvent(
      'coupon_used',
      {
        'category': category,
        'dday': dday,
      },
    );
  }

  Future<void> logNotificationOpened({
    String? notificationType,
  }) {
    return _logEvent(
      'notification_opened',
      {
        'notification_type': notificationType ?? 'unknown',
      },
    );
  }

  Future<void> logImageExtractAttempted({
    required String source,
  }) {
    return _logEvent(
      'image_extract_attempted',
      {
        'source': source,
      },
    );
  }

  Future<void> logImageExtractSucceeded({
    required String source,
    required String couponType,
    required bool categoryResolved,
  }) {
    return _logEvent(
      'image_extract_succeeded',
      {
        'source': source,
        'coupon_type': couponType,
        'category_resolved': categoryResolved,
      },
    );
  }

  Future<void> logImageExtractFailed({
    required String source,
    required String reason,
  }) {
    return _logEvent(
      'image_extract_failed',
      {
        'source': source,
        'reason': reason,
      },
    );
  }

  Future<void> recordNonFatal(Object error, StackTrace stackTrace) async {
    if (!_available) {
      return;
    }
    await FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  Future<void> _logEvent(String name, Map<String, Object> parameters) async {
    if (!_available) {
      return;
    }
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (error, stackTrace) {
      debugPrint('Firebase analytics event failed: $name, $error');
      await recordNonFatal(error, stackTrace);
    }
  }
}
