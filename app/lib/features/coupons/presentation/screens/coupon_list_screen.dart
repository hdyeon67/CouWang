import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_spacing.dart';

class CouponListScreen extends StatefulWidget {
  const CouponListScreen({super.key});

  @override
  State<CouponListScreen> createState() => _CouponListScreenState();
}

class _CouponListScreenState extends State<CouponListScreen> {
  static const List<_CouponItem> _coupons = [
    _CouponItem(
      brand: '스타벅스',
      avatarText: 'S',
      title: '스타벅스 아메리카노 Tall',
      couponType: '바코드',
      dDay: 12,
      status: CouponStatus.available,
    ),
    _CouponItem(
      brand: 'CU',
      avatarText: 'CU',
      title: 'CU 5,000원권',
      couponType: '바코드',
      dDay: 2,
      status: CouponStatus.urgent,
    ),
    _CouponItem(
      brand: '올리브영',
      avatarText: 'O',
      title: '올리브영 10,000원권',
      couponType: 'QR',
      dDay: null,
      status: CouponStatus.redeemed,
    ),
    _CouponItem(
      brand: 'GS25',
      avatarText: 'GS',
      title: 'GS25 도시락 할인권',
      couponType: 'none',
      dDay: null,
      status: CouponStatus.expired,
    ),
    _CouponItem(
      brand: 'BBQ',
      avatarText: 'B',
      title: 'BBQ 5,000원 할인권',
      couponType: 'QR',
      dDay: 18,
      status: CouponStatus.available,
    ),
    _CouponItem(
      brand: '배스킨라빈스',
      avatarText: 'B',
      title: '배스킨라빈스 싱글킹',
      couponType: '바코드',
      dDay: 1,
      status: CouponStatus.urgent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(CupertinoIcons.line_horizontal_3),
          ),
        ),
        title: const Text('쿠왕'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.createCoupon);
            },
            icon: const Icon(CupertinoIcons.add),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          const _MonthlyReportBanner(),
          const SizedBox(height: AppSpacing.lg),
          _PrimaryActionCard(
            icon: CupertinoIcons.creditcard,
            title: '멤버십 리스트 보기',
            subtitle: '계산 전에 바로 꺼낼 수 있게 모아볼 수 있어요.',
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.membershipList);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: '쿠폰',
            trailingLabel: '쿠폰 추가',
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.createCoupon);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          for (final coupon in _coupons) ...[
            _CouponCard(coupon: coupon),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

enum CouponStatus {
  available,
  urgent,
  expired,
  redeemed,
}

class _CouponItem {
  const _CouponItem({
    required this.brand,
    required this.avatarText,
    required this.title,
    required this.couponType,
    required this.dDay,
    required this.status,
  });

  final String brand;
  final String avatarText;
  final String title;
  final String couponType;
  final int? dDay;
  final CouponStatus status;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailingLabel,
    required this.onTap,
  });

  final String title;
  final String trailingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Text(
            trailingLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2F6BFF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthlyReportBanner extends StatelessWidget {
  const _MonthlyReportBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F6BFF), Color(0xFF63A1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142F6BFF),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '이번 달 리포트',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '이번 달에 쿠폰으로 18,400원을 아꼈어요',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '31일까지 사용 안 하면 사라지는 쿠폰은 2개예요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            children: [
              Expanded(
                child: _ReportStat(
                  label: '사용 금액',
                  value: '18,400원',
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReportStat(
                  label: '사용 쿠폰',
                  value: '6개',
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReportStat(
                  label: '버려질 쿠폰',
                  value: '2개',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  const _ReportStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8ECF4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF2F6BFF)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: Color(0xFF8A94A6),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon});

  final _CouponItem coupon;

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(coupon.status);
    final progressValue = _progressValue(coupon);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(AppRouter.couponDetail);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE8ECF4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08162033),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandAvatar(
                  text: coupon.avatarText,
                  status: coupon.status,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF1D2433),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _subtitleText(coupon),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6F7B8C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusBadge(badge: badge),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 6,
                backgroundColor: const Color(0xFFF1F4F9),
                valueColor: AlwaysStoppedAnimation<Color>(badge.tint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleText(_CouponItem coupon) {
    if (coupon.status == CouponStatus.redeemed) {
      return '사용완료 · ${coupon.couponType}';
    }
    if (coupon.status == CouponStatus.expired) {
      return '만료됨 · ${coupon.couponType}';
    }

    return '만료 D-${coupon.dDay} · ${coupon.couponType}';
  }

  double _progressValue(_CouponItem coupon) {
    if (coupon.status == CouponStatus.redeemed) {
      return 1;
    }
    if (coupon.status == CouponStatus.expired) {
      return 0.18;
    }

    final dDay = coupon.dDay ?? 30;
    final normalized = 1 - (dDay / 20);
    return normalized.clamp(0.12, 0.96);
  }

  _StatusBadgeStyle _statusBadge(CouponStatus status) {
    switch (status) {
      case CouponStatus.available:
        return const _StatusBadgeStyle(
          label: '사용가능',
          background: Color(0xFFEAF8F4),
          foreground: Color(0xFF167C64),
          tint: Color(0xFF63C7B2),
        );
      case CouponStatus.urgent:
        return const _StatusBadgeStyle(
          label: '임박',
          background: Color(0xFFFFF1E6),
          foreground: Color(0xFFD97706),
          tint: Color(0xFFF2A766),
        );
      case CouponStatus.expired:
        return const _StatusBadgeStyle(
          label: '만료',
          background: Color(0xFFF2F4F7),
          foreground: Color(0xFF7B8594),
          tint: Color(0xFFB9C1CC),
        );
      case CouponStatus.redeemed:
        return const _StatusBadgeStyle(
          label: '사용완료',
          background: Color(0xFFF3F7FF),
          foreground: Color(0xFF2F6BFF),
          tint: Color(0xFF8FB2FF),
          outlined: true,
        );
    }
  }
}

class _BrandAvatar extends StatelessWidget {
  const _BrandAvatar({
    required this.text,
    required this.status,
  });

  final String text;
  final CouponStatus status;

  @override
  Widget build(BuildContext context) {
    final style = switch (status) {
      CouponStatus.available => const (
          background: Color(0xFFE9F2FF),
          foreground: Color(0xFF2F6BFF),
        ),
      CouponStatus.urgent => const (
          background: Color(0xFFFFF1E6),
          foreground: Color(0xFFD97706),
        ),
      CouponStatus.expired => const (
          background: Color(0xFFF2F4F7),
          foreground: Color(0xFF7B8594),
        ),
      CouponStatus.redeemed => const (
          background: Color(0xFFF3F7FF),
          foreground: Color(0xFF2F6BFF),
        ),
    };

    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        color: style.background,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: style.foreground,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.badge});

  final _StatusBadgeStyle badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: badge.background,
        borderRadius: BorderRadius.circular(999),
        border: badge.outlined
            ? Border.all(color: const Color(0xFFC7D8FF))
            : null,
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          color: badge.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusBadgeStyle {
  const _StatusBadgeStyle({
    required this.label,
    required this.background,
    required this.foreground,
    required this.tint,
    this.outlined = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color tint;
  final bool outlined;
}
