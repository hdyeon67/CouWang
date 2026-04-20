import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../app/router.dart';
import '../app/app_navigator.dart';
import '../core/resources/app_strings.dart';
import '../features/coupons/presentation/screens/coupon_detail_screen.dart';
import '../repositories/coupon_repository.dart';
import '../repositories/notification_log_repository.dart';
import '../repositories/settings_repository.dart';
import 'analytics_service.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _launchPayload;
  bool _launchedFromNotification = false;
  bool _showingNotificationDetail = false;
  DateTime? _notificationDetailOpenedAt;
  String? _pendingTapPayload;
  bool _handlingTap = false;

  bool get launchedFromNotification => _launchedFromNotification;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        handleNotificationTap(response.payload);
      },
    );

    const channel = AndroidNotificationChannel(
      'kuwang_coupon_alerts',
      '쿠폰 만료 알림',
      description: '쿠폰 만료 전 알림을 받습니다.',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _launchPayload = launchDetails?.notificationResponse?.payload;
      _launchedFromNotification = true;
    }

    _initialized = true;
  }

  Future<void> handlePendingLaunchPayload() async {
    if (_launchPayload == null) {
      return;
    }

    final payload = _launchPayload;
    _launchPayload = null;
    await handleNotificationTap(payload);
  }

  Future<void> handlePendingNotificationTap() async {
    final payload = _pendingTapPayload;
    if (payload == null) {
      return;
    }
    _pendingTapPayload = null;
    await handleNotificationTap(payload);
  }

  void markLaunchSplashHandled() {
    _launchedFromNotification = false;
  }

  bool consumeNotificationDetailResumeReset() {
    if (!_showingNotificationDetail) {
      return false;
    }
    final openedAt = _notificationDetailOpenedAt;
    if (openedAt != null &&
        DateTime.now().difference(openedAt) < const Duration(seconds: 2)) {
      return false;
    }
    _showingNotificationDetail = false;
    _notificationDetailOpenedAt = null;
    return true;
  }

  Future<void> handleNotificationTap(String? payload) async {
    if (payload == null || payload.isEmpty) {
      return;
    }
    if (!_isNavigatorReady) {
      _queueNotificationTap(payload);
      return;
    }
    if (_handlingTap) {
      _pendingTapPayload = payload;
      return;
    }

    _handlingTap = true;
    try {
      final notificationPayload = _parsePayload(payload);
      if (notificationPayload == null) {
        return;
      }

      final coupon = CouponRepository.findById(notificationPayload.couponId);
      if (coupon == null) {
        return;
      }

      final notificationType = notificationPayload.notificationType;
      await AnalyticsService().logNotificationOpened(
        notificationType: notificationType,
      );
      if (notificationType == null) {
        await NotificationLogRepository.ensureLatestVisibleLogForCoupon(
          coupon: coupon,
          notificationType: 'tap',
          title: AppStrings.notificationGenericTitle,
          body: _getBody('default', coupon.name),
          scheduledAt: DateTime.now(),
          markAsRead: true,
        );
        await NotificationLogRepository.markLatestUnreadAsReadByCouponId(
          coupon.id,
        );
      } else {
        final logId = _logId(coupon.id, notificationType);
        await NotificationLogRepository.upsertLog(
          id: logId,
          couponId: coupon.id,
          notificationType: notificationType,
          title: _getTitle(notificationType),
          body: _getBody(notificationType, coupon.name),
          scheduledAt: DateTime.now(),
        );
        await NotificationLogRepository.markAsReadById(logId);
      }

      navigatorKey.currentState!.pushNamedAndRemoveUntil(
        AppRouter.home,
        (route) => false,
      );
      navigatorKey.currentState!.pushNamed(
        AppRouter.couponDetail,
        arguments: coupon,
      );
      _showingNotificationDetail = true;
      _notificationDetailOpenedAt = DateTime.now();
    } finally {
      _handlingTap = false;
    }
    await handlePendingNotificationTap();
  }

  bool get _isNavigatorReady =>
      navigatorKey.currentState != null && navigatorKey.currentContext != null;

  void _queueNotificationTap(String payload) {
    _pendingTapPayload = payload;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handlePendingNotificationTap();
    });
  }

  Future<void> scheduleCouponNotifications(
    CouponDetailModel coupon,
    NotificationSettingsModel settings,
    {
    bool cancelExistingNotifications = true,
    bool deleteExistingLogs = true,
  }) async {
    if (kIsWeb) {
      return;
    }
    if (cancelExistingNotifications) {
      await cancelCouponNotifications(
        coupon.id,
        deleteLogs: deleteExistingLogs,
      );
    }

    if (!settings.masterEnabled || coupon.isUsed || coupon.isExpired) {
      return;
    }

    final expiry = coupon.expiryDateTime;
    if (expiry == null) {
      return;
    }

    const schedules = <({int days, String type})>[
      (days: 30, type: 'd30'),
      (days: 7, type: 'd7'),
      (days: 3, type: 'd3'),
      (days: 1, type: 'd1'),
      (days: 0, type: 'dday'),
      (days: -1, type: 'expire'),
    ];

    for (final schedule in schedules) {
      if (!_shouldSchedule(schedule.type, settings)) {
        continue;
      }

      final targetDate = expiry.subtract(Duration(days: schedule.days));
      final scheduledTime = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        12,
      );

      if (!scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
        continue;
      }

      await NotificationLogRepository.upsertLog(
        id: _logId(coupon.id, schedule.type),
        couponId: coupon.id,
        notificationType: schedule.type,
        title: _getTitle(schedule.type),
        body: _getBody(schedule.type, coupon.name),
        scheduledAt: scheduledTime,
      );

      await _zonedSchedule(
        _notificationId(coupon.id, schedule.type),
        _getTitle(schedule.type),
        _getBody(schedule.type, coupon.name),
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'kuwang_coupon_alerts',
            '쿠폰 만료 알림',
            channelDescription: '쿠폰 만료 전 알림을 받습니다.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              _getBody(schedule.type, coupon.name),
              contentTitle: _getTitle(schedule.type),
              summaryText: AppStrings.appTitle,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: _payloadFor(coupon.id, schedule.type),
      );
    }
  }

  Future<void> cancelCouponNotifications(
    String couponId, {
    bool deleteLogs = true,
  }) async {
    if (kIsWeb) {
      if (deleteLogs) {
        await NotificationLogRepository.deleteLogsByCouponId(couponId);
      }
      return;
    }
    const types = ['d30', 'd7', 'd3', 'd1', 'dday', 'expire'];
    for (final type in types) {
      await _plugin.cancel(_notificationId(couponId, type));
    }
    if (deleteLogs) {
      await NotificationLogRepository.deleteLogsByCouponId(couponId);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      await NotificationLogRepository.deleteAllLogs();
      return;
    }
    await _plugin.cancelAll();
    await NotificationLogRepository.deleteAllLogs();
  }

  Future<void> rescheduleAllCouponNotifications() async {
    if (kIsWeb) {
      return;
    }
    final settings = SettingsRepository.load();
    if (!settings.masterEnabled) {
      await _plugin.cancelAll();
      return;
    }

    for (final coupon in CouponRepository.getAll()) {
      if (!coupon.isUsed && !coupon.isExpired) {
        await scheduleCouponNotifications(
          coupon,
          settings,
          cancelExistingNotifications: false,
          deleteExistingLogs: false,
        );
      }
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (payload != null) {
      final notificationPayload = _parsePayload(payload);
      final coupon = notificationPayload == null
          ? null
          : CouponRepository.findById(notificationPayload.couponId);
      if (coupon != null) {
        final notificationType =
            notificationPayload?.notificationType ?? 'immediate';
        await NotificationLogRepository.upsertLog(
          id: _logId(coupon.id, notificationType),
          couponId: coupon.id,
          notificationType: notificationType,
          title: title,
          body: body,
          scheduledAt: DateTime.now(),
        );
      }
    }

    if (kIsWeb) {
      return;
    }

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'kuwang_coupon_alerts',
          '쿠폰 만료 알림',
          channelDescription: '쿠폰 만료 전 알림을 받습니다.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: AppStrings.appTitle,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> showTestNotification(String couponName) async {
    await showImmediateNotification(
      id: 99999,
      title: _getTitle('dday'),
      body: _getBody('dday', couponName),
      payload: _payloadFor(_testCouponIdForType('dday'), 'dday'),
    );
  }

  Future<void> showAllTestNotifications(String couponName) async {
    const orderedTypes = ['d30', 'd7', 'd3', 'd1', 'dday', 'expire'];
    for (var i = 0; i < orderedTypes.length; i++) {
      final type = orderedTypes[i];
      await showImmediateNotification(
        id: 99990 + i,
        title: _getTitle(type),
        body: _getBody(type, couponName),
        payload: _payloadFor(_testCouponIdForType(type), type),
      );
    }
  }

  Future<void> cancelScheduledTestNotifications() async {
    if (kIsWeb) {
      return;
    }
    for (var i = 0; i < 6; i++) {
      await _plugin.cancel(99100 + i);
    }
  }

  Future<void> scheduleAllTestNotifications({
    required String couponName,
    required Duration startAfter,
  }) async {
    if (kIsWeb) {
      return;
    }
    const orderedTypes = ['d30', 'd7', 'd3', 'd1', 'dday', 'expire'];
    final now = tz.TZDateTime.now(tz.local);

    for (var i = 0; i < orderedTypes.length; i++) {
      final type = orderedTypes[i];
      final scheduledTime = now.add(startAfter + Duration(seconds: i * 10));
      final couponId = _testCouponIdForType(type);
      final coupon = CouponRepository.findById(couponId);

      if (coupon != null) {
        await NotificationLogRepository.upsertLog(
          id: _logId(coupon.id, type),
          couponId: coupon.id,
          notificationType: type,
          title: _getTitle(type),
          body: _getBody(type, coupon.name),
          scheduledAt: scheduledTime,
        );
      }

      await _zonedSchedule(
        99100 + i,
        _getTitle(type),
        _getBody(type, couponName),
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'kuwang_coupon_alerts',
            '쿠폰 만료 알림',
            channelDescription: '쿠폰 만료 전 알림을 받습니다.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              _getBody(type, couponName),
              contentTitle: _getTitle(type),
              summaryText: AppStrings.appTitle,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: _payloadFor(couponId, type),
      );
    }
  }

  Future<void> _zonedSchedule(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledTime,
    NotificationDetails notificationDetails, {
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  _NotificationPayload? _parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }
    final separatorIndex = payload.indexOf('|');
    if (separatorIndex < 0) {
      return _NotificationPayload(couponId: payload);
    }
    return _NotificationPayload(
      couponId: payload.substring(0, separatorIndex),
      notificationType: payload.substring(separatorIndex + 1),
    );
  }

  String _payloadFor(String couponId, String type) => '$couponId|$type';

  bool _shouldSchedule(String type, NotificationSettingsModel settings) {
    switch (type) {
      case 'd30':
        return settings.day30Enabled;
      case 'd7':
        return settings.day7Enabled;
      case 'd3':
        return settings.day3Enabled;
      case 'd1':
        return settings.day1Enabled;
      case 'dday':
      case 'expire':
        return settings.expireDayEnabled;
      default:
        return false;
    }
  }

  int _notificationId(String couponId, String type) {
    const typeIndex = <String, int>{
      'd30': 0,
      'd7': 1,
      'd3': 2,
      'd1': 3,
      'dday': 4,
      'expire': 5,
    };
    return couponId.hashCode.abs() % 100000 * 10 + (typeIndex[type] ?? 0);
  }

  String _logId(String couponId, String type) => '${couponId}_$type';

  String _testCouponIdForType(String type) {
    switch (type) {
      case 'd30':
        return 'internal_test_d30';
      case 'd7':
        return 'internal_test_d7';
      case 'd3':
        return 'internal_test_d3';
      case 'd1':
        return 'internal_test_d1';
      case 'dday':
        return 'internal_test_dday';
      case 'expire':
        return 'internal_test_expired';
      default:
        return 'internal_test_dday';
    }
  }

  String _getTitle(String type) {
    switch (type) {
      case 'd30':
        return AppStrings.notificationTitleD30;
      case 'd7':
        return AppStrings.notificationTitleD7;
      case 'd3':
        return AppStrings.notificationTitleD3;
      case 'd1':
        return AppStrings.notificationTitleD1;
      case 'dday':
        return AppStrings.notificationTitleDday;
      case 'expire':
        return AppStrings.notificationTitleExpired;
      default:
        return AppStrings.notificationGenericTitle;
    }
  }

  String _getBody(String type, String couponName) {
    switch (type) {
      case 'd30':
        return '$couponName${AppStrings.notificationBodyD30Suffix}';
      case 'd7':
        return '$couponName${AppStrings.notificationBodyD7Suffix}';
      case 'd3':
        return '$couponName${AppStrings.notificationBodyD3Suffix}';
      case 'd1':
        return '$couponName${AppStrings.notificationBodyD1Suffix}';
      case 'dday':
        return '$couponName${AppStrings.notificationBodyDdaySuffix}';
      case 'expire':
        return '$couponName${AppStrings.notificationBodyExpiredSuffix}';
      default:
        return '$couponName${AppStrings.notificationBodyGenericSuffix}';
    }
  }
}

class _NotificationPayload {
  const _NotificationPayload({
    required this.couponId,
    this.notificationType,
  });

  final String couponId;
  final String? notificationType;
}
