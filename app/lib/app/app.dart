// 앱 전역 lifecycle과 navigator를 묶는 최상위 위젯.
//
// 알림 탭 복구, 갤러리 캐시 정리, locale/theme 연결처럼 화면 바깥의 공통 동작을
// 여기서 처리한다.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/resources/app_strings.dart';
import '../services/notification_service.dart';
import '../services/gallery_scan_service.dart';
import 'app_navigator.dart';
import 'router.dart';
import 'theme.dart';

// 앱 전체를 감싸는 최상위 StatefulWidget이다.
//
// 화면별 상태가 아니라 앱 전역 lifecycle과 navigatorKey를 함께 관리한다.
class CouWangApp extends StatefulWidget {
  const CouWangApp({super.key});

  @override
  State<CouWangApp> createState() => _CouWangAppState();
}

// 앱 resumed/detached lifecycle에 맞춰 공통 후처리를 관리한다.
class _CouWangAppState extends State<CouWangApp> with WidgetsBindingObserver {
  @override
  // initState에서는 observer 등록과 앱 런치 직후 1회성 후처리를 연결한다.
  //
  // build보다 먼저 한 번만 호출되므로 알림 payload 복구처럼 초기 진입 로직을
  // 두기에 적합하다.
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 앱 런치 직후에는 navigator가 준비된 뒤에만 pending payload를 처리한다.
      NotificationService().handlePendingLaunchPayload();
    });
  }

  @override
  // dispose에서는 observer와 캐시성 리소스를 정리한다.
  //
  // initState에서 등록한 observer와 종료 시점 정리 대상 리소스를 함께 해제한다.
  void dispose() {
    GalleryScanService().dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  // 앱이 background/foreground를 오갈 때 공통 흐름을 이어 붙인다.
  //
  // 예를 들어 알림 탭으로 상세 화면에 들어간 뒤 resumed 되었을 때 어느 화면으로
  // 돌아갈지 여기서 결정한다.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // 종료 시점에 ML Kit 리소스를 정리한다.
      GalleryScanService().dispose();
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
  // build는 현재 전역 설정을 기준으로 MaterialApp 트리를 구성한다.
  //
  // theme, locale, route generator처럼 앱 전역 의존성이 한 번에 보이는 자리다.
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
