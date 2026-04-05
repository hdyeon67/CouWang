import 'package:flutter/material.dart';

import '../core/resources/app_strings.dart';
import 'router.dart';
import 'theme.dart';

class CouWangApp extends StatelessWidget {
  const CouWangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: CouWangTheme.light(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.resolveAppStartRoute(),
    );
  }
}
