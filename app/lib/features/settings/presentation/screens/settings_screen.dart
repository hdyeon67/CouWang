import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/resources/app_strings.dart';
import '../../../../core/services/app_permission_service.dart';
import '../../../../core/widgets/app_tab_scaffold.dart';
import '../../../../repositories/coupon_repository.dart';
import '../../../../repositories/membership_repository.dart';
import '../../../../repositories/settings_repository.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/gallery_scan_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../utils/scanned_image_store.dart';
import '../../../coupons/presentation/screens/coupon_create_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const bool _internalTestToolsEnabled = bool.fromEnvironment(
    'ENABLE_INTERNAL_TEST_TOOLS',
  );

  bool _masterEnabled = false;
  bool _expireDayEnabled = false;
  bool _day1Enabled = false;
  bool _day3Enabled = false;
  bool _day7Enabled = false;
  bool _day30Enabled = false;
  bool _autoScanEnabled = false;
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
    _loadAutoScanSetting();
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

  Future<void> _loadAutoScanSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _autoScanEnabled =
          prefs.getBool(GalleryScanService.autoScanEnabledKey) ?? false;
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
    final saved = SettingsRepository.load();
    return NotificationSettingsModel(
      masterEnabled: _masterEnabled,
      expireDayEnabled: _expireDayEnabled,
      day1Enabled: _day1Enabled,
      day3Enabled: _day3Enabled,
      day7Enabled: _day7Enabled,
      day30Enabled: _day30Enabled,
      notificationConsentAsked:
          saved.notificationConsentAsked || _masterEnabled,
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

  Future<void> _addVirtualMemberships() async {
    await MembershipRepository.addVirtualMemberships();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(AppStrings.settingsTestMembershipsDone),
          behavior: SnackBarBehavior.floating,
        ),
      );
    setState(() {});
  }

  Future<void> _runGalleryScanTest() async {
    final service = GalleryScanService();
    final hasPermission = await service.checkAndRequestPermission();
    if (!hasPermission || !mounted) {
      return;
    }

    final detected = await service.scanNewImagesWithOptions(
      respectAutoSetting: false,
      respectDailyLimit: false,
      forceRescan: true,
    );
    if (!mounted) {
      return;
    }

    if (detected.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('감지된 쿠폰 이미지가 없어요. 최근 갤러리 이미지를 확인해보세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final first = detected.first;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${detected.length}개의 후보를 찾았어요. 첫 번째 이미지를 등록 화면에서 열어요.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

    final savedCoupon = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CouponCreateScreen(preloadedImage: first.file),
      ),
    );
    if (savedCoupon != null) {
      await ScannedImageStore.addRegisteredHash(first.imageHash);
    }
  }

  Future<void> _resetGalleryScanState() async {
    await GalleryScanService().resetScanState();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('갤러리 감지 이력과 스캔 기준을 초기화했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _triggerCrashlyticsTestCrash() {
    final analytics = AnalyticsService();
    if (!analytics.isAvailable) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Crashlytics 초기화 실패: ${analytics.initError ?? 'ENABLE_FIREBASE 설정을 확인해주세요.'}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    analytics.crashForTesting();
  }

  Future<void> _handleAutoScanToggle(bool value) async {
    if (value) {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) {
        return;
      }
      final guideShown =
          prefs.getBool(GalleryScanService.autoScanGuideShownKey) ?? false;
      if (!guideShown) {
        final shouldContinue = await _showPermissionGuideDialog(context);
        if (shouldContinue != true || !mounted) {
          return;
        }
        await prefs.setBool(GalleryScanService.autoScanGuideShownKey, true);
      }

      final hasPermission =
          await GalleryScanService().checkAndRequestPermission();
      if (!hasPermission || !mounted) {
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(GalleryScanService.autoScanEnabledKey, value);
    if (!mounted) {
      return;
    }
    setState(() {
      _autoScanEnabled = value;
    });
  }

  Future<bool?> _showPermissionGuideDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/icon/4.png', width: 60, height: 60),
                const SizedBox(height: 16),
                const Text(
                  '쿠왕이 쿠폰을 찾아드릴게요!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '갤러리에 저장된 쿠폰·기프티콘을\n자동으로 찾아서 알려드려요.\n\n• 이미지는 기기 안에서만 분석해요\n• 수집하거나 전송하지 않아요\n• 설정에서 언제든 끌 수 있어요',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          '지금은 괜찮아요',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF64CAFA),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          '허용하기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
                  color: const Color(0xFFEDF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD0ECFF),
                    width: 1,
                  ),
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
                        _CouWangSwitch(
                          value: _masterEnabled,
                          onChanged: _handleMasterToggle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFCCE8F8),
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
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD0ECFF),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '갤러리 자동 감지',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '갤러리에서 쿠폰을 자동으로 찾아드려요.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _CouWangSwitch(
                          value: _autoScanEnabled,
                          onChanged: _handleAutoScanToggle,
                        ),
                      ],
                    ),
                    if (_autoScanEnabled) ...[
                      const SizedBox(height: 12),
                      const Divider(
                        height: 1,
                        color: Color(0xFFCCE8F8),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• 이미지는 기기 안에서만 분석돼요\n• 서버로 전송되지 않아요\n• 앱 실행 시 새로운 쿠폰을 찾아드려요',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                          height: 1.8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!kReleaseMode || _internalTestToolsEnabled) ...[
                const SizedBox(height: 500),
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
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _addVirtualMemberships,
                    icon: const Icon(
                      Icons.card_membership_outlined,
                      size: 20,
                      color: Color(0xFF555555),
                    ),
                    label: const Text(
                      AppStrings.settingsTestMemberships,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _triggerCrashlyticsTestCrash,
                    icon: const Icon(
                      Icons.bug_report_outlined,
                      size: 20,
                      color: Color(0xFF555555),
                    ),
                    label: const Text(
                      'Crashlytics 테스트 크래시 발생',
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
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _runGalleryScanTest,
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      size: 20,
                      color: Color(0xFF555555),
                    ),
                    label: const Text(
                      AppStrings.settingsTestGalleryScan,
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
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _resetGalleryScanState,
                    icon: const Icon(
                      Icons.restart_alt_outlined,
                      size: 20,
                      color: Color(0xFF555555),
                    ),
                    label: const Text(
                      AppStrings.settingsTestGalleryReset,
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
              ],
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
          _CouWangSwitch(
            value: enabled ? value : false,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _CouWangSwitch extends StatelessWidget {
  const _CouWangSwitch({
    required this.value,
    this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null;
    final trackColor =
        value && isEnabled ? const Color(0xFF64CAFA) : const Color(0xFFCCCCCC);

    return GestureDetector(
      onTap: isEnabled ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          color: trackColor,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(2.5),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
