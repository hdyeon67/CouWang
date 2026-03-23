import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_spacing.dart';

class MembershipListScreen extends StatelessWidget {
  const MembershipListScreen({super.key});

  static const List<_MembershipCardItem> _memberships = [
    _MembershipCardItem(
      brand: '올리브영',
      avatarText: 'O',
      note: '계산 전에 빠르게 열어두는 멤버십',
      statusLabel: '자주 사용',
    ),
    _MembershipCardItem(
      brand: '스타벅스',
      avatarText: 'S',
      note: '적립 바코드 보관용',
      statusLabel: '적립 가능',
    ),
    _MembershipCardItem(
      brand: 'CU',
      avatarText: 'CU',
      note: '편의점 할인/적립',
      statusLabel: '즉시 제시',
    ),
    _MembershipCardItem(
      brand: 'GS25',
      avatarText: 'GS',
      note: '행사 확인용 멤버십',
      statusLabel: '준비 완료',
    ),
  ];

  void _showPlaceholderMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버십'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE8ECF4)),
            ),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.creditcard_fill,
                    color: Color(0xFF2F6BFF),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '계산대 앞에서 바로 꺼내는 멤버십 보관함',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '자주 쓰는 멤버십을 한곳에 모아 빠르게 보여주는 화면입니다.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 52,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.createMembership);
                    },
                    icon: const Icon(CupertinoIcons.add),
                    label: const Text('멤버십 추가'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showPlaceholderMessage(context, '멤버십 편집 흐름은 다음 단계에서 구현합니다.');
                    },
                    icon: const Icon(CupertinoIcons.pencil),
                    label: const Text('멤버십 편집'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '총 ${_memberships.length}개',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final membership in _memberships) ...[
            _MembershipCard(
              membership: membership,
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.membershipDetail);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _MembershipCardItem {
  const _MembershipCardItem({
    required this.brand,
    required this.avatarText,
    required this.note,
    required this.statusLabel,
  });

  final String brand;
  final String avatarText;
  final String note;
  final String statusLabel;
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.membership,
    required this.onTap,
  });

  final _MembershipCardItem membership;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F7FF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                membership.avatarText,
                style: const TextStyle(
                  color: Color(0xFF2F6BFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membership.brand,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    membership.note,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                membership.statusLabel,
                style: const TextStyle(
                  color: Color(0xFF2F6BFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
