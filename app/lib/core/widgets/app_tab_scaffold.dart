// 홈/멤버십/설정 하단 탭을 공통으로 감싸는 스캐폴드.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/router.dart';
import '../resources/app_strings.dart';
import 'couwang_banner_ad.dart';

// BottomTabItem 상태 값을 정의하는 enum.
enum BottomTabItem { membership, home, settings }

// AppTabScaffold 관련 역할을 담당하는 클래스.
class AppTabScaffold extends StatelessWidget {
  const AppTabScaffold({
    super.key,
    required this.currentTab,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset,
  });

  final BottomTabItem currentTab;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool? resizeToAvoidBottomInset;

  static const double _bottomTabHeight = 76;
  static const double _adSpacingFromTab = 5;
  static const double _fabSpacingFromTab = 16;
  static const double _horizontalMargin = 20;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return PopScope(
      // 하단 탭 루트에서는 Android back 동작을 제어해
      // 홈에서는 앱 종료, 다른 탭에서는 홈 복귀로 맞춘다.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (currentTab == BottomTabItem.home) {
          SystemNavigator.pop();
          return;
        }
        AppRouter.replaceWithTabRoute(context, BottomTabItem.home);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: appBar,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: body),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomTabBarContainer(
                selectedTab: currentTab,
                bottomPadding: bottomInset +
                    CouWangBannerAd.height +
                    _adSpacingFromTab,
                onMembershipTabClick: () {
                  if (currentTab == BottomTabItem.membership) {
                    return;
                  }
                  AppRouter.replaceWithTabRoute(context, BottomTabItem.membership);
                },
                onHomeTabClick: () {
                  if (currentTab == BottomTabItem.home) {
                    return;
                  }
                  AppRouter.replaceWithTabRoute(context, BottomTabItem.home);
                },
                onSettingsTabClick: () {
                  if (currentTab == BottomTabItem.settings) {
                    return;
                  }
                  AppRouter.replaceWithTabRoute(context, BottomTabItem.settings);
                },
              ),
            ),
            if (floatingActionButton != null)
              Positioned(
                right: _horizontalMargin,
                bottom: bottomInset +
                    CouWangBannerAd.height +
                    _adSpacingFromTab +
                    _bottomTabHeight +
                    _fabSpacingFromTab,
                child: floatingActionButton!,
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset,
              child: const Center(
                child: CouWangBannerAd(),
              ),
            ),
          ],
        ),
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBody: true,
      ),
    );
  }
}

// BottomTabBarContainer 관련 역할을 담당하는 클래스.
class BottomTabBarContainer extends StatelessWidget {
  const BottomTabBarContainer({
    super.key,
    required this.selectedTab,
    required this.bottomPadding,
    required this.onMembershipTabClick,
    required this.onHomeTabClick,
    required this.onSettingsTabClick,
  });

  final BottomTabItem selectedTab;
  final double bottomPadding;
  final VoidCallback onMembershipTabClick;
  final VoidCallback onHomeTabClick;
  final VoidCallback onSettingsTabClick;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FloatingTabCard(
            selectedTab: selectedTab,
            onMembershipTabClick: onMembershipTabClick,
            onHomeTabClick: onHomeTabClick,
            onSettingsTabClick: onSettingsTabClick,
          ),
        ),
      ),
    );
  }
}

// FloatingTabCard 관련 역할을 담당하는 클래스.
class FloatingTabCard extends StatelessWidget {
  const FloatingTabCard({
    super.key,
    required this.selectedTab,
    required this.onMembershipTabClick,
    required this.onHomeTabClick,
    required this.onSettingsTabClick,
  });

  final BottomTabItem selectedTab;
  final VoidCallback onMembershipTabClick;
  final VoidCallback onHomeTabClick;
  final VoidCallback onSettingsTabClick;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: BottomTabNavItem(
                label: AppStrings.tabMembership,
                icon: Icons.credit_card_outlined,
                isActive: selectedTab == BottomTabItem.membership,
                onTap: onMembershipTabClick,
              ),
            ),
            Expanded(
              child: BottomTabNavItem(
                label: AppStrings.tabHome,
                icon: Icons.home_rounded,
                isActive: selectedTab == BottomTabItem.home,
                onTap: onHomeTabClick,
              ),
            ),
            Expanded(
              child: BottomTabNavItem(
                label: AppStrings.tabSettings,
                icon: Icons.settings_outlined,
                isActive: selectedTab == BottomTabItem.settings,
                onTap: onSettingsTabClick,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// BottomTabNavItem 관련 역할을 담당하는 클래스.
class BottomTabNavItem extends StatelessWidget {
  const BottomTabNavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    final foreground =
        isActive ? const Color(0xFF64CAFA) : const Color(0xFFBDBDBD);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SizedBox(
        height: double.infinity,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE8F7FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: foreground,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: foreground,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// FloatingAddButton 관련 역할을 담당하는 클래스.
class FloatingAddButton extends StatelessWidget {
  const FloatingAddButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: const Color(0xFF64CAFA),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
