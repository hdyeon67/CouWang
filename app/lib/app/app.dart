import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:photo_manager/photo_manager.dart';

import '../core/resources/app_strings.dart';
import '../services/notification_service.dart';
import '../services/gallery_scan_service.dart';
import 'app_navigator.dart';
import 'router.dart';
import 'theme.dart';

class CouWangApp extends StatefulWidget {
  const CouWangApp({super.key});

  @override
  State<CouWangApp> createState() => _CouWangAppState();
}

class _CouWangAppState extends State<CouWangApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().handlePendingLaunchPayload();
    });
  }

  @override
  void dispose() {
    GalleryScanService().dispose();
    PhotoManager.clearFileCache();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      GalleryScanService().dispose();
      PhotoManager.clearFileCache();
    }
    if (state != AppLifecycleState.resumed) {
      return;
    }
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
