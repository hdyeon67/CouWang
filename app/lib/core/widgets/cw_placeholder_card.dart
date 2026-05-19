import 'package:flutter/cupertino.dart';
/// 로딩/빈 상태에서 쓰는 공통 placeholder 카드.
import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

// CwPlaceholderCard 관련 역할을 담당하는 클래스.
class CwPlaceholderCard extends StatelessWidget {
  const CwPlaceholderCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = CupertinoIcons.square_grid_2x2,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
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
