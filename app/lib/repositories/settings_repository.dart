import 'package:sqflite/sqflite.dart';

import '../services/local_database_service.dart';

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

class SettingsRepository {
  SettingsRepository._();

  static NotificationSettingsModel _settings =
      const NotificationSettingsModel.defaults();
  static bool _initialized = false;

  static Future<void> initialize() async {
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

  static NotificationSettingsModel load() => _settings;

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

  static Future<void> resetToDefaults() async {
    await save(const NotificationSettingsModel.defaults());
  }
}
