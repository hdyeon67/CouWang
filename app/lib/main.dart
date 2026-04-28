import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/app.dart';
import 'repositories/coupon_repository.dart';
import 'repositories/membership_repository.dart';
import 'repositories/settings_repository.dart';
import 'services/analytics_service.dart';
import 'services/gallery_scan_service.dart';
import 'services/local_database_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await AnalyticsService().init();
  AnalyticsService().configureCrashReporting();
  await LocalDatabaseService.instance.init();
  await SettingsRepository.initialize();
  await CouponRepository.initialize();
  await MembershipRepository.initialize();
  await NotificationService().init();
  GalleryScanService().warmUp();
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await MobileAds.instance.initialize();
  }
  runApp(const CouWangApp());
}
