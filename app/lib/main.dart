// 앱 전체 초기화 순서를 담당하는 진입점.
//
// 데이터베이스, 로컬 설정, 저장소, 알림, 광고, Firebase를 먼저 준비한 뒤
// 실제 UI를 띄운다. 인수인계 시 가장 먼저 읽으면 앱의 시작 순서를 파악하기 쉽다.
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

// 앱 실행 전에 필요한 초기화 작업을 순서대로 수행한다.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 쿠왕은 세로 사용 흐름을 전제로 설계되어 있어 portraitUp만 허용한다.
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
