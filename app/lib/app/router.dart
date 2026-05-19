// 앱 전체 라우트 이름과 화면 전환 진입점을 관리한다.
//
// 문자열 경로를 한곳에 모아둬서 알림 탭, 상세 복귀, 하단 탭 교체가 같은 기준으로
// 움직이도록 한다.
import 'package:flutter/cupertino.dart';

import '../core/widgets/app_tab_scaffold.dart';
import '../features/coupons/presentation/screens/coupon_create_screen.dart';
import '../features/coupons/presentation/screens/coupon_detail_screen.dart';
import '../features/coupons/presentation/screens/coupon_list_screen.dart';
import '../features/memberships/presentation/screens/membership_create_screen.dart';
import '../features/memberships/presentation/screens/membership_detail_screen.dart';
import '../features/memberships/presentation/screens/membership_list_screen.dart';
import '../features/notifications/presentation/screens/notification_list_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';

// 앱 라우트 이름과 화면 전환 경로를 관리하는 클래스.
class AppRouter {
  static const home = '/';
  static const splash = '/splash';
  static const createCoupon = '/coupons/create';
  static const couponDetail = '/coupons/detail';
  static const membershipList = '/memberships';
  static const createMembership = '/memberships/create';
  static const membershipDetail = '/memberships/detail';
  static const notificationList = '/notifications';
  static const settingsRoute = '/settings';

  // UI 이벤트 진입점 역할을 한다.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _pageRoute(const SplashScreen());
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
        final membership = settings.arguments;
        return _pageRoute(
          membership is MembershipDetailModel
              ? MembershipDetailScreen(membership: membership)
              : const MembershipDetailScreen(),
        );
      case notificationList:
        return _pageRoute(const NotificationListScreen());
      case settingsRoute:
        return _pageRoute(const SettingsScreen());
      case home:
      default:
        return _pageRoute(const HomeDashboardScreen());
    }
  }

  // 현재 맥락에서 사용할 값을 계산하거나 선택한다.
  static String resolveAppStartRoute() {
    return splash;
  }

  // pageRoute 관련 처리를 수행한다.
  static PageRoute<dynamic> _pageRoute(Widget child) {
    return CupertinoPageRoute<void>(builder: (_) => child);
  }

  // replaceWithTabRoute 관련 처리를 수행한다.
  static void replaceWithTabRoute(BuildContext context, BottomTabItem tab) {
    // 하단 탭은 뒤로가기 스택 누적보다 "현재 탭을 새 루트로 교체"하는 쪽이
    // 사용자 경험과 상태 관리가 단순하다.
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

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => target,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }
}
