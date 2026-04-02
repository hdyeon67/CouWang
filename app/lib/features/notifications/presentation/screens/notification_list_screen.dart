import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../coupons/presentation/screens/coupon_detail_screen.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  static const List<_NotificationItem> _items = [
    _NotificationItem(
      title: '스타벅스 아메리카노 Tall',
      message: '3일 안에 사용하지 않으면 혜택이 사라져요.',
      timeLabel: '오늘 오전 9:20',
      typeLabel: '쿠폰 만료 임박',
      coupon: CouponDetailModel(
        brand: '스타벅스',
        avatarText: 'S',
        title: '아메리카노 Tall',
        status: CouponDetailStatus.urgent,
        dDay: 3,
        expiryDate: '2026-04-03',
        couponType: '바코드',
        createdAt: '2026-03-24',
        couponNumber: 'STB-3029-1148',
        memo: '매장 내 사용 가능',
      ),
    ),
    _NotificationItem(
      title: '배스킨라빈스 파인트 교환권',
      message: '곧 만료되는 쿠폰이에요. 외출 전에 한 번 더 확인해보세요.',
      timeLabel: '어제 오후 6:10',
      typeLabel: '사용 리마인드',
      coupon: CouponDetailModel(
        brand: '배스킨라빈스',
        avatarText: 'B',
        title: '파인트 교환권',
        status: CouponDetailStatus.urgent,
        dDay: 2,
        expiryDate: '2026-04-02',
        couponType: 'QR',
        createdAt: '2026-03-18',
        couponNumber: 'BR-2203-9921',
        memo: '포장 주문 가능',
      ),
    ),
    _NotificationItem(
      title: 'ABC마트 1만원 할인 쿠폰',
      message: '오늘 안에 사용하지 않으면 혜택이 사라져요.',
      timeLabel: '3월 20일',
      typeLabel: '오늘 만료',
      coupon: CouponDetailModel(
        brand: 'ABC마트',
        avatarText: 'A',
        title: '1만원 할인 쿠폰',
        status: CouponDetailStatus.urgent,
        dDay: 0,
        expiryDate: '2026-03-31',
        couponType: '바코드',
        createdAt: '2026-03-10',
        couponNumber: 'ABC-1000-2026',
        memo: '일부 브랜드 제외',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.notificationSettings);
            },
            icon: const Icon(CupertinoIcons.slider_horizontal_3),
            tooltip: '알림 설정',
          ),
        ],
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
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.bell_fill,
                    color: Color(0xFF2F6BFF),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '놓치기 쉬운 쿠폰과 멤버십 알림을 한곳에 모았어요',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '오른쪽 상단에서 알림 설정 화면으로 이동할 수 있어요.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final item in _items) ...[
            _NotificationCard(
              item: item,
              onTap: () {
                Navigator.of(context).pushNamed(
                  AppRouter.couponDetail,
                  arguments: item.coupon,
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.typeLabel,
    required this.coupon,
  });

  final String title;
  final String message;
  final String timeLabel;
  final String typeLabel;
  final CouponDetailModel coupon;
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  final _NotificationItem item;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                CupertinoIcons.bell,
                color: Color(0xFF2F6BFF),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        item.timeLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F7FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.typeLabel,
                      style: const TextStyle(
                        color: Color(0xFF2F6BFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    item.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
