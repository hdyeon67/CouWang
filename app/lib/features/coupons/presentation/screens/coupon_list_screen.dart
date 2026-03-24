import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_tab_scaffold.dart';

enum HomeCouponSortType { expiry, brand }

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    super.key,
    this.onCouponClick,
    this.onFabClick,
  });

  final ValueChanged<String>? onCouponClick;
  final VoidCallback? onFabClick;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  static const List<HomeCouponItem> _couponList = [
    HomeCouponItem(
      id: 'coupon_001',
      brand: '스타벅스',
      thumbnailLabel: 'S',
      title: '스타벅스 카페 아메리카노 Tall',
      expiryText: '유효기간: 오늘까지',
      dDay: 0,
      amountLabel: '4,500원',
      thumbnailColor: Color(0xFFF4EEE7),
    ),
    HomeCouponItem(
      id: 'coupon_002',
      brand: '배스킨라빈스',
      thumbnailLabel: 'BR',
      title: '배스킨라빈스 파인트 교환권',
      expiryText: '유효기간: 2026.03.25',
      dDay: 2,
      amountLabel: '9,800원',
      thumbnailColor: Color(0xFFFFF1E8),
    ),
    HomeCouponItem(
      id: 'coupon_003',
      brand: '도미노피자',
      thumbnailLabel: 'D',
      title: '도미노피자 포테이토(L) 교환권',
      expiryText: '유효기간: 2026.03.26',
      dDay: 3,
      amountLabel: '28,900원',
      thumbnailColor: Color(0xFFFFF3E8),
    ),
    HomeCouponItem(
      id: 'coupon_004',
      brand: 'ABC마트',
      thumbnailLabel: 'A',
      title: 'ABC마트 1만원 디지털 상품권',
      expiryText: '유효기간: 2026.03.30',
      dDay: 7,
      amountLabel: '10,000원',
      thumbnailColor: Color(0xFFF1F3F6),
    ),
    HomeCouponItem(
      id: 'coupon_005',
      brand: '올리브영',
      thumbnailLabel: 'O',
      title: '올리브영 10,000원 할인권',
      expiryText: '유효기간: 2026.04.02',
      dDay: 10,
      amountLabel: '10,000원',
      thumbnailColor: Color(0xFFF4F7EB),
    ),
  ];

  static const double _fabDownOffset = 8;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  HomeCouponSortType _sortType = HomeCouponSortType.expiry;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HomeCouponItem> get _sortedCouponList {
    final items = [..._couponList];

    switch (_sortType) {
      case HomeCouponSortType.expiry:
        items.sort((a, b) => a.dDay.compareTo(b.dDay));
        break;
      case HomeCouponSortType.brand:
        items.sort((a, b) => a.brand.compareTo(b.brand));
        break;
    }

    return items;
  }

  List<HomeCouponItem> get _filteredCouponList {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _sortedCouponList;
    }

    return _sortedCouponList.where((coupon) {
      return coupon.title.toLowerCase().contains(query);
    }).toList();
  }

  void _handleCouponClick(HomeCouponItem coupon) {
    if (widget.onCouponClick != null) {
      widget.onCouponClick!(coupon.id);
      return;
    }

    Navigator.of(context).pushNamed(AppRouter.couponDetail);
  }

  void _handleFabClick() {
    if (widget.onFabClick != null) {
      widget.onFabClick!.call();
      return;
    }

    Navigator.of(context).pushNamed(AppRouter.createCoupon);
  }

  @override
  Widget build(BuildContext context) {
    return AppTabScaffold(
      currentTab: BottomTabItem.home,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Transform.translate(
        offset: const Offset(0, _fabDownOffset),
        child: FloatingAddButton(onPressed: _handleFabClick),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            220,
          ),
          children: [
            TopMascotHeader(
              onNotificationClick: () {
                Navigator.of(context).pushNamed(AppRouter.notificationList);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            const SavingSpeechBubbleCard(
              highlightedAmount: '42,500원',
              prefix: '이번 달 쿠폰으로 ',
              suffix: ' 아꼈다 멍!',
            ),
            const SizedBox(height: AppSpacing.xl),
            CouponSectionHeader(
              title: '내 쿠폰함',
              sortType: _sortType,
              onSortChanged: (value) {
                setState(() {
                  _sortType = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            CouponSearchField(controller: _searchController),
            const SizedBox(height: AppSpacing.md),
            CouponListSection(
              coupons: _filteredCouponList,
              onCouponClick: _handleCouponClick,
            ),
          ],
        ),
      ),
    );
  }
}

class CouponListScreen extends StatelessWidget {
  const CouponListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeDashboardScreen();
  }
}

class HomeCouponItem {
  const HomeCouponItem({
    required this.id,
    required this.brand,
    required this.thumbnailLabel,
    required this.title,
    required this.expiryText,
    required this.dDay,
    required this.amountLabel,
    required this.thumbnailColor,
  });

  final String id;
  final String brand;
  final String thumbnailLabel;
  final String title;
  final String expiryText;
  final int dDay;
  final String amountLabel;
  final Color thumbnailColor;
}

class TopMascotHeader extends StatelessWidget {
  const TopMascotHeader({
    super.key,
    required this.onNotificationClick,
  });

  final VoidCallback onNotificationClick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x08162033),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: ClipOval(
            child: Image.asset(
              'assets/icon/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const Spacer(),
        _HeaderIconButton(
          icon: CupertinoIcons.bell,
          onPressed: onNotificationClick,
        ),
      ],
    );
  }
}

