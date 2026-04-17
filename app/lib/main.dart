import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/app.dart';
import 'repositories/coupon_repository.dart';
import 'repositories/membership_repository.dart';
import 'repositories/settings_repository.dart';
import 'services/local_database_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabaseService.instance.init();
  await SettingsRepository.initialize();
  await CouponRepository.initialize();
  await MembershipRepository.initialize();
  await NotificationService().init();
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await MobileAds.instance.initialize();
  }
  runApp(const CouWangApp());
}
