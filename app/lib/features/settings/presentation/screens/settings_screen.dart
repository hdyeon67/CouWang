import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_spacing.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
        title: const Text('설정'),
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
            const _BrandCard(),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(title: '알림'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsSection(
              children: [
                _ActionItem(
                  icon: CupertinoIcons.bell_circle,
                  title: '알림 리스트',
                  subtitle: '받은 알림과 리마인드 문구를 확인합니다',
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRouter.notificationList);
                  },
                ),
                const _DividerLine(),
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
                _DividerLine(),
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
                _DividerLine(),
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
                _DividerLine(),
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
                _DividerLine(),
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
                _DividerLine(),
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
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(title: '데이터'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsSection(
              children: [
                _ActionItem(
                  icon: CupertinoIcons.tray_arrow_down,
                  title: '샘플 데이터 불러오기',
                  subtitle: '데모용 쿠폰 데이터를 채워넣습니다',
                  onTap: () => _showPlaceholder('샘플 데이터 불러오기는 추후 연결합니다.'),
                ),
                _DividerLine(),
                _ActionItem(
                  icon: CupertinoIcons.delete_simple,
                  title: '데이터 초기화',
                  subtitle: '현재 저장된 쿠폰 데이터를 비웁니다',
                  onTap: () => _showPlaceholder('데이터 초기화는 추후 연결합니다.'),
                ),
                _DividerLine(),
                _ActionItem(
                  icon: CupertinoIcons.share,
                  title: 'CSV 내보내기',
                  subtitle: '추후 지원 예정',
                  onTap: () => _showPlaceholder('CSV 내보내기는 추후 지원 예정입니다.'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(title: '서비스 정보'),
            const SizedBox(height: AppSpacing.sm),
            const _SettingsSection(
              children: [
                _StaticItem(
                  icon: CupertinoIcons.info_circle,
                  title: '앱 버전',
                  value: '1.0.0',
                ),
                _DividerLine(),
                _StaticItem(
                  icon: CupertinoIcons.heart,
                  title: '쿠왕 소개',
                  value: '쿠폰을 놓치지 않게 도와드려요',
                ),
                _DividerLine(),
                _StaticItem(
                  icon: CupertinoIcons.doc_text,
                  title: '오픈소스 라이선스',
                  value: 'placeholder',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(title: '계정'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsSection(
              children: [
                _DisabledItem(
                  icon: CupertinoIcons.person_crop_circle,
                  title: '로그인',
                  subtitle: '추후 제공 예정',
                ),
                _DividerLine(),
                _DisabledItem(
                  icon: CupertinoIcons.person_add,
                  title: '회원가입',
                  subtitle: '추후 제공 예정',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.paw_solid,
              color: Color(0xFF2F6BFF),
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '쿠왕',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '쿠폰을 놓치지 않게 도와드려요',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF4B5563),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(children: children),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _LeadingIcon(icon: icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF2F6BFF),
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _LeadingIcon(icon: icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: Color(0xFF98A2B3),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticItem extends StatelessWidget {
  const _StaticItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _LeadingIcon(icon: icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledItem extends StatelessWidget {
  const _DisabledItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.72,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _LeadingIcon(icon: icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '준비 중',
                style: TextStyle(
                  color: Color(0xFF7B8798),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF2F6BFF),
        size: 19,
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
      indent: 72,
      endIndent: AppSpacing.md,
      color: Color(0xFFEFF2F6),
    );
  }
}
