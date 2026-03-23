import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _expiryReminderEnabled = true;
  bool _sameDayReminderEnabled = true;
  bool _d1ReminderEnabled = true;
  bool _d3ReminderEnabled = true;
  bool _d7ReminderEnabled = true;
  bool _d30ReminderEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
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
                          '쿠폰과 멤버십 알림을 조절할 수 있어요',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '이번 MVP에서는 토글 UI만 먼저 제공하고, 실제 알림 반영은 다음 단계에서 연결합니다.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFE8ECF4)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06162033),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _ToggleItem(
                    icon: CupertinoIcons.bell,
                    title: '만료 임박 알림',
                    subtitle: '쿠폰 만료가 가까워지면 알려드려요',
                    value: _expiryReminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _expiryReminderEnabled = value;
                      });
                    },
                  ),
                  const _DividerLine(),
                  _ToggleItem(
                    icon: CupertinoIcons.today,
                    title: '당일 알림',
                    subtitle: '만료 당일 마지막으로 알려드려요',
                    value: _sameDayReminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _sameDayReminderEnabled = value;
                      });
                    },
                  ),
                  const _DividerLine(),
                  _ToggleItem(
                    icon: CupertinoIcons.clock,
                    title: 'D-1 알림',
                    subtitle: '만료 하루 전 다시 알려드려요',
                    value: _d1ReminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _d1ReminderEnabled = value;
                      });
                    },
                  ),
                  const _DividerLine(),
                  _ToggleItem(
                    icon: CupertinoIcons.calendar_badge_plus,
                    title: 'D-3 알림',
                    subtitle: '만료 3일 전 여유 있게 알려드려요',
                    value: _d3ReminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _d3ReminderEnabled = value;
                      });
                    },
                  ),
                  const _DividerLine(),
                  _ToggleItem(
                    icon: CupertinoIcons.calendar_today,
                    title: 'D-7 알림',
                    subtitle: '만료 일주일 전 미리 알려드려요',
                    value: _d7ReminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _d7ReminderEnabled = value;
                      });
                    },
                  ),
                  const _DividerLine(),
                  _ToggleItem(
                    icon: CupertinoIcons.calendar,
                    title: 'D-30 알림',
                    subtitle: '한 달 전부터 천천히 챙길 수 있어요',
                    value: _d30ReminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _d30ReminderEnabled = value;
                      });
                    },
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

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2F6BFF), size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFEFF2F7),
      indent: AppSpacing.md,
      endIndent: AppSpacing.md,
    );
  }
}
