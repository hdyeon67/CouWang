import 'package:flutter/cupertino.dart';

import '../features/coupons/presentation/screens/coupon_create_screen.dart';
import '../features/coupons/presentation/screens/coupon_detail_screen.dart';
import '../features/coupons/presentation/screens/coupon_list_screen.dart';
import '../features/intro/presentation/screens/intro_screen.dart';
import '../features/memberships/presentation/screens/membership_create_screen.dart';
import '../features/memberships/presentation/screens/membership_detail_screen.dart';
import '../features/memberships/presentation/screens/membership_list_screen.dart';
import '../features/notifications/presentation/screens/notification_list_screen.dart';
import '../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  static const intro = '/intro';
  static const home = '/';
  static const createCoupon = '/coupons/create';
  static const couponDetail = '/coupons/detail';
  static const membershipList = '/memberships';
  static const createMembership = '/memberships/create';
  static const membershipDetail = '/memberships/detail';
  static const notificationList = '/notifications';
  static const notificationSettings = '/notifications/settings';
  static const settingsRoute = '/settings';
  static const authGate = '/auth-gate';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case intro:
        return _pageRoute(const IntroScreen());
      case createCoupon:
        return _pageRoute(const CouponCreateScreen());
      case couponDetail:
        return _pageRoute(const CouponDetailScreen());
      case membershipList:
        return _pageRoute(const MembershipListScreen());
      case createMembership:
        return _pageRoute(const MembershipCreateScreen());
      case membershipDetail:
        return _pageRoute(const MembershipDetailScreen());
      case notificationList:
        return _pageRoute(const NotificationListScreen());
      case notificationSettings:
        return _pageRoute(const NotificationSettingsScreen());
      case settingsRoute:
        return _pageRoute(const SettingsScreen());
      case home:
      default:
        return _pageRoute(const HomeDashboardScreen());
    }
  }

  // MVP starts directly on the home tab.
  // Later, this can change to intro or authGate when server-driven
  // initialization or auth flow is added.
  static String resolveAppStartRoute() {
    return home;
  }

  // Later, this launch target can change from home -> authGate
  // without changing the intro screen itself.
  static String resolvePostIntroRoute() {
    return home;
  }

  static PageRoute<dynamic> _pageRoute(Widget child) {
    return CupertinoPageRoute<void>(builder: (_) => child);
  }
}
