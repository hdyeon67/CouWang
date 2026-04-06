import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile_scanner;

import '../../../../core/resources/app_strings.dart';
import '../../../../core/services/app_permission_service.dart';
import '../../../../repositories/membership_repository.dart';
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
  String? _selectedImagePath;
  bool _isProcessingImage = false;

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
    _selectedImagePath = membership.imagePath;
    _memoController.text = membership.memo ?? '';
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
      _selectedImagePath = image.path;
    });
  }

  Future<void> _extractFromImage() async {
    if (_selectedImagePath == null) {
      return;
    }

    setState(() {
      _isProcessingImage = true;
    });

    final code = await _detectCodeFromImage(_selectedImagePath!);
    final title = await _extractTitleFromImage(_selectedImagePath!);

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessingImage = false;
      if (code != null && code.isNotEmpty) {
        _cardNumberController.text = code;
      }
      if ((_nameController.text.trim().isEmpty) && title != null && title.isNotEmpty) {
        _nameController.text = title;
      }
    });

    _showMessage(
      code != null || title != null
          ? AppStrings.membershipExtractDone
          : AppStrings.membershipExtractFailed,
    );
  }

  Future<String?> _detectCodeFromImage(String imagePath) async {
    final controller = mobile_scanner.MobileScannerController(autoStart: false);
    try {
      final capture = await controller.analyzeImage(imagePath);
      for (final barcode in capture?.barcodes ?? const <mobile_scanner.Barcode>[]) {
        final value = (barcode.rawValue ?? barcode.displayValue ?? '').trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    } catch (_) {
      return null;
    } finally {
      controller.dispose();
    }
    return null;
  }

  Future<String?> _extractTitleFromImage(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    try {
      final recognizedText = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      for (final rawLine in recognizedText.text.split('\n')) {
        final line = rawLine.trim();
        if (line.length >= 2 && !RegExp(r'^[0-9\s-]+$').hasMatch(line)) {
          return line;
        }
      }
    } catch (_) {
      return null;
    } finally {
      recognizer.close();
    }
    return null;
  }

  void _showImageFullScreen() {
    if (_selectedImageBytes == null && (_selectedImagePath == null || _selectedImagePath!.isEmpty)) {
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.transparent),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildSelectedImage(BoxFit.contain),
                          ),
                        ),
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

  Widget _buildSelectedImage(BoxFit fit) {
    if (_selectedImageBytes != null) {
      return Image.memory(_selectedImageBytes!, fit: fit);
    }
    return Image.file(File(_selectedImagePath!), fit: fit);
  }

  Future<void> _submitForm() async {
    final membershipName = _nameController.text.trim();

    if (membershipName.isEmpty) {
      _showMessage(AppStrings.membershipNameRequired);
      return;
    }
    final saved = await MembershipRepository.saveDraft(
      MembershipDraft(
        id: widget.membership?.id,
        name: membershipName,
        brand: _resolveBrand(membershipName),
        cardNumber: _cardNumberController.text.trim(),
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        imageBytes: _selectedImageBytes,
        sourceImagePath: _selectedImagePath,
        createdAt: widget.membership?.createdAt,
      ),
    );

    _showMessage(AppStrings.membershipRegistered);
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        Navigator.of(context).pop(saved);
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

  String _resolveBrand(String membershipName) {
    final normalized = membershipName.toLowerCase();
    if (normalized.contains('스타벅스')) {
      return AppStrings.brandStarbucks;
    }
    if (normalized.contains('cj')) {
      return AppStrings.membershipCjOne;
    }
    if (normalized.contains('해피')) {
      return AppStrings.membershipHappyPoint;
    }
    if (normalized.contains('skt')) {
      return AppStrings.membershipSkt;
    }
    return AppStrings.membershipPoint;
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
                  selectedImagePath: _selectedImagePath,
                  onTap: _pickImage,
                  onPreview: _showImageFullScreen,
                ),
                const SizedBox(height: 16),
                _ExtractButton(
                  enabled: _selectedImagePath != null && !_isProcessingImage,
                  isLoading: _isProcessingImage,
                  onPressed: _extractFromImage,
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
                    onPressed: () => _submitForm(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64CAFA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      widget.membership == null
                          ? AppStrings.couponSubmit
                          : AppStrings.couponUpdate,
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
    required this.selectedImagePath,
    required this.onTap,
    required this.onPreview,
  });

  final Uint8List? selectedImageBytes;
  final String? selectedImagePath;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    if (selectedImageBytes != null || (selectedImagePath?.isNotEmpty ?? false)) {
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
                if (selectedImageBytes != null)
                  Image.memory(
                    selectedImageBytes!,
                    fit: BoxFit.cover,
                  )
                else
                  Image.file(
                    File(selectedImagePath!),
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
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onPreview,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            AppStrings.membershipPreviewImage,
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

class _ExtractButton extends StatelessWidget {
  const _ExtractButton({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading;
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFD6EFFF) : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextButton(
        onPressed: active ? onPressed : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_fix_high,
              size: 18,
              color: active ? const Color(0xFF64CAFA) : const Color(0xFFBDBDBD),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.couponExtract,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? const Color(0xFF64CAFA) : const Color(0xFFBDBDBD),
              ),
            ),
          ],
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
