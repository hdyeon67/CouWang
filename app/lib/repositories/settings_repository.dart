// 알림 설정 저장소.
//
// 현재는 알림 관련 토글만 DB에 저장하지만, 앱 단위 설정의 기준 레이어 역할을 한다.
import 'package:sqflite/sqflite.dart';

import '../services/local_database_service.dart';

// NotificationSettingsModel 모델 역할을 담당하는 클래스.
class NotificationSettingsModel {
  const NotificationSettingsModel({
    required this.masterEnabled,
    required this.expireDayEnabled,
    required this.day1Enabled,
    required this.day3Enabled,
    required this.day7Enabled,
    required this.day30Enabled,
    required this.notificationConsentAsked,
  });

  const NotificationSettingsModel.defaults()
      : masterEnabled = false,
        expireDayEnabled = true,
        day1Enabled = true,
        day3Enabled = true,
        day7Enabled = true,
        day30Enabled = false,
        notificationConsentAsked = false;

  final bool masterEnabled;
  final bool expireDayEnabled;
  final bool day1Enabled;
  final bool day3Enabled;
  final bool day7Enabled;
  final bool day30Enabled;
  final bool notificationConsentAsked;

  NotificationSettingsModel copyWith({
    bool? masterEnabled,
    bool? expireDayEnabled,
    bool? day1Enabled,
    bool? day3Enabled,
    bool? day7Enabled,
    bool? day30Enabled,
    bool? notificationConsentAsked,
  }) {
    return NotificationSettingsModel(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      expireDayEnabled: expireDayEnabled ?? this.expireDayEnabled,
      day1Enabled: day1Enabled ?? this.day1Enabled,
      day3Enabled: day3Enabled ?? this.day3Enabled,
      day7Enabled: day7Enabled ?? this.day7Enabled,
      day30Enabled: day30Enabled ?? this.day30Enabled,
      notificationConsentAsked:
          notificationConsentAsked ?? this.notificationConsentAsked,
    );
  }
}

// 앱 알림 설정을 저장하고 불러오는 저장소.
class SettingsRepository {
  SettingsRepository._();

  static NotificationSettingsModel _settings =
      const NotificationSettingsModel.defaults();
  static bool _initialized = false;

  // initialize 관련 처리를 수행한다.
  static Future<void> initialize() async {
    // 첫 실행에는 기본값 row를 하나 만든 뒤 메모리 캐시에 보관한다.
    if (_initialized) {
      return;
    }

    final db = await LocalDatabaseService.instance.database;
    final rows = await db.query(
      'notification_settings',
      where: 'id = 1',
      limit: 1,
    );

    if (rows.isEmpty) {
      await save(const NotificationSettingsModel.defaults());
    } else {
      final row = rows.first;
      _settings = NotificationSettingsModel(
        masterEnabled: (row['master_enabled'] as int? ?? 0) == 1,
        expireDayEnabled: (row['expire_day_enabled'] as int? ?? 0) == 1,
        day1Enabled: (row['day1_enabled'] as int? ?? 0) == 1,
        day3Enabled: (row['day3_enabled'] as int? ?? 0) == 1,
        day7Enabled: (row['day7_enabled'] as int? ?? 0) == 1,
        day30Enabled: (row['day30_enabled'] as int? ?? 0) == 1,
        notificationConsentAsked:
            (row['notification_consent_asked'] as int? ?? 0) == 1,
      );
    }

    _initialized = true;
  }

  // 필요한 데이터나 상태를 불러온다.
  static NotificationSettingsModel load() => _settings;

  // 변경된 데이터나 상태를 저장한다.
  static Future<void> save(NotificationSettingsModel settings) async {
    final db = await LocalDatabaseService.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'notification_settings',
      {
        'id': 1,
        'master_enabled': settings.masterEnabled ? 1 : 0,
        'expire_day_enabled': settings.expireDayEnabled ? 1 : 0,
        'day1_enabled': settings.day1Enabled ? 1 : 0,
        'day3_enabled': settings.day3Enabled ? 1 : 0,
        'day7_enabled': settings.day7Enabled ? 1 : 0,
        'day30_enabled': settings.day30Enabled ? 1 : 0,
        'notification_consent_asked':
            settings.notificationConsentAsked ? 1 : 0,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _settings = settings;
  }

  // 관련 상태를 초기값으로 되돌린다.
  static Future<void> resetToDefaults() async {
    await save(const NotificationSettingsModel.defaults());
  }
}
