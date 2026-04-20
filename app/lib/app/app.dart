import 'package:flutter/material.dart';

import '../core/resources/app_strings.dart';
import '../services/notification_service.dart';
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.resolveAppStartRoute(),
    );
  }
}
