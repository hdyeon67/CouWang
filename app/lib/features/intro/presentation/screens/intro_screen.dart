import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_spacing.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // For the MVP we always move to the main tab screen.
    // Later this can point to an AuthGateScreen route instead.
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushReplacementNamed(AppRouter.resolvePostIntroRoute());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _IntroSymbol(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                '쿠왕',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 36,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '만료 전에 쿠폰을 챙겨주는 서비스',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF667085),
                ),
              ),
              const Spacer(flex: 3),
              Text(
                '시작 중...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF8A94A6),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroSymbol extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      width: 136,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE6ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1B2A41),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 28,
            child: Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF1FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.paw_solid,
                color: Color(0xFF2F6BFF),
                size: 28,
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 22,
            child: _MiniCouponChip(
              icon: CupertinoIcons.ticket,
              rotation: -0.12,
            ),
          ),
          Positioned(
            right: 18,
            bottom: 22,
            child: _MiniCouponChip(
              icon: CupertinoIcons.tickets,
              rotation: 0.12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCouponChip extends StatelessWidget {
  const _MiniCouponChip({
    required this.icon,
    required this.rotation,
  });

  final IconData icon;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 38,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8E4FF)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF2F6BFF),
        ),
      ),
    );
  }
}
