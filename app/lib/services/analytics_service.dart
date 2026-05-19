// Firebase Analytics / Crashlytics 래퍼.
//
// 앱 코드 곳곳에서 Firebase SDK를 직접 부르지 않고, 이 서비스 하나를 통해
// 활성화 여부와 실패 처리를 공통화한다.
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

// Firebase Analytics와 Crashlytics 연동을 감싸는 서비스.
class AnalyticsService {
  AnalyticsService._internal();

  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  static const bool _firebaseEnabled = bool.fromEnvironment(
    'ENABLE_FIREBASE',
  );

  bool _initialized = false;
  bool _available = false;
  Object? _initError;

  bool get isAvailable => _available;

  Object? get initError => _initError;

  // init 관련 처리를 수행한다.
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!_firebaseEnabled || kIsWeb) {
      // 빌드 옵션이 없으면 앱은 로컬 전용 모드처럼 동작한다.
      return;
    }

    try {
      await Firebase.initializeApp();
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      _available = true;
      _initError = null;
    } catch (error, stackTrace) {
      _initError = error;
      debugPrint('Firebase analytics disabled: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // configureCrashReporting 관련 처리를 수행한다.
  void configureCrashReporting() {
    // Flutter zone 밖에서 나는 fatal error까지 Crashlytics로 보내기 위한 훅.
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

  // recordNonFatal 관련 처리를 수행한다.
  Future<void> recordNonFatal(Object error, StackTrace stackTrace) async {
    if (!_available) {
      return;
    }
    await FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  // crashForTesting 관련 처리를 수행한다.
  void crashForTesting() {
    if (!_available) {
      throw StateError(
        'Crashlytics is not available. Run with ENABLE_FIREBASE=true and check Firebase config files. Last init error: $_initError',
      );
    }
    FirebaseCrashlytics.instance.log(
      'Crashlytics forced test crash from settings screen',
    );
    FirebaseCrashlytics.instance.setCustomKey('test_crash_source', 'settings');
    FirebaseCrashlytics.instance.crash();
  }

  // logEvent 관련 처리를 수행한다.
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
