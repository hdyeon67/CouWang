import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_spacing.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  static const List<_NotificationItem> _items = [
    _NotificationItem(
      title: '스타벅스 아메리카노 Tall',
      message: '3일 안에 사용하지 않으면 혜택이 사라져요.',
      timeLabel: '오늘 오전 9:20',
      typeLabel: '쿠폰 만료 임박',
    ),
    _NotificationItem(
      title: '올리브영 멤버십',
      message: '계산 전에 바로 보여줄 수 있도록 준비해두었어요.',
      timeLabel: '어제 오후 6:10',
      typeLabel: '멤버십 리마인드',
    ),
    _NotificationItem(
      title: '이번 달 리포트',
      message: '이번 달에 쿠폰으로 18,400원을 아꼈어요.',
      timeLabel: '3월 20일',
      typeLabel: '리포트',
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
                _showPlaceholderMessage(context, '${item.title} 상세 이동은 다음 단계에서 연결합니다.');
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
  });

  final String title;
  final String message;
  final String timeLabel;
  final String typeLabel;
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
