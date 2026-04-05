import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/resources/app_strings.dart';
import '../../../../core/services/app_permission_service.dart';
import 'membership_detail_screen.dart';

class MembershipCreateScreen extends StatefulWidget {
  const MembershipCreateScreen({
    super.key,
    this.membership,
  });

  final MembershipDetailModel? membership;

  @override
  State<MembershipCreateScreen> createState() => _MembershipCreateScreenState();
}

class _MembershipCreateScreenState extends State<MembershipCreateScreen> {
  final _nameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _memoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _selectedImageBytes;
  final String _selectedBrand = '직접 등록';

  @override
  void initState() {
    super.initState();
    final membership = widget.membership;
    if (membership == null) {
      return;
    }
    _nameController.text = membership.name;
    _cardNumberController.text = membership.cardNumber;
    _selectedImageBytes = membership.imageBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardNumberController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final granted = await AppPermissionService.ensurePhotoPermission(context);
    if (!granted || !mounted) {
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );

    if (image == null || !mounted) {
      return;
    }

    final imageBytes = await image.readAsBytes();

    setState(() {
      _selectedImageBytes = imageBytes;
    });
  }

  void _submitForm() {
    final membershipName = _nameController.text.trim();

    if (membershipName.isEmpty) {
      _showMessage(AppStrings.membershipNameRequired);
      return;
    }
    if (_selectedBrand.isEmpty) {
      _showMessage(AppStrings.membershipBrandRequired);
      return;
    }

    _showMessage(AppStrings.membershipRegistered);
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
      backgroundColor: const Color(0xFFF5F5F7),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 40, height: 40),
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 24,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 20),
                MembershipImagePicker(
                  selectedImageBytes: _selectedImageBytes,
                  onTap: _pickImage,
                ),
                const SizedBox(height: 28),
                const _FieldLabel(AppStrings.membershipNameLabel),
                const SizedBox(height: 8),
                _FilledTextField(
                  controller: _nameController,
                  hintText: AppStrings.membershipNameHint,
                ),
                const SizedBox(height: 18),
                const _FieldLabel(AppStrings.membershipCardNumberLabel),
                const SizedBox(height: 8),
                _FilledTextField(
                  controller: _cardNumberController,
                  hintText: AppStrings.membershipCardNumberHint,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(
                    Icons.credit_card_outlined,
                    size: 20,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
                const SizedBox(height: 18),
                const _FieldLabel(AppStrings.couponMemoLabel),
                const SizedBox(height: 8),
                _FilledTextField(
                  controller: _memoController,
                  hintText: AppStrings.membershipMemoHint,
                  minLines: 4,
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64CAFA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      AppStrings.couponSubmit,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MembershipImagePicker extends StatelessWidget {
  const MembershipImagePicker({
    super.key,
    required this.selectedImageBytes,
    required this.onTap,
  });

  final Uint8List? selectedImageBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (selectedImageBytes != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  selectedImageBytes!,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          AppStrings.couponChangeImage,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(),
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE0F4FF),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 26,
                  color: Color(0xFF64CAFA),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                AppStrings.couponPickImage,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                AppStrings.couponImageHelp,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF555555),
      ),
    );
  }
}

class _FilledTextField extends StatelessWidget {
  const _FilledTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.prefixIcon,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFFBDBDBD),
          ),
          prefixIcon: prefixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF64CAFA)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(20),
        ),
      );

    const dashWidth = 6.0;
    const dashSpace = 4.0;

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
