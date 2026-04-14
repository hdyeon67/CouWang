import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/widgets/app_tab_scaffold.dart';
import '../../../../core/widgets/empty_state_mascot.dart';
import '../../../../repositories/membership_repository.dart';
import 'membership_detail_screen.dart';

class MembershipListScreen extends StatefulWidget {
  const MembershipListScreen({super.key});

  @override
  State<MembershipListScreen> createState() => _MembershipListScreenState();
}

class _MembershipListScreenState extends State<MembershipListScreen> {
  void _showPlaceholderMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<MembershipCardItem> get _memberships {
    return MembershipRepository.getAll()
        .map(MembershipCardItem.fromDetail)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final memberships = _memberships;
    final hasMemberships = memberships.isNotEmpty;

    return AppTabScaffold(
      currentTab: BottomTabItem.membership,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingAddButton(
        onPressed: () {
          Navigator.of(context)
              .pushNamed(AppRouter.createMembership)
              .then((_) {
            if (mounted) {
              setState(() {});
            }
          });
        },
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 190),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MembershipHeaderSection(),
              if (hasMemberships) ...[
                const SizedBox(height: 24),
                MembershipCardList(
                  memberships: memberships,
                  onMembershipTap: (membership) {
                    Navigator.of(context)
                        .pushNamed(
                          AppRouter.membershipDetail,
                          arguments: membership.detail,
                        )
                        .then((_) {
                      if (mounted) {
                        setState(() {});
                      }
                    });
                  },
                  onMenuTap: (membership) {
                    _showPlaceholderMessage(
                      context,
                      '${membership.name} 메뉴는 수정·삭제 같은 빠른 관리 액션용으로 둘 예정입니다.',
                    );
                  },
                ),
              ] else
                const MembershipEmptyState(),
            ],
          ),
        ),
      ),
    );
  }
}

class MembershipHeaderSection extends StatelessWidget {
  const MembershipHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.membershipTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 10),
        MembershipInfoText(
          text: AppStrings.membershipGuide,
        ),
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
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Color(0xFF9E9E9E),
        height: 1.5,
      ),
    );
  }
}

class MembershipEmptyState extends StatelessWidget {
  const MembershipEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.52,
      child: const Center(
        child: EmptyStateMascot(
          message: AppStrings.membershipEmpty,
          imageSize: 100,
        ),
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < memberships.length; index++)
            MembershipCard(
              membership: memberships[index],
              isFirst: index == 0,
              isLast: index == memberships.length - 1,
              onTap: () => onMembershipTap(memberships[index]),
              onMenuTap: () => onMenuTap(memberships[index]),
            ),
        ],
      ),
    );
  }
}

class MembershipCard extends StatelessWidget {
  const MembershipCard({
    super.key,
    required this.membership,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onMenuTap,
  });

  final MembershipCardItem membership;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              height: 72,
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: membership.barColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: membership.iconBgColor,
                    ),
                    child: Icon(
                      membership.icon,
                      size: 22,
                      color: membership.iconColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      membership.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onMenuTap,
                    padding: const EdgeInsets.only(right: 20),
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.menu,
                      size: 22,
                      color: Color(0xFFBDBDBD),
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF0F0F0),
                indent: 20,
                endIndent: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class MembershipCardItem {
  const MembershipCardItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.cardNumber,
    required this.barColor,
    required this.iconColor,
    required this.iconBgColor,
    required this.icon,
    required this.detail,
  });

  final String id;
  final String name;
  final String brand;
  final String cardNumber;
  final Color barColor;
  final Color iconColor;
  final Color iconBgColor;
  final IconData icon;
  final MembershipDetailModel detail;

  factory MembershipCardItem.fromDetail(MembershipDetailModel membership) {
    final style = _MembershipVisualStyle.fromBrand(membership.brand);
    return MembershipCardItem(
      id: membership.id,
      name: membership.name,
      brand: membership.brand,
      cardNumber: membership.cardNumber,
      barColor: style.barColor,
      iconColor: style.iconColor,
      iconBgColor: style.iconBgColor,
      icon: style.icon,
      detail: membership,
    );
  }
}

class _MembershipVisualStyle {
  const _MembershipVisualStyle({
    required this.barColor,
    required this.iconColor,
    required this.iconBgColor,
    required this.icon,
  });

  final Color barColor;
  final Color iconColor;
  final Color iconBgColor;
  final IconData icon;

  factory _MembershipVisualStyle.fromBrand(String brand) {
    switch (brand) {
      case AppStrings.membershipPoint:
      case AppStrings.membershipCjOne:
        return const _MembershipVisualStyle(
          barColor: Color(0xFFE53935),
          iconColor: Color(0xFFE53935),
          iconBgColor: Color(0xFFFFEBEE),
          icon: Icons.star,
        );
      case AppStrings.categoryCafe:
      case AppStrings.brandStarbucks:
        return const _MembershipVisualStyle(
          barColor: Color(0xFF1B5E20),
          iconColor: Color(0xFF2E7D32),
          iconBgColor: Color(0xFFE8F5E9),
          icon: Icons.local_cafe_outlined,
        );
      case AppStrings.categoryBakery:
      case AppStrings.membershipHappyPoint:
        return const _MembershipVisualStyle(
          barColor: Color(0xFFE91E8C),
          iconColor: Color(0xFFE91E8C),
          iconBgColor: Color(0xFFFCE4EC),
          icon: Icons.favorite,
        );
      default:
        return const _MembershipVisualStyle(
          barColor: Color(0xFF212121),
          iconColor: Color(0xFF424242),
          iconBgColor: Color(0xFFF5F5F5),
          icon: Icons.business,
        );
    }
  }
}
