import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';

class CouponImageAutoFillScreen extends StatelessWidget {
  const CouponImageAutoFillScreen({
    super.key,
    this.draft = const CouponAutoFillDraft(
      title: '스타벅스 아메리카노 Tall',
      brand: '스타벅스',
      expiryDate: '2026.04.03',
      couponType: '바코드',
      memo: '이미지 자동 입력 결과를 확인한 뒤 저장해보세요.',
      detectedCode: '8801-2345-6789',
      imagePath: null,
      isRecognized: true,
      statusTitle: '코드 인식이 완료됐어요',
      statusDescription: '인식 결과를 확인한 뒤 등록 화면에 값을 채울 수 있어요.',
    ),
  });

  final CouponAutoFillDraft draft;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이미지 자동 입력'),
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
          child: ElevatedButton(
            onPressed: draft.isRecognized
                ? () {
                    Navigator.of(context).pop(draft);
                  }
                : null,
            child: Text(
              draft.isRecognized ? '등록 화면에 값 채우기' : '다른 이미지로 다시 시도',
            ),
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
            Text(
              '갤러리 이미지에서 읽은 값을 먼저 확인하는 단계예요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _RecognitionStatusCard(draft: draft),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE8ECF4)),
              ),
              child: Column(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFDDE5F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: draft.imagePath == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.photo_fill,
                                size: 36,
                                color: Color(0xFF8EA0B8),
                              ),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                '선택한 이미지 placeholder',
                                style: TextStyle(
                                  color: Color(0xFF607183),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Image.file(
                            File(draft.imagePath!),
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    draft.isRecognized
                        ? '이미지에서 바코드/QR 값과 일부 정보를 읽어왔어요.'
                        : '이미지에서는 코드를 찾지 못했지만 결과를 먼저 확인할 수 있어요.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE8ECF4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '인식 결과',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InfoRow(label: '쿠폰명', value: draft.title),
                  const _SectionDivider(),
                  _InfoRow(label: '브랜드', value: draft.brand),
                  const _SectionDivider(),
                  _InfoRow(label: '유형', value: draft.couponType),
                  const _SectionDivider(),
                  _InfoRow(label: '만료일', value: draft.expiryDate),
                  const _SectionDivider(),
                  _InfoRow(label: '인식 코드', value: draft.detectedCode),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: draft.isRecognized
                    ? const Color(0xFFF9FBFF)
                    : const Color(0xFFFFFAF5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: draft.isRecognized
                      ? const Color(0xFFD8E2F1)
                      : const Color(0xFFF1DFC7),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: draft.isRecognized
                          ? const Color(0xFFEAF1FF)
                          : const Color(0xFFFFF0DD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      draft.isRecognized
                          ? CupertinoIcons.check_mark_circled
                          : CupertinoIcons.exclamationmark_triangle,
                      color: draft.isRecognized
                          ? const Color(0xFF2F6BFF)
                          : const Color(0xFFDC8A1D),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      draft.isRecognized
                          ? '코드값은 읽어왔고, 제목·브랜드·만료일은 아직 샘플값으로 채워집니다.'
                          : '이번 단계에서는 인식 실패 이유를 간단히 보여주고, 다른 이미지로 다시 시도하도록 안내합니다.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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

class CouponAutoFillDraft {
  const CouponAutoFillDraft({
    required this.title,
    required this.brand,
    required this.expiryDate,
    required this.couponType,
    required this.memo,
    required this.detectedCode,
    required this.imagePath,
    required this.isRecognized,
    required this.statusTitle,
    required this.statusDescription,
  });

  final String title;
  final String brand;
  final String expiryDate;
  final String couponType;
  final String memo;
  final String detectedCode;
  final String? imagePath;
  final bool isRecognized;
  final String statusTitle;
  final String statusDescription;
}

class _RecognitionStatusCard extends StatelessWidget {
  const _RecognitionStatusCard({required this.draft});

  final CouponAutoFillDraft draft;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = draft.isRecognized
        ? const Color(0xFFF4F8FF)
        : const Color(0xFFFFF8EE);
    final borderColor = draft.isRecognized
        ? const Color(0xFFD8E2F1)
        : const Color(0xFFF1DFC7);
    final iconBackgroundColor = draft.isRecognized
        ? const Color(0xFFEAF1FF)
        : const Color(0xFFFFF0DD);
    final iconColor = draft.isRecognized
        ? const Color(0xFF2F6BFF)
        : const Color(0xFFDC8A1D);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              draft.isRecognized
                  ? CupertinoIcons.check_mark_circled
                  : CupertinoIcons.exclamationmark_triangle,
              color: iconColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.statusTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  draft.statusDescription,
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

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFEFF2F7),
    );
  }
}
