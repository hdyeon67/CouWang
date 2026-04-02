import 'package:flutter/cupertino.dart';

import '../core/widgets/app_tab_scaffold.dart';
import '../features/coupons/presentation/screens/coupon_create_screen.dart';
import '../features/coupons/presentation/screens/coupon_detail_screen.dart';
import '../features/coupons/presentation/screens/coupon_list_screen.dart';
import '../features/memberships/presentation/screens/membership_create_screen.dart';
import '../features/memberships/presentation/screens/membership_detail_screen.dart';
import '../features/memberships/presentation/screens/membership_list_screen.dart';
import '../features/notifications/presentation/screens/notification_list_screen.dart';
import '../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  static const home = '/';
  static const createCoupon = '/coupons/create';
  static const couponDetail = '/coupons/detail';
  static const membershipList = '/memberships';
  static const createMembership = '/memberships/create';
  static const membershipDetail = '/memberships/detail';
  static const notificationList = '/notifications';
  static const notificationSettings = '/notifications/settings';
  static const settingsRoute = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case createCoupon:
        return _pageRoute(const CouponCreateScreen());
      case couponDetail:
        final coupon = settings.arguments;
        return _pageRoute(
          coupon is CouponDetailModel
              ? CouponDetailScreen(coupon: coupon)
              : const CouponDetailScreen(),
        );
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

  static String resolveAppStartRoute() {
    return home;
  }

  static PageRoute<dynamic> _pageRoute(Widget child) {
    return CupertinoPageRoute<void>(builder: (_) => child);
  }

  static void replaceWithTabRoute(BuildContext context, BottomTabItem tab) {
    Widget target;

    switch (tab) {
      case BottomTabItem.membership:
        target = const MembershipListScreen();
        break;
      case BottomTabItem.home:
        target = const HomeDashboardScreen();
        break;
      case BottomTabItem.settings:
        target = const SettingsScreen();
        break;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => target,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}
