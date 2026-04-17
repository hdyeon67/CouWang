import 'package:flutter/material.dart';

import '../../../../core/resources/app_strings.dart';
import '../../../../core/widgets/empty_state_mascot.dart';
import '../../../../repositories/notification_log_repository.dart';
import '../../../coupons/presentation/screens/coupon_detail_screen.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen>
    with WidgetsBindingObserver {
  List<_NotificationItem> _notifications = <_NotificationItem>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    final logs = await NotificationLogRepository.loadVisibleLogs();
    if (!mounted) {
      return;
    }
    setState(() {
      _notifications = logs
          .map(
            (log) => _NotificationItem(
              id: log.id,
              badgeLabel: _badgeLabel(log.coupon),
              badgeType: _badgeType(log.coupon, log.isRead),
              title: log.coupon.name,
              timeText: _formatTimeText(log.scheduledAt),
              isUnread: !log.isRead,
              coupon: log.coupon,
            ),
          )
          .toList();
    });
  }

  String _badgeLabel(CouponDetailModel coupon) {
    if (coupon.isUsed) {
      return AppStrings.couponUsed;
    }
    if (coupon.isExpired) {
      return AppStrings.couponExpired;
    }
    return coupon.dday == 0 ? 'D-DAY' : 'D-${coupon.dday}';
  }

  _NotificationBadgeType _badgeType(CouponDetailModel coupon, bool isRead) {
    if (isRead || coupon.isUsed || coupon.isExpired) {
      return _NotificationBadgeType.inactiveOutline;
    }
    if (coupon.dday == 0) {
      return _NotificationBadgeType.dDayActive;
    }
    return _NotificationBadgeType.activeOutline;
  }

  Future<void> _openCouponDetail(_NotificationItem item) async {
    await NotificationLogRepository.markAsRead(item.id);
    if (!mounted) {
      return;
    }
    setState(() {
      final index = _notifications.indexWhere((element) => element.id == item.id);
      if (index >= 0) {
        _notifications[index] = _notifications[index].copyWith(
          isUnread: false,
          badgeType: _NotificationBadgeType.inactiveOutline,
        );
      }
    });
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CouponDetailScreen(coupon: item.coupon),
      ),
    );
    await _loadNotifications();
  }

  void _removeNotification(_NotificationItem item) {
    _showDeleteConfirmDialog(
      title: '알림 삭제',
      description: '이 알림을 삭제할까요?',
      onConfirm: () async {
        await NotificationLogRepository.deleteLog(item.id);
        if (!mounted) {
          return;
        }
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
      onConfirm: () async {
        await NotificationLogRepository.deleteAllLogs();
        if (!mounted) {
          return;
        }
        setState(() {
          _notifications.clear();
        });
      },
    );
  }

  String _formatTimeText(DateTime scheduledAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDay = DateTime(
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
    );
    final difference = today.difference(scheduledDay).inDays;
    if (difference <= 0) {
      return AppStrings.notificationJustNow;
    }
    return '$difference일 전';
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
                Transform.translate(
                  offset: const Offset(-10, 0),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF222222),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
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
                      onTap: _notifications.isEmpty ? null : _clearAllNotifications,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          AppStrings.notificationDeleteAll,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _notifications.isEmpty
                                ? const Color(0xFFBDBDBD)
                                : const Color(0xFF64CAFA),
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
                      child: EmptyStateMascot(
                        message: AppStrings.notificationEmpty,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DdayBadge(
                      label: item.badgeLabel,
                      type: item.badgeType,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                  ],
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
          background: const Color(0xFF55C8FF),
          textColor: Colors.white,
        ),
      _NotificationBadgeType.activeOutline => (
          background: _getDdayBadgeColor(label),
          textColor: Colors.white,
        ),
      _NotificationBadgeType.inactiveOutline => (
          background: _getInactiveBadgeColor(label),
          textColor: Colors.white,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: style.textColor,
        ),
      ),
    );
  }

  Color _getDdayBadgeColor(String label) {
    final dday = label == 'D-DAY'
        ? 0
        : int.tryParse(label.replaceFirst('D-', '')) ?? 30;
    if (dday <= 1) return const Color(0xFF55C8FF);
    if (dday <= 3) return const Color(0xFF7DD4FF);
    if (dday <= 7) return const Color(0xFFA3E0FF);
    if (dday <= 15) return const Color(0xFFC2EAFF);
    return const Color(0xFFDDF3FF);
  }

  Color _getInactiveBadgeColor(String label) {
    if (label == AppStrings.couponExpired) {
      return const Color(0xFFE58C73);
    }
    return const Color(0xFF8E9AAF);
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.badgeLabel,
    required this.badgeType,
    required this.title,
    required this.timeText,
    required this.isUnread,
    required this.coupon,
  });

  final String id;
  final String badgeLabel;
  final _NotificationBadgeType badgeType;
  final String title;
  final String timeText;
  final bool isUnread;
  final CouponDetailModel coupon;

  _NotificationItem copyWith({
    bool? isUnread,
    _NotificationBadgeType? badgeType,
  }) {
    return _NotificationItem(
      id: id,
      badgeLabel: badgeLabel,
      badgeType: badgeType ?? this.badgeType,
      title: title,
      timeText: timeText,
      isUnread: isUnread ?? this.isUnread,
      coupon: coupon,
    );
  }
}

enum _NotificationBadgeType {
  dDayActive,
  activeOutline,
  inactiveOutline,
}
