import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';

class MembershipCreateScreen extends StatefulWidget {
  const MembershipCreateScreen({super.key});

  @override
  State<MembershipCreateScreen> createState() => _MembershipCreateScreenState();
}

class _MembershipCreateScreenState extends State<MembershipCreateScreen> {
  final _nameController = TextEditingController();
  final _memoController = TextEditingController();

  String? _selectedBrand;

  static const List<String> _brands = [
    '스타벅스',
    '올리브영',
    'CU',
    'GS25',
    '배스킨라빈스',
    '이마트',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _selectBrand() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DEEA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '멤버십 브랜드 선택',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._brands.map(
                    (brand) => ListTile(
                      title: Text(brand),
                      trailing: _selectedBrand == brand
                          ? const Icon(
                              CupertinoIcons.check_mark_circled_solid,
                              color: Color(0xFF2F6BFF),
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop(brand);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedBrand = selected;
      });
    }
  }

  void _submitForm() {
    final membershipName = _nameController.text.trim();

    if (membershipName.isEmpty) {
      _showMessage('멤버십명을 입력해주세요.');
      return;
    }
    if (_selectedBrand == null) {
      _showMessage('브랜드를 선택해주세요.');
      return;
    }

    _showMessage('멤버십이 등록되었어요.');
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버십 등록'),
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
            onPressed: _submitForm,
            child: const Text('등록 완료'),
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
              '계산대에서 바로 보여줄 멤버십을 간단하게 등록할 수 있어요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _FormSection(
              children: [
                _SectionLabel(label: '멤버십명'),
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: '예: 올리브영 멤버십',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(label: '브랜드'),
                _PickerField(
                  icon: CupertinoIcons.creditcard,
                  text: _selectedBrand ?? '브랜드를 선택해주세요',
                  isSelected: _selectedBrand != null,
                  onTap: _selectBrand,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(label: '메모(선택)'),
                TextField(
                  controller: _memoController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '적립, 할인, 사용처 메모 등',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _FormSection(
              children: [
                _SectionLabel(label: '이미지 추가(선택)'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBFF),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFD7E2F2),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        CupertinoIcons.photo_on_rectangle,
                        color: Color(0xFF8EA0B8),
                        size: 30,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        '이미지 추가',
                        style: TextStyle(
                          color: Color(0xFF516173),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '이미지 업로드 기반 등록은 다음 단계에서 확장할 수 있어요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.children});

  final List<Widget> children;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontSize: 15,
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? const Color(0xFF1D2433)
        : const Color(0xFF8EA0B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(CupertinoIcons.chevron_down),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF7B8CA5)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
