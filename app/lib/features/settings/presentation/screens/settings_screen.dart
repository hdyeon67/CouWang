import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/resources/app_strings.dart';
import '../../../../core/services/app_permission_service.dart';
import '../../../../core/widgets/app_tab_scaffold.dart';
import '../../../../repositories/coupon_repository.dart';
import '../../../../repositories/settings_repository.dart';
import '../../../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _masterEnabled = false;
  bool _expireDayEnabled = false;
  bool _day1Enabled = false;
  bool _day3Enabled = false;
  bool _day7Enabled = false;
  bool _day30Enabled = false;
  int _testNotificationDelaySeconds = 10;
  String _appVersionLabel = '';
  Timer? _foregroundTestNotificationTimer;

  static const List<({int seconds, String label})> _testDelayOptions = [
    (seconds: 10, label: AppStrings.settingsTestTime10Sec),
    (seconds: 30, label: AppStrings.settingsTestTime30Sec),
    (seconds: 60, label: AppStrings.settingsTestTime1Min),
    (seconds: 180, label: AppStrings.settingsTestTime3Min),
    (seconds: 300, label: AppStrings.settingsTestTime5Min),
  ];

  @override
  void initState() {
    super.initState();
    _syncNotificationPermissionState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }

    setState(() {
      _appVersionLabel = 'v${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _syncNotificationPermissionState() async {
    final granted =
        await AppPermissionService.isNotificationPermissionGranted();
    final saved = SettingsRepository.load();
    if (!mounted) {
      return;
    }

    setState(() {
      if (granted) {
        _masterEnabled = saved.masterEnabled;
        _expireDayEnabled = saved.expireDayEnabled;
        _day1Enabled = saved.day1Enabled;
        _day3Enabled = saved.day3Enabled;
        _day7Enabled = saved.day7Enabled;
        _day30Enabled = saved.day30Enabled;
      } else {
        _masterEnabled = false;
        _expireDayEnabled = false;
        _day1Enabled = false;
        _day3Enabled = false;
        _day7Enabled = false;
        _day30Enabled = false;
      }
    });
  }

  NotificationSettingsModel _buildSettings() {
    return NotificationSettingsModel(
      masterEnabled: _masterEnabled,
      expireDayEnabled: _expireDayEnabled,
      day1Enabled: _day1Enabled,
      day3Enabled: _day3Enabled,
      day7Enabled: _day7Enabled,
      day30Enabled: _day30Enabled,
    );
  }

  Future<void> _saveAndReschedule() async {
    SettingsRepository.save(_buildSettings());
    await NotificationService().rescheduleAllCouponNotifications();
  }

  Future<void> _handleMasterToggle(bool val) async {
    if (val) {
      final granted =
          await AppPermissionService.ensureNotificationPermission(context);
      if (!granted || !mounted) {
        return;
      }
    }

    setState(() {
      _masterEnabled = val;
      if (!val) {
        _expireDayEnabled = false;
        _day1Enabled = false;
        _day3Enabled = false;
        _day7Enabled = false;
        _day30Enabled = false;
      } else {
        _expireDayEnabled = true;
        _day1Enabled = true;
        _day3Enabled = true;
        _day7Enabled = true;
        _day30Enabled = false;
      }
    });
    await _saveAndReschedule();
  }

  Future<void> _handleSubToggle({
    required bool nextValue,
    required ValueSetter<bool> apply,
  }) async {
    if (nextValue) {
      final granted =
          await AppPermissionService.ensureNotificationPermission(context);
      if (!granted || !mounted) {
        return;
      }
    }

    setState(() {
      apply(nextValue);
    });
    await _saveAndReschedule();
  }

  Future<void> _showTestNotification() async {
    final granted =
        await AppPermissionService.ensureNotificationPermission(context);
    if (!granted || !mounted) {
      return;
    }

    await CouponRepository.addInternalNotificationTestCoupons();

    final couponName =
        CouponRepository.getAll().isNotEmpty
            ? CouponRepository.getAll().first.name
            : AppStrings.brandStarbucks;
    await NotificationService().scheduleAllTestNotifications(
      couponName: couponName,
      startAfter: Duration(seconds: _testNotificationDelaySeconds),
    );
    _foregroundTestNotificationTimer?.cancel();
    _foregroundTestNotificationTimer = Timer(
      Duration(seconds: _testNotificationDelaySeconds),
      () async {
        if (!mounted) {
          return;
        }
        await NotificationService().cancelScheduledTestNotifications();
        await NotificationService().showAllTestNotifications(couponName);
      },
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(AppStrings.settingsTestNotificationScheduled),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _addInternalTestCoupons() async {
    await CouponRepository.addInternalNotificationTestCoupons();
    await NotificationService().rescheduleAllCouponNotifications();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(AppStrings.settingsTestCouponsDone),
          behavior: SnackBarBehavior.floating,
        ),
      );
    setState(() {});
  }

  @override
  void dispose() {
    _foregroundTestNotificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTabScaffold(
      currentTab: BottomTabItem.settings,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.settingsTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EDE8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.settingsMasterTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                AppStrings.settingsMasterDescription,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF9E9E9E),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: _masterEnabled,
                          onChanged: _handleMasterToggle,
                          activeThumbColor: const Color(0xFF64CAFA),
                          activeTrackColor:
                              const Color(0xFF64CAFA).withValues(alpha: 0.4),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFBDBDBD),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE8DDD8),
                    ),
                    const SizedBox(height: 12),
                    _SubToggleRow(
                      label: AppStrings.settingsExpireDay,
                      enabled: _masterEnabled,
                      value: _masterEnabled ? _expireDayEnabled : false,
                      onChanged: (val) => _handleSubToggle(
                        nextValue: val,
                        apply: (value) => _expireDayEnabled = value,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _SubToggleRow(
                      label: AppStrings.settingsDay1,
                      enabled: _masterEnabled,
                      value: _masterEnabled ? _day1Enabled : false,
                      onChanged: (val) => _handleSubToggle(
                        nextValue: val,
                        apply: (value) => _day1Enabled = value,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _SubToggleRow(
                      label: AppStrings.settingsDay3,
                      enabled: _masterEnabled,
                      value: _masterEnabled ? _day3Enabled : false,
                      onChanged: (val) => _handleSubToggle(
                        nextValue: val,
                        apply: (value) => _day3Enabled = value,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _SubToggleRow(
                      label: AppStrings.settingsDay7,
                      enabled: _masterEnabled,
                      value: _masterEnabled ? _day7Enabled : false,
                      onChanged: (val) => _handleSubToggle(
                        nextValue: val,
                        apply: (value) => _day7Enabled = value,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _SubToggleRow(
                      label: AppStrings.settingsDay30,
                      enabled: _masterEnabled,
                      value: _masterEnabled ? _day30Enabled : false,
                      onChanged: (val) => _handleSubToggle(
                        nextValue: val,
                        apply: (value) => _day30Enabled = value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _addInternalTestCoupons,
                  icon: const Icon(
                    Icons.playlist_add_outlined,
                    size: 20,
                    color: Color(0xFF555555),
                  ),
                  label: const Text(
                    AppStrings.settingsTestCoupons,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555555),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F0F0),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        AppStrings.settingsTestTimeTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _testNotificationDelaySeconds,
                        borderRadius: BorderRadius.circular(14),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF555555),
                          fontWeight: FontWeight.w500,
                        ),
                        items: _testDelayOptions
                            .map(
                              (option) => DropdownMenuItem<int>(
                                value: option.seconds,
                                child: Text(option.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _testNotificationDelaySeconds = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _showTestNotification,
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    size: 20,
                    color: Color(0xFF555555),
                  ),
          label: const Text(
                    AppStrings.settingsTestAllNotifications,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555555),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F0F0),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (_appVersionLabel.isNotEmpty) ...[
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    _appVersionLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFBDBDBD),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubToggleRow extends StatelessWidget {
  const _SubToggleRow({
    required this.label,
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool enabled;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: enabled ? FontWeight.w500 : FontWeight.w400,
              color: enabled ? const Color(0xFF1A1A1A) : const Color(0xFFBDBDBD),
            ),
          ),
          const Spacer(),
          Switch(
            value: enabled ? value : false,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: const Color(0xFF64CAFA),
            activeTrackColor:
                const Color(0xFF64CAFA).withValues(alpha: 0.4),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFBDBDBD),
          ),
        ],
      ),
    );
  }
}
