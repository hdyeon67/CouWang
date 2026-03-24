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
      bottomNavigationBar: BottomTabBar(
        currentTab: currentTab,
        onMembershipTabClick: () {
          if (currentTab == BottomTabItem.membership) {
            return;
          }
          Navigator.of(context).pushReplacementNamed(AppRouter.membershipList);
        },
        onHomeTabClick: () {
          if (currentTab == BottomTabItem.home) {
            return;
          }
          Navigator.of(context).pushReplacementNamed(AppRouter.home);
        },
        onSettingsTabClick: () {
          if (currentTab == BottomTabItem.settings) {
            return;
          }
          Navigator.of(context).pushReplacementNamed(AppRouter.settingsRoute);
        },
      ),
    );
  }
}

class BottomTabBar extends StatelessWidget {
  const BottomTabBar({
    super.key,
    required this.currentTab,
    required this.onMembershipTabClick,
    required this.onHomeTabClick,
    required this.onSettingsTabClick,
  });

  final BottomTabItem currentTab;
  final VoidCallback onMembershipTabClick;
  final VoidCallback onHomeTabClick;
  final VoidCallback onSettingsTabClick;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 88,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08162033),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _BottomTabButton(
                label: '멤버십',
                icon: CupertinoIcons.creditcard,
                isActive: currentTab == BottomTabItem.membership,
                onTap: onMembershipTabClick,
              ),
            ),
            Expanded(
              child: _BottomTabButton(
                label: '홈',
                icon: CupertinoIcons.house_fill,
                isActive: currentTab == BottomTabItem.home,
                onTap: onHomeTabClick,
              ),
            ),
            Expanded(
              child: _BottomTabButton(
                label: '설정',
                icon: CupertinoIcons.gear_alt_fill,
                isActive: currentTab == BottomTabItem.settings,
                onTap: onSettingsTabClick,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTabButton extends StatelessWidget {
  const _BottomTabButton({
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
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE9F7FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
