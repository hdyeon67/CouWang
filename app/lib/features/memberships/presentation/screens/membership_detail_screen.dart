import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';

class MembershipDetailScreen extends StatelessWidget {
  const MembershipDetailScreen({
    super.key,
    this.membership = const MembershipDetailModel(
      brand: '올리브영',
      avatarText: 'O',
      membershipName: '올리브영 멤버십',
      description: '계산 전에 바로 보여주는 적립/할인 멤버십',
      createdAt: '2026-03-20',
      memo: '결제 전에 먼저 제시',
      imageLabel: '멤버십 이미지',
    ),
  });

  final MembershipDetailModel membership;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버십 상세'),
        actions: [
          IconButton(
            onPressed: () => _showEditConfirmDialog(context),
            icon: const Icon(CupertinoIcons.pencil),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showDeleteConfirmDialog(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(color: Color(0xFFE5D7DA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    foregroundColor: const Color(0xFF9A4B58),
                  ),
                  child: const Text('삭제'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _showPresentConfirmDialog(context),
                  child: const Text('멤버십 보여주기'),
                ),
              ),
            ],
          ),
        ),
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
            _MembershipHeroCard(membership: membership),
            const SizedBox(height: AppSpacing.lg),
            _MembershipImageCard(
              label: membership.imageLabel,
              onTap: () {
                _showPresentConfirmDialog(context);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _MembershipInfoSection(membership: membership),
            const SizedBox(height: AppSpacing.md),
            Text(
              '계산 전에 빠르게 보여줄 수 있도록 멤버십 상세 화면을 단순하게 구성했습니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: const Color(0xFF8A94A6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showEditConfirmDialog(BuildContext context) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: '멤버십을 수정할까요?',
      description: '멤버십 정보와 메모를 다시 정리할 수 있습니다.',
      confirmLabel: '수정',
    );

    if (confirmed == true && context.mounted) {
      _showMessage(context, '멤버십 수정 placeholder: 실제 편집은 다음 단계에서 연결합니다.');
    }
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: '멤버십을 삭제할까요?',
      description: '${membership.membershipName}이 목록에서 제거됩니다.',
      confirmLabel: '삭제',
      destructive: true,
    );

    if (confirmed == true && context.mounted) {
      _showMessage(context, '멤버십 삭제 placeholder: 실제 삭제는 다음 단계에서 연결합니다.');
    }
  }

  Future<void> _showPresentConfirmDialog(BuildContext context) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: '멤버십을 바로 보여줄까요?',
      description: '계산 전에 빠르게 제시할 수 있도록 이 화면을 열어둡니다.',
      confirmLabel: '보여주기',
    );

    if (confirmed == true && context.mounted) {
      _showMessage(context, '멤버십 제시 placeholder: 실제 전체 화면 표시 기능은 다음 단계에서 연결합니다.');
    }
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String description,
    required String confirmLabel,
    bool destructive = false,
  }) {
    final confirmColor = destructive
        ? const Color(0xFFB5475A)
        : const Color(0xFF2F6BFF);

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                confirmLabel,
                style: TextStyle(color: confirmColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

class MembershipDetailModel {
  const MembershipDetailModel({
    required this.brand,
    required this.avatarText,
    required this.membershipName,
    required this.description,
    required this.createdAt,
    required this.imageLabel,
    this.memo,
  });

  final String brand;
  final String avatarText;
  final String membershipName;
  final String description;
  final String createdAt;
  final String imageLabel;
  final String? memo;
}

class _MembershipHeroCard extends StatelessWidget {
  const _MembershipHeroCard({required this.membership});

  final MembershipDetailModel membership;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
            height: 60,
            width: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F7FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              membership.avatarText,
              style: const TextStyle(
                color: Color(0xFF2F6BFF),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membership.membershipName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  membership.brand,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2F6BFF),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  membership.description,
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

class _MembershipImageCard extends StatelessWidget {
  const _MembershipImageCard({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE8ECF4)),
        ),
        child: Column(
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDDE5F0)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.photo,
                    size: 34,
                    color: Color(0xFF8EA0B8),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    '멤버십 이미지 placeholder',
                    style: TextStyle(
                      color: Color(0xFF607183),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipInfoSection extends StatelessWidget {
  const _MembershipInfoSection({required this.membership});

  final MembershipDetailModel membership;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: Column(
        children: [
          _InfoRow(label: '브랜드', value: membership.brand),
          const _DividerLine(),
          _InfoRow(label: '멤버십명', value: membership.membershipName),
          const _DividerLine(),
          _InfoRow(label: '등록일', value: membership.createdAt),
          if ((membership.memo ?? '').isNotEmpty) ...[
            const _DividerLine(),
            _InfoRow(label: '메모', value: membership.memo!),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8A94A6),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15,
                color: const Color(0xFF1D2433),
              ),
            ),
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
    );
  }
}
