import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../constants/app_spacing.dart';

enum BottomTabItem { membership, home, settings }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: appBar,
      body: body,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      extendBody: true,
      bottomNavigationBar: BottomTabBarContainer(
        selectedTab: currentTab,
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
    );
  }
}

class BottomTabBarContainer extends StatelessWidget {
  const BottomTabBarContainer({
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
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: FloatingTabCard(
          selectedTab: selectedTab,
          onMembershipTabClick: onMembershipTabClick,
          onHomeTabClick: onHomeTabClick,
          onSettingsTabClick: onSettingsTabClick,
        ),
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14162033),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: BottomTabNavItem(
              label: '멤버십',
              icon: CupertinoIcons.creditcard,
              isActive: selectedTab == BottomTabItem.membership,
              onTap: onMembershipTabClick,
            ),
          ),
          Expanded(
            child: BottomTabNavItem(
              label: '홈',
              icon: CupertinoIcons.house_fill,
              isActive: selectedTab == BottomTabItem.home,
              onTap: onHomeTabClick,
            ),
          ),
          Expanded(
            child: BottomTabNavItem(
              label: '설정',
              icon: CupertinoIcons.gear_alt_fill,
              isActive: selectedTab == BottomTabItem.settings,
              onTap: onSettingsTabClick,
            ),
          ),
        ],
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    final foreground = isActive ? const Color(0xFF64CAFA) : const Color(0xFF8B929E);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFE6F7FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: foreground,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive ? const Color(0xFF64CAFA) : const Color(0xFF8B929E),
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingAddButton extends StatelessWidget {
  const FloatingAddButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: const Color(0xFF64CAFA),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(CupertinoIcons.add, size: 28),
      ),
    );
  }
}
