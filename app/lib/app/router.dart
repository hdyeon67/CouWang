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

// Navigator 라우트 문자열과 실제 화면 매핑을 한곳에 모은다.
//
// 알림 진입, 상세 화면 복귀, 탭 교체가 서로 다른 파일에 흩어지지 않도록
// 라우팅 규칙을 중앙화한다.
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

  // named route가 들어왔을 때 어떤 화면을 띄울지 결정한다.
  //
  // route name과 arguments를 받아 타입에 맞는 화면으로 연결한다.
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

  // 앱 시작 시 첫 진입 라우트를 반환한다.
  //
  // 현재는 스플래시를 먼저 거치지만, 추후 로그인/온보딩 분기가 생기면 여기서
  // 앱 시작 경로를 한곳에서 바꿀 수 있다.
  static String resolveAppStartRoute() {
    return splash;
  }

  // iOS 감성에 맞춘 Cupertino 전환 라우트를 공통 생성한다.
  static PageRoute<dynamic> _pageRoute(Widget child) {
    return CupertinoPageRoute<void>(builder: (_) => child);
  }

  // 하단 탭 전환 시 기존 스택을 비우고 새 탭을 루트처럼 교체한다.
  //
  // 탭 화면은 보통 "뒤로가기를 누르면 이전 탭 히스토리"보다 "현재 탭 기준 루트"
  // 로 동작하는 편이 자연스러워서 pushAndRemoveUntil을 사용한다.
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
