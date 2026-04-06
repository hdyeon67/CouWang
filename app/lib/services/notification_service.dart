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

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _launchPayload;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

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

  Future<void> handleNotificationTap(String? payload) async {
    if (payload == null) {
      return;
    }

    await NotificationLogRepository.markLatestUnreadAsReadByCouponId(payload);
    final coupon = CouponRepository.findById(payload);
    if (coupon == null) {
      return;
    }

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRouter.home,
      (route) => false,
    );
    navigatorKey.currentState?.pushNamed(
      AppRouter.couponDetail,
      arguments: coupon,
    );
  }

  Future<void> scheduleCouponNotifications(
    CouponDetailModel coupon,
    NotificationSettingsModel settings,
  ) async {
    await cancelCouponNotifications(coupon.id);

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
        9,
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

      await _plugin.zonedSchedule(
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
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: coupon.id,
      );
    }
  }

  Future<void> cancelCouponNotifications(String couponId) async {
    const types = ['d30', 'd7', 'd3', 'd1', 'dday', 'expire'];
    for (final type in types) {
      await _plugin.cancel(_notificationId(couponId, type));
    }
    await NotificationLogRepository.deleteLogsByCouponId(couponId);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    await NotificationLogRepository.deleteAllLogs();
  }

  Future<void> rescheduleAllCouponNotifications() async {
    await cancelAllNotifications();
    final settings = SettingsRepository.load();
    if (!settings.masterEnabled) {
      return;
    }

    for (final coupon in CouponRepository.getAll()) {
      if (!coupon.isUsed && !coupon.isExpired) {
        await scheduleCouponNotifications(coupon, settings);
      }
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
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
          largeIcon: const DrawableResourceAndroidBitmap(
            '@mipmap/ic_launcher',
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
      payload: 'test_coupon_id',
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
        payload: 'test_coupon_id',
      );
    }
  }

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
