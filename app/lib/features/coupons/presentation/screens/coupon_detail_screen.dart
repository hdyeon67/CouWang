import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_spacing.dart';

class CouponDetailScreen extends StatelessWidget {
  const CouponDetailScreen({
    super.key,
    this.coupon = const CouponDetailModel(
      brand: '스타벅스',
      avatarText: 'S',
      title: '아메리카노 Tall',
      status: CouponDetailStatus.available,
      dDay: 12,
      expiryDate: '2026-03-25',
      couponType: '바코드',
      createdAt: '2026-03-04',
      couponNumber: '1234-5678-9012',
      memo: '매장 내 사용 가능',
    ),
  });

  final CouponDetailModel coupon;

  @override
  Widget build(BuildContext context) {
    final badge = _statusStyle(coupon.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('쿠폰 상세'),
        actions: [
          IconButton(
            onPressed: () {
              _showMessage(context, '추가 관리 메뉴는 다음 단계에서 연결합니다.');
            },
            icon: const Icon(CupertinoIcons.ellipsis),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showMessage(context, '편집 화면은 다음 단계에서 연결합니다.');
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(color: Color(0xFFCFE0FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    foregroundColor: const Color(0xFF2F6BFF),
                  ),
                  child: const Text('편집'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRouter.membershipDetail);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(color: Color(0xFFE1E7F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    foregroundColor: const Color(0xFF516173),
                  ),
                  child: const Text('멤버십'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _showRedeemConfirmDialog(context),
                  child: const Text('사용 완료 처리'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _HeroCouponCard(
              coupon: coupon,
              badge: badge,
            ),
            const SizedBox(height: AppSpacing.lg),
            _BarcodeCard(couponNumber: coupon.couponNumber),
            const SizedBox(height: AppSpacing.lg),
            _InfoSection(
              coupon: coupon,
              badgeLabel: badge.label,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ManagementSection(
              onEditTap: () {
                _showMessage(context, '쿠폰 수정 화면은 다음 단계에서 연결합니다.');
              },
              onMembershipTap: () {
                Navigator.of(context).pushNamed(AppRouter.membershipDetail);
              },
              onDeleteTap: () {
                _showDeleteConfirmDialog(context);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '만료 7일/1일 전 알림이 자동 설정됩니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: const Color(0xFF8A94A6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showRedeemConfirmDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14162033),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    CupertinoIcons.check_mark_circled,
                    color: Color(0xFF2F6BFF),
                    size: 30,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '사용 완료로 처리할까요?',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${coupon.brand} ${coupon.title}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF4B5563),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '처리하면 상태가 사용완료로 변경됩니다.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7B8798),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFFE1E7F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                          foregroundColor: const Color(0xFF6B7280),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        child: const Text('확인'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && context.mounted) {
      // Later, real redeem save logic can be connected here.
      _showMessage(context, '사용 완료 placeholder: 실제 저장은 다음 단계에서 연결합니다.');
    }
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('쿠폰을 삭제할까요?'),
          content: Text('${coupon.brand} ${coupon.title} 쿠폰이 목록에서 제거됩니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                '삭제',
                style: TextStyle(color: Color(0xFFB5475A)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      _showMessage(context, '쿠폰 삭제 placeholder: 실제 삭제는 다음 단계에서 연결합니다.');
    }
  }
}

class CouponDetailModel {
  const CouponDetailModel({
    required this.brand,
    required this.avatarText,
    required this.title,
    required this.status,
    required this.dDay,
    required this.expiryDate,
    required this.couponType,
    required this.createdAt,
    required this.couponNumber,
    this.memo,
  });

  final String brand;
  final String avatarText;
  final String title;
  final CouponDetailStatus status;
  final int? dDay;
  final String expiryDate;
  final String couponType;
  final String createdAt;
  final String couponNumber;
  final String? memo;
}

enum CouponDetailStatus {
  available,
  urgent,
  expired,
  redeemed,
}

class _HeroCouponCard extends StatelessWidget {
  const _HeroCouponCard({
    required this.coupon,
    required this.badge,
  });

  final CouponDetailModel coupon;
  final _StatusBadgeStyle badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE8ECF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A162033),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  coupon.avatarText,
                  style: const TextStyle(
                    color: Color(0xFF2F6BFF),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.brand,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6F7B8C),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${coupon.brand} ${coupon.title}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _StatusBadge(badge: badge),
              _DdayBadge(
                text: coupon.status == CouponDetailStatus.redeemed
                    ? '사용 완료'
                    : coupon.status == CouponDetailStatus.expired
                    ? '만료됨'
                    : 'D-${coupon.dDay}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            coupon.status == CouponDetailStatus.expired
                ? '만료일 ${coupon.expiryDate}'
                : '만료일 ${coupon.expiryDate}까지 사용할 수 있어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _BarcodeCard extends StatelessWidget {
  const _BarcodeCard({
    required this.couponNumber,
  });

  final String couponNumber;

  @override
  Widget build(BuildContext context) {
    final bars = [18, 34, 26, 42, 20, 38, 24, 40, 30, 18, 44, 26, 36, 22, 40];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars
                  .map(
                    (height) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 4,
                        height: height.toDouble(),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B26),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '쿠폰번호: $couponNumber',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: const Color(0xFF758195),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.coupon,
    required this.badgeLabel,
  });

  final CouponDetailModel coupon;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: Column(
        children: [
          _InfoRow(label: '브랜드', value: coupon.brand),
          _InfoRow(label: '만료일', value: coupon.expiryDate),
          _InfoRow(label: '유형', value: coupon.couponType),
          _InfoRow(label: '등록일', value: coupon.createdAt),
          _InfoRow(label: '상태', value: badgeLabel),
          if (coupon.memo != null && coupon.memo!.trim().isNotEmpty)
            _InfoRow(label: '메모', value: coupon.memo!),
        ],
      ),
    );
  }
}

class _ManagementSection extends StatelessWidget {
  const _ManagementSection({
    required this.onEditTap,
    required this.onMembershipTap,
    required this.onDeleteTap,
  });

  final VoidCallback onEditTap;
  final VoidCallback onMembershipTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '관리',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _ManagementActionTile(
            icon: CupertinoIcons.pencil,
            title: '쿠폰 수정',
            subtitle: '제목, 만료일, 메모를 다시 정리합니다',
            onTap: onEditTap,
          ),
          const _SectionDivider(),
          _ManagementActionTile(
            icon: CupertinoIcons.creditcard,
            title: '멤버십으로 이동',
            subtitle: '함께 보여줄 멤버십을 바로 확인합니다',
            onTap: onMembershipTap,
          ),
          const _SectionDivider(),
          _ManagementActionTile(
            icon: CupertinoIcons.delete,
            title: '쿠폰 삭제',
            subtitle: '더 이상 쓰지 않는 쿠폰을 정리합니다',
            destructive: true,
            onTap: onDeleteTap,
          ),
        ],
      ),
    );
  }
}

class _ManagementActionTile extends StatelessWidget {
  const _ManagementActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive
        ? const Color(0xFFB5475A)
        : const Color(0xFF1D2433);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: destructive
                    ? const Color(0xFFFFF1F3)
                    : const Color(0xFFF3F7FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: foreground, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: destructive
                  ? const Color(0xFFDB93A0)
                  : const Color(0xFF90A0B5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFEFF2F7),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8A94A6),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.badge,
  });

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

class _DdayBadge extends StatelessWidget {
  const _DdayBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF64748B),
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
    this.outlined = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool outlined;
}

_StatusBadgeStyle _statusStyle(CouponDetailStatus status) {
  switch (status) {
    case CouponDetailStatus.available:
      return const _StatusBadgeStyle(
        label: '사용가능',
        background: Color(0xFFEAF8F4),
        foreground: Color(0xFF167C64),
      );
    case CouponDetailStatus.urgent:
      return const _StatusBadgeStyle(
        label: '임박',
        background: Color(0xFFFFF1E6),
        foreground: Color(0xFFD97706),
      );
    case CouponDetailStatus.expired:
      return const _StatusBadgeStyle(
        label: '만료',
        background: Color(0xFFF2F4F7),
        foreground: Color(0xFF7B8594),
      );
    case CouponDetailStatus.redeemed:
      return const _StatusBadgeStyle(
        label: '사용완료',
        background: Color(0xFFF3F7FF),
        foreground: Color(0xFF2F6BFF),
        outlined: true,
      );
  }
}
