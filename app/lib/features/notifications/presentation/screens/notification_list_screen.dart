import 'package:flutter/material.dart';

import '../../../../core/resources/app_strings.dart';
import '../../../coupons/presentation/screens/coupon_detail_screen.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  late final List<_NotificationItem> _initialNotifications = [
    _NotificationItem(
      badgeLabel: 'D-DAY',
      badgeType: _NotificationBadgeType.dDayActive,
      title: '스타벅스 아메리카노',
      timeText: AppStrings.notificationJustNow,
      isUnread: true,
      coupon: const CouponDetailModel(
        brand: '스타벅스',
        avatarText: 'S',
        title: '아메리카노 Tall',
        status: CouponDetailStatus.urgent,
        dDay: 0,
        expiryDate: '2026-04-02',
        couponType: '바코드',
        createdAt: '2026-03-27',
        couponNumber: 'STB-2402-1193',
        memo: '매장 내 사용 가능',
      ),
    ),
    _NotificationItem(
      badgeLabel: 'D-3',
      badgeType: _NotificationBadgeType.activeOutline,
      title: '베스킨라빈스 파인트 교환권',
      timeText: AppStrings.notificationJustNow,
      isUnread: true,
      coupon: const CouponDetailModel(
        brand: '배스킨라빈스',
        avatarText: 'B',
        title: '파인트 교환권',
        status: CouponDetailStatus.urgent,
        dDay: 3,
        expiryDate: '2026-04-05',
        couponType: 'QR',
        createdAt: '2026-03-19',
        couponNumber: 'BR-3320-9182',
        memo: '포장 주문 가능',
      ),
    ),
    _NotificationItem(
      badgeLabel: 'D-7',
      badgeType: _NotificationBadgeType.inactiveOutline,
      title: '파리바게뜨 3,000원 할인',
      timeText: AppStrings.notificationDaysAgo6,
      isUnread: false,
      coupon: const CouponDetailModel(
        brand: '파리바게뜨',
        avatarText: 'P',
        title: '3,000원 할인',
        status: CouponDetailStatus.available,
        dDay: 7,
        expiryDate: '2026-04-09',
        couponType: '바코드',
        createdAt: '2026-03-12',
        couponNumber: 'PAR-3000-7612',
        memo: '일부 제품 제외',
      ),
    ),
    _NotificationItem(
      badgeLabel: 'D-DAY',
      badgeType: _NotificationBadgeType.dDayActive,
      title: 'GS25 5,000원 금액권',
      timeText: AppStrings.notificationDaysAgo10,
      isUnread: false,
      coupon: const CouponDetailModel(
        brand: 'GS25',
        avatarText: 'G',
        title: '5,000원 금액권',
        status: CouponDetailStatus.urgent,
        dDay: 0,
        expiryDate: '2026-04-02',
        couponType: '바코드',
        createdAt: '2026-03-09',
        couponNumber: 'GS-5000-2048',
        memo: '모바일 교환권',
      ),
    ),
  ];

  late List<_NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List<_NotificationItem>.from(_initialNotifications);
  }

  void _openCouponDetail(_NotificationItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CouponDetailScreen(coupon: item.coupon),
      ),
    );
  }

  void _removeNotification(_NotificationItem item) {
    _showDeleteConfirmDialog(
      title: '알림 삭제',
      description: '이 알림을 삭제할까요?',
      onConfirm: () {
        setState(() {
          _notifications.remove(item);
        });
      },
    );
  }

  void _clearAllNotifications() {
    _showDeleteConfirmDialog(
      title: '전체 삭제',
      description: '모든 알림을 삭제할까요?',
      onConfirm: () {
        setState(() {
          _notifications.clear();
        });
      },
    );
  }

  void _showDeleteConfirmDialog({
    required String title,
    required String description,
    required VoidCallback onConfirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: const Text(
                '삭제하기',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF222222),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      AppStrings.notificationTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearAllNotifications,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          AppStrings.notificationDeleteAll,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64CAFA),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_notifications.isEmpty)
                  const SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        AppStrings.notificationEmpty,
                        style: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    itemCount: _notifications.length,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return _NotificationCard(
                        item: item,
                        onTap: () => _openCouponDetail(item),
                        onRemove: item.isUnread
                            ? null
                            : () => _removeNotification(item),
                      );
                    },
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    this.onTap,
    this.onRemove,
  });

  final _NotificationItem item;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final titleColor = item.isUnread
        ? const Color(0xFF1A1A1A)
        : const Color(0xFF9E9E9E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: item.isUnread ? Colors.white : const Color(0xFFF9F6F3),
            borderRadius: BorderRadius.circular(16),
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
              _DdayBadge(
                label: item.badgeLabel,
                type: item.badgeType,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 42,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.timeText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    if (item.isUnread)
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Color(0xFFBDBDBD),
                      )
                    else
                      GestureDetector(
                        onTap: onRemove,
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFFE57373),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DdayBadge extends StatelessWidget {
  const _DdayBadge({
    required this.label,
    required this.type,
  });

  final String label;
  final _NotificationBadgeType type;

  @override
  Widget build(BuildContext context) {
    final style = switch (type) {
      _NotificationBadgeType.dDayActive => (
          background: const Color(0xFF64CAFA),
          border: null,
          textColor: Colors.white,
        ),
      _NotificationBadgeType.activeOutline => (
          background: Colors.white,
          border: Border.all(color: const Color(0xFF64CAFA), width: 1.5),
          textColor: const Color(0xFF64CAFA),
        ),
      _NotificationBadgeType.inactiveOutline => (
          background: Colors.white,
          border: Border.all(color: const Color(0xFFBDBDBD), width: 1.2),
          textColor: const Color(0xFFBDBDBD),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(6),
        border: style.border,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: style.textColor,
        ),
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.badgeLabel,
    required this.badgeType,
    required this.title,
    required this.timeText,
    required this.isUnread,
    required this.coupon,
  });

  final String badgeLabel;
  final _NotificationBadgeType badgeType;
  final String title;
  final String timeText;
  final bool isUnread;
  final CouponDetailModel coupon;
}

enum _NotificationBadgeType {
  dDayActive,
  activeOutline,
  inactiveOutline,
}
