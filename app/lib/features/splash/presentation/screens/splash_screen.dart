import 'package:flutter/material.dart';

import '../../../../core/resources/app_strings.dart';
import '../../../../core/services/app_permission_service.dart';
import '../../../../services/notification_service.dart';
import '../../../coupons/presentation/screens/coupon_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startIntroFlow();
    });
  }

  Future<void> _startIntroFlow() async {
    _controller.forward();
    await Future.wait<void>([
      Future<void>.delayed(const Duration(milliseconds: 2200)),
      AppPermissionService.requestStartupPermissions(context),
    ]);

    if (!mounted) {
      return;
    }

    if (NotificationService().launchedFromNotification) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const HomeDashboardScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = MediaQuery.of(context).size.width * 0.55;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FBFF),
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: const Color(0xFFF5FBFF)),
            Center(
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 140,
                            height: 140,
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -14,
                          child: Transform.translate(
                            offset: const Offset(0, -12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF64CAFA),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.stars_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    AppStrings.splashGreeting,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      AppStrings.splashTitle,
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64CAFA),
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        width: barWidth,
                        height: 4,
                        child: Stack(
                          children: [
                            Container(
                              width: barWidth,
                              height: 4,
                              color: const Color(0xFFDDE8F0),
                            ),
                            Container(
                              width: barWidth * _progressAnimation.value,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF64CAFA),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