class SavingSpeechBubbleCard extends StatelessWidget {
  const SavingSpeechBubbleCard({
    super.key,
    required this.highlightedAmount,
    required this.prefix,
    required this.suffix,
  });

  final String highlightedAmount;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08162033),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 24,
            height: 1.45,
            color: const Color(0xFF1B1F28),
          ),
          children: [
            TextSpan(text: prefix),
            TextSpan(
              text: highlightedAmount,
              style: const TextStyle(
                color: Color(0xFF64CAFA),
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(text: suffix),
          ],
        ),
      ),
    );
  }
}

class CouponSectionHeader extends StatelessWidget {
  const CouponSectionHeader({
    super.key,
    required this.title,
    required this.sortType,
    required this.onSortChanged,
  });

  final String title;
  final HomeCouponSortType sortType;
  final ValueChanged<HomeCouponSortType> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        CouponSortDropdown(
          currentSortType: sortType,
          onChanged: onSortChanged,
        ),
      ],
    );
  }
}

class CouponSearchField extends StatelessWidget {
  const CouponSearchField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06162033),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: '쿠폰명을 입력해 주세요.',
          suffixIcon: Icon(CupertinoIcons.search),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }
}

class CouponSortDropdown extends StatelessWidget {
  const CouponSortDropdown({
    super.key,
    required this.currentSortType,
    required this.onChanged,
  });

  final HomeCouponSortType currentSortType;
  final ValueChanged<HomeCouponSortType> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<HomeCouponSortType>(
      onSelected: onChanged,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: HomeCouponSortType.expiry,
          child: Text('만료순'),
        ),
        PopupMenuItem(
          value: HomeCouponSortType.brand,
          child: Text('브랜드순'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentSortType == HomeCouponSortType.expiry ? '만료순' : '브랜드순',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF667085),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: Color(0xFF667085),
            ),
          ],
        ),
      ),
    );
  }
}

class CouponListSection extends StatelessWidget {
  const CouponListSection({
    super.key,
    required this.coupons,
    required this.onCouponClick,
  });

  final List<HomeCouponItem> coupons;
  final ValueChanged<HomeCouponItem> onCouponClick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < coupons.length; index++) ...[
          CouponCard(
            coupon: coupons[index],
            isHighlighted: index == 0,
            onTap: () => onCouponClick(coupons[index]),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class CouponCard extends StatelessWidget {
  const CouponCard({
    super.key,
    required this.coupon,
    required this.isHighlighted,
    required this.onTap,
  });

  final HomeCouponItem coupon;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFFB7E9FF)
                  : const Color(0xFFE7ECF3),
              width: isHighlighted ? 1.4 : 1,
            ),
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
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: coupon.thumbnailColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    coupon.thumbnailLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      coupon.expiryText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: const Color(0xFF4B5565),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DdayBadge(dDay: coupon.dDay),
            ],
          ),
        ),
      ),
    );
  }
}

class DdayBadge extends StatelessWidget {
  const DdayBadge({
    super.key,
    required this.dDay,
  });

  final int dDay;

  @override
  Widget build(BuildContext context) {
    final style = _badgeStyleForDday(dDay);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  _BadgeStyle _badgeStyleForDday(int value) {
    if (value <= 0) {
      return const _BadgeStyle(
        label: 'D-DAY',
        backgroundColor: Color(0xFF64CAFA),
        textColor: Colors.white,
      );
    }
    if (value <= 3) {
      return _BadgeStyle(
        label: 'D-$value',
        backgroundColor: const Color(0xFFBFEFFF),
        textColor: const Color(0xFF1D7EAA),
      );
    }
    return _BadgeStyle(
      label: 'D-$value',
      backgroundColor: const Color(0xFFF1F3F6),
      textColor: const Color(0xFF667085),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: const Color(0xFF1B1F28),
      ),
    );
  }
}


class _BadgeStyle {
  const _BadgeStyle({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
}
