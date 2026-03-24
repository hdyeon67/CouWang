import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/router.dart';
import '../../../../app/firebase_bootstrap.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/auth_service.dart';

enum AuthEntryStatus {
  checking,
  signedOut,
}

class AuthEntryScreen extends StatefulWidget {
  const AuthEntryScreen({super.key});

  @override
  State<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends State<AuthEntryScreen> {
  AuthEntryStatus _status = AuthEntryStatus.checking;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await FirebaseBootstrap.ensureInitialized();
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) {
      return;
    }

    if (AuthService.instance.currentUser != null) {
      await _moveToHome();
      return;
    }

    setState(() {
      _status = AuthEntryStatus.signedOut;
    });
  }

  Future<void> _moveToHome() async {
    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacementNamed(AppRouter.home);
  }

  void _showComingSoon(String provider) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$provider 로그인 연결은 다음 단계에서 붙일 예정이에요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _status = AuthEntryStatus.checking;
    });

    try {
      final credential = await AuthService.instance.signInWithGoogle();

      if (!mounted) {
        return;
      }

      if (credential?.user == null) {
        setState(() {
          _status = AuthEntryStatus.signedOut;
        });
        _showComingSoon('Google 로그인');
        return;
      }

      await _moveToHome();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = AuthEntryStatus.signedOut;
      });

      _showMessage(
        'Google 로그인에 실패했어요. Firebase Google 로그인 활성화와 SHA 설정을 확인해주세요.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFD),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                const Spacer(),
                const _MascotBadge(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  '쿠왕',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '쿠폰과 멤버십을 잊지 않도록 도와드릴게요',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (_status) {
                    AuthEntryStatus.checking => const _CheckingState(),
                    AuthEntryStatus.signedOut => _SignedOutState(
                        onGoogleTap: _handleGoogleLogin,
                        onKakaoTap: () => _showComingSoon('카카오'),
                        firebaseError: FirebaseBootstrap.initializationError,
                      ),
                  },
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MascotBadge extends StatelessWidget {
  const _MascotBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Image.asset(
          'assets/icon/app_icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _CheckingState extends StatelessWidget {
  const _CheckingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('checking'),
      children: const [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Color(0xFF64CAFA),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          '로그인 상태를 확인하고 있어요',
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState({
    required this.onGoogleTap,
    required this.onKakaoTap,
    this.firebaseError,
  });

  final VoidCallback onGoogleTap;
  final VoidCallback onKakaoTap;
  final Object? firebaseError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('signedOut'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '간편하게 시작해보세요',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '로그인하면 쿠폰과 멤버십을 내 기기에서 안전하게 관리할 수 있어요.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
              ),
              if (firebaseError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4ED),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Text(
                    'Firebase 초기화에 문제가 있어요. iOS 설정 파일과 Google 로그인 구성을 다시 확인해주세요.',
                    style: TextStyle(
                      color: Color(0xFF9A3412),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _LoginButton(
                label: 'Google로 시작하기',
                icon: CupertinoIcons.globe,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1D2433),
                borderColor: const Color(0xFFE5EAF2),
                onTap: onGoogleTap,
              ),
              const SizedBox(height: AppSpacing.sm),
              _LoginButton(
                label: '카카오로 시작하기',
                icon: CupertinoIcons.chat_bubble_2_fill,
                backgroundColor: const Color(0xFFFEE500),
                foregroundColor: const Color(0xFF1D1D1F),
                borderColor: const Color(0xFFFEE500),
                onTap: onKakaoTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
