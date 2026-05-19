// 앱 전역 lifecycle과 navigator를 묶는 최상위 위젯.
//
// 알림 탭 복구, 갤러리 캐시 정리, locale/theme 연결처럼 화면 바깥의 공통 동작을
// 여기서 처리한다.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:photo_manager/photo_manager.dart';

import '../core/resources/app_strings.dart';
import '../services/notification_service.dart';
import '../services/gallery_scan_service.dart';
import 'app_navigator.dart';
import 'router.dart';
import 'theme.dart';

// 앱 전역 lifecycle과 MaterialApp 구성을 감싸는 최상위 위젯.
class CouWangApp extends StatefulWidget {
  const CouWangApp({super.key});

  @override
  State<CouWangApp> createState() => _CouWangAppState();
}

// CouWangAppState 관련 역할을 담당하는 클래스.
class _CouWangAppState extends State<CouWangApp> with WidgetsBindingObserver {
  @override
  // 화면 또는 객체가 처음 생성될 때 필요한 초기 설정을 수행한다.
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 앱 런치 직후에는 navigator가 준비된 뒤에만 pending payload를 처리한다.
      NotificationService().handlePendingLaunchPayload();
    });
  }

  @override
  // 사용이 끝난 리소스를 정리한다.
  void dispose() {
    GalleryScanService().dispose();
    PhotoManager.clearFileCache();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  // 앱 lifecycle 변화에 맞춰 후속 동작을 처리한다.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // photo_manager가 남긴 캐시와 ML Kit 리소스를 종료 시점에 정리한다.
      GalleryScanService().dispose();
      PhotoManager.clearFileCache();
    }
    if (state != AppLifecycleState.resumed) {
      return;
    }
    // resumed 시점에는 알림 탭 후속 처리와 상세 복귀 리셋을 함께 확인한다.
    NotificationService().handlePendingNotificationTap();
    if (!NotificationService().consumeNotificationDetailResumeReset()) {
      return;
    }
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRouter.home,
      (route) => false,
    );
  }

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: CouWangTheme.light(),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.resolveAppStartRoute(),
    );
  }
}
