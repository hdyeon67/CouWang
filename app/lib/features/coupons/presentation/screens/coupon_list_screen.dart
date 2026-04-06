import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/resources/app_strings.dart';
import '../../../../core/widgets/app_tab_scaffold.dart';
import '../../../../repositories/coupon_repository.dart';
import '../../../notifications/presentation/screens/notification_list_screen.dart';
import '../../../../services/notification_service.dart';
import 'coupon_create_screen.dart';
import 'coupon_detail_screen.dart';

enum HomeCouponSortType { expiry, name }

enum HomeCouponFilterType { available, used, expired }

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
  static const double _horizontalPadding = 20;
  final TextEditingController _searchController = TextEditingController();
  int _bubbleMessageIndex = 0;

  String _searchQuery = '';
  HomeCouponSortType _sortType = HomeCouponSortType.expiry;
  HomeCouponFilterType _filterType = HomeCouponFilterType.available;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().rescheduleAllCouponNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HomeCouponItem> get _filteredCouponList {
    final query = _searchQuery.trim().toLowerCase();

    final items = _couponList.where((coupon) {
      final matchesFilter = coupon.filterType == _filterType;
      final matchesSearch =
          query.isEmpty ||
          coupon.title.toLowerCase().contains(query) ||
          coupon.brand.toLowerCase().contains(query) ||
          coupon.detail.category.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();

    switch (_sortType) {
      case HomeCouponSortType.expiry:
        items.sort((a, b) => a.dDay.compareTo(b.dDay));
        break;
      case HomeCouponSortType.name:
        items.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return items;
  }

  String get _monthlySavingText {
    final amount = _couponList
        .where((coupon) {
          final usedAt = coupon.detail.usedAt;
          if (usedAt == null) {
            return false;
          }
          final usedDate = DateTime.tryParse(usedAt);
          if (usedDate == null) {
            return false;
          }
          final now = DateTime.now();
          return usedDate.year == now.year && usedDate.month == now.month;
        })
        .fold<int>(0, (sum, coupon) => sum + _estimateCouponAmount(coupon.detail));

    final formatted = amount > 0 ? _formatAmount(amount) : AppStrings.homeSavingFallback;
    final messages = [
      '${AppStrings.homeBubbleOriginalPrefix}$formatted${AppStrings.homeBubbleOriginalSuffix}',
      '${_couponList.where((coupon) => coupon.filterType == HomeCouponFilterType.available).length}장의 쿠폰이 아직 기다리고 있다 멍!',
      AppStrings.homeBubbleReminder,
      AppStrings.homeBubbleCheer,
    ];
    return messages[_bubbleMessageIndex % messages.length];
  }

  int _estimateCouponAmount(CouponDetailModel coupon) {
    final name = '${coupon.brand} ${coupon.name}'.toLowerCase();
    if (name.contains('1만원') || name.contains('10000')) return 10000;
    if (name.contains('5,000') || name.contains('5000')) return 5000;
    if (name.contains('3,000') || name.contains('3000')) return 3000;
    if (name.contains('파인트')) return 9800;
    if (name.contains('카페라떼')) return 6100;
    if (name.contains('아메리카노')) return 4500;
    if (name.contains('치킨')) return 23000;
    if (name.contains('피자')) return 28900;
    if (name.contains('상품권')) return 10000;
    if (name.contains('할인')) return 3000;
    return 5000;
  }

  String _formatAmount(int amount) {
    final buffer = StringBuffer();
    final value = amount.toString();
    for (var i = 0; i < value.length; i++) {
      final remaining = value.length - i;
      buffer.write(value[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${buffer.toString()}원';
  }

  List<HomeCouponItem> get _couponList {
    return CouponRepository.getAll().map((coupon) {
      return HomeCouponItem(
        id: coupon.id,
        brand: coupon.brand,
        title: coupon.name,
        expiryDate: coupon.expiry,
        dDay: coupon.dday,
        imagePath: coupon.imagePath ?? '',
        imageBytes: coupon.imageBytes,
        filterType: _resolveFilterType(coupon),
        detail: coupon,
      );
    }).toList();
  }

  HomeCouponFilterType _resolveFilterType(CouponDetailModel coupon) {
    if (coupon.isUsed || coupon.status == CouponDetailStatus.redeemed) {
      return HomeCouponFilterType.used;
    }
    if (coupon.isExpired || coupon.status == CouponDetailStatus.expired) {
      return HomeCouponFilterType.expired;
    }
    return HomeCouponFilterType.available;
  }

  void _handleCouponClick(HomeCouponItem coupon) {
    if (widget.onCouponClick != null) {
      widget.onCouponClick!(coupon.id);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CouponDetailScreen(coupon: coupon.detail),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleFabClick() {
    if (widget.onFabClick != null) {
      widget.onFabClick!.call();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CouponCreateScreen(),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppTabScaffold(
      currentTab: BottomTabItem.home,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingAddButton(onPressed: _handleFabClick),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            _horizontalPadding,
            8,
            _horizontalPadding,
            210,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopMascotHeader(
                onTap: () {
                  setState(() {
                    _bubbleMessageIndex++;
                  });
                },
                onNotificationClick: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SavingSpeechBubbleCard(message: _monthlySavingText),
              const SizedBox(height: 28),
              const Text(
                AppStrings.homeSectionTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 14),
              FilterAndSortRow(
                selectedFilter: _filterType,
                sortType: _sortType,
                onFilterChanged: (value) {
                  setState(() {
                    _filterType = value;
                  });
                },
                onSortChanged: (value) {
                  setState(() {
                    _sortType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              CouponSearchField(controller: _searchController),
              const SizedBox(height: 16),
              CouponListSection(
                coupons: _filteredCouponList,
                onCouponClick: _handleCouponClick,
              ),
            ],
          ),
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
    required this.title,
    required this.expiryDate,
    required this.dDay,
    required this.imagePath,
    this.imageBytes,
    required this.filterType,
    required this.detail,
  });

  final String id;
  final String brand;
  final String title;
  final String expiryDate;
  final int dDay;
  final String imagePath;
  final Uint8List? imageBytes;
  final HomeCouponFilterType filterType;
  final CouponDetailModel detail;
}

class TopMascotHeader extends StatelessWidget {
  const TopMascotHeader({
    super.key,
    required this.onTap,
    required this.onNotificationClick,
  });

  final VoidCallback onTap;
  final VoidCallback onNotificationClick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icon/2-1.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onNotificationClick,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          icon: const Icon(
            Icons.notifications_outlined,
            size: 26,
            color: Color(0xFF222222),
          ),
        ),
      ],
    );
  }
}

class SavingSpeechBubbleCard extends StatelessWidget {
  const SavingSpeechBubbleCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '"$message"',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
          height: 1.5,
        ),
      ),
    );
  }
}

class FilterAndSortRow extends StatelessWidget {
  const FilterAndSortRow({
    super.key,
    required this.selectedFilter,
    required this.sortType,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final HomeCouponFilterType selectedFilter;
  final HomeCouponSortType sortType;
  final ValueChanged<HomeCouponFilterType> onFilterChanged;
  final ValueChanged<HomeCouponSortType> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChipButton(
                    label: AppStrings.homeFilterAvailable,
                    isSelected:
                        selectedFilter == HomeCouponFilterType.available,
                    onTap: () =>
                        onFilterChanged(HomeCouponFilterType.available),
                  ),
                  FilterChipButton(
                    label: AppStrings.homeFilterUsed,
                    isSelected: selectedFilter == HomeCouponFilterType.used,
                    onTap: () => onFilterChanged(HomeCouponFilterType.used),
                  ),
                  FilterChipButton(
                    label: AppStrings.homeFilterExpired,
                    isSelected:
                        selectedFilter == HomeCouponFilterType.expired,
                    onTap: () => onFilterChanged(HomeCouponFilterType.expired),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: CouponSortDropdown(
                  currentSortType: sortType,
                  onChanged: onSortChanged,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Wrap(
              spacing: 8,
              children: [
                FilterChipButton(
                  label: AppStrings.homeFilterAvailable,
                  isSelected: selectedFilter == HomeCouponFilterType.available,
                  onTap: () => onFilterChanged(HomeCouponFilterType.available),
                ),
                FilterChipButton(
                  label: AppStrings.homeFilterUsed,
                  isSelected: selectedFilter == HomeCouponFilterType.used,
                  onTap: () => onFilterChanged(HomeCouponFilterType.used),
                ),
                FilterChipButton(
                  label: AppStrings.homeFilterExpired,
                  isSelected: selectedFilter == HomeCouponFilterType.expired,
                  onTap: () => onFilterChanged(HomeCouponFilterType.expired),
                ),
              ],
            ),
            const Spacer(),
            CouponSortDropdown(
              currentSortType: sortType,
              onChanged: onSortChanged,
            ),
          ],
        );
      },
    );
  }
}

class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF64CAFA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
          ),
        ),
      ),
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
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7DEE7), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1A1A1A),
        ),
        decoration: const InputDecoration(
          hintText: AppStrings.homeSearchHint,
          hintStyle: TextStyle(
            fontSize: 14,
            color: Color(0xFFBDBDBD),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          suffixIcon: Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.search,
              color: Color(0xFF9E9E9E),
              size: 22,
            ),
          ),
          suffixIconConstraints: BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
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
    return GestureDetector(
      onTap: () {
        onChanged(
          currentSortType == HomeCouponSortType.expiry
              ? HomeCouponSortType.name
              : HomeCouponSortType.expiry,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentSortType == HomeCouponSortType.expiry
                  ? AppStrings.homeSortExpiry
                  : AppStrings.homeSortName,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.swap_horiz_rounded,
              size: 16,
              color: Color(0xFF9E9E9E),
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
    if (coupons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            AppStrings.homeNoCoupons,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: coupons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        return CouponCard(
          coupon: coupon,
          isHighlighted: index == 0 && coupon.dDay == 0,
          onTap: () => onCouponClick(coupon),
        );
      },
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
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: isHighlighted
                ? Border.all(color: const Color(0xFF64CAFA), width: 1.8)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CouponThumbnail(
                imagePath: coupon.imagePath,
                imageBytes: coupon.imageBytes,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AppStrings.homeCouponExpiryPrefix}${coupon.expiryDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DdayBadge(dDay: coupon.dDay),
                  if (coupon.dDay == 0) ...[
                    const SizedBox(height: 4),
                    const Text(
                      AppStrings.homeTodayExpires,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64CAFA),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CouponThumbnail extends StatelessWidget {
  const CouponThumbnail({
    super.key,
    required this.imagePath,
    this.imageBytes,
  });

  final String imagePath;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null || imagePath.isNotEmpty;

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF0F0F0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: hasImage
            ? (imageBytes != null
                ? Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ))
            : const SizedBox.shrink(),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: style.border,
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: style.textColor,
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
    if (value <= 9) {
      return _BadgeStyle(
        label: 'D-$value',
        backgroundColor: Colors.white,
        textColor: const Color(0xFF64CAFA),
        border: Border.all(color: const Color(0xFF64CAFA), width: 1.5),
      );
    }
    return _BadgeStyle(
      label: 'D-$value',
      backgroundColor: Colors.white,
      textColor: const Color(0xFFBDBDBD),
      border: Border.all(color: const Color(0xFFBDBDBD), width: 1.2),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.border,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final BoxBorder? border;
}
