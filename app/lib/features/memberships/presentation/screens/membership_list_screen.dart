import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_tab_scaffold.dart';

class MembershipListScreen extends StatelessWidget {
  const MembershipListScreen({super.key});

  static const List<MembershipCardItem> _memberships = [
    MembershipCardItem(
      brand: 'CJ ONE',
      note: '올리브영, CGV, 뚜레쥬르 적립에 사용하는 멤버십',
      accentColor: Color(0xFFE8564D),
      icon: CupertinoIcons.star_fill,
    ),
    MembershipCardItem(
      brand: '스타벅스',
      note: '사이렌 오더와 별 적립에 사용하는 멤버십',
      accentColor: Color(0xFF3CA66B),
      icon: CupertinoIcons.bolt_fill,
    ),
    MembershipCardItem(
      brand: '해피포인트',
      note: '파리바게뜨, 배스킨라빈스 적립/할인 멤버십',
      accentColor: Color(0xFFFF6FAE),
      icon: CupertinoIcons.heart_fill,
    ),
    MembershipCardItem(
      brand: '신세계 포인트',
      note: '이마트와 신세계 계열 브랜드에서 사용하는 포인트',
      accentColor: Color(0xFF30333A),
      icon: CupertinoIcons.bag_fill,
    ),
  ];

  void _showPlaceholderMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppTabScaffold(
      currentTab: BottomTabItem.membership,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 8),
        child: FloatingAddButton(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRouter.createMembership);
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
            160,
          ),
          children: [
            MembershipHeaderSection(
              onEditClick: () {
                _showPlaceholderMessage(
                  context,
                  '멤버십 편집 흐름은 다음 단계에서 구현합니다.',
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            MembershipCardList(
              memberships: _memberships,
              onMembershipTap: (_) {
                Navigator.of(context).pushNamed(AppRouter.membershipDetail);
              },
              onMenuTap: (membership) {
                _showPlaceholderMessage(
                  context,
                  '${membership.brand} 멤버십 액션은 다음 단계에서 구현합니다.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MembershipHeaderSection extends StatelessWidget {
  const MembershipHeaderSection({
    super.key,
    required this.onEditClick,
  });

  final VoidCallback onEditClick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '나의 멤버십',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1B1F28),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const MembershipInfoText(
          text: '멤버십 바코드를 등록해놓으면 쿠폰 사용과 함께 적립·할인을 받을 수 있어요',
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class MembershipInfoText extends StatelessWidget {
  const MembershipInfoText({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF64CAFA),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class MembershipCardList extends StatelessWidget {
  const MembershipCardList({
    super.key,
    required this.memberships,
    required this.onMembershipTap,
    required this.onMenuTap,
  });

  final List<MembershipCardItem> memberships;
  final ValueChanged<MembershipCardItem> onMembershipTap;
  final ValueChanged<MembershipCardItem> onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final membership in memberships) ...[
          MembershipCard(
            membership: membership,
            onTap: () => onMembershipTap(membership),
            onMenuTap: () => onMenuTap(membership),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class MembershipCard extends StatelessWidget {
  const MembershipCard({
    super.key,
    required this.membership,
    required this.onTap,
    required this.onMenuTap,
  });

  final MembershipCardItem membership;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08162033),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 96,
                decoration: BoxDecoration(
                  color: membership.accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppSpacing.cardRadius),
                    right: Radius.circular(8),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: membership.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          membership.icon,
                          color: membership.accentColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              membership.brand,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF1B1F28),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              membership.note,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF667085),
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        onPressed: onMenuTap,
                        icon: const Icon(
                          CupertinoIcons.line_horizontal_3_decrease,
                          color: Color(0xFF98A2B3),
                        ),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MembershipCardItem {
  const MembershipCardItem({
    required this.brand,
    required this.note,
    required this.accentColor,
    required this.icon,
  });

  final String brand;
  final String note;
  final Color accentColor;
  final IconData icon;
}
