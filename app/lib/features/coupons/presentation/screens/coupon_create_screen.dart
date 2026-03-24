import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_spacing.dart';
import 'coupon_camera_scan_screen.dart';

class CouponCreateScreen extends StatefulWidget {
  const CouponCreateScreen({super.key});

  @override
  State<CouponCreateScreen> createState() => _CouponCreateScreenState();
}

class _CouponCreateScreenState extends State<CouponCreateScreen> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _codeController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedBrand;
  DateTime? _selectedExpiryDate;
  CouponType _selectedCouponType = CouponType.barcode;
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;
  bool _isProcessingImage = false;
  bool _usedAutoFill = false;
  String? _detectedCodeFormatLabel;

  static const List<String> _brands = [
    '스타벅스',
    'CU',
    'GS25',
    '올리브영',
    'BBQ',
    '배스킨라빈스',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final selectedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (selectedImage == null || !mounted) {
      return;
    }

    final imageBytes = await selectedImage.readAsBytes();

    setState(() {
      _selectedImageBytes = imageBytes;
      _selectedImagePath = selectedImage.path;
    });

    _showMessage('이미지를 불러왔어요. 아래 OCR 버튼으로 스캔할 수 있어요.');
  }

  Future<void> _runImageOcr() async {
    if (kIsWeb) {
      _showMessage('웹에서는 OCR과 바코드/QR 이미지 분석을 지원하지 않아요. 모바일 기기에서 테스트해 주세요.');
      return;
    }

    final imagePath = _selectedImagePath;
    if (imagePath == null) {
      return;
    }

    setState(() {
      _isProcessingImage = true;
    });

    final detectedCode = await _detectCodeFromImage(imagePath);
    final detectedText = await _extractTextFromImage(imagePath);
    final extracted = _buildAutoFillResult(
      detectedCode: detectedCode,
      detectedText: detectedText,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessingImage = false;
    });

    if (!extracted.isRecognized) {
      _showMessage('이미지에서 텍스트나 코드를 읽지 못했어요.');
      return;
    }

    _applyAutoFillResult(extracted);
    _showMessage('이미지 스캔 결과를 입력란에 채웠어요.');
  }

  Future<void> _startCameraScanFlow() async {
    if (kIsWeb) {
      _showMessage('웹에서는 실시간 코드 인식을 지원하지 않아요. 모바일 기기에서 테스트해 주세요.');
      return;
    }

    final scanResult = await Navigator.of(context).push<CameraScanResult>(
      CupertinoPageRoute<CameraScanResult>(
        builder: (_) => const CouponCameraScanScreen(),
      ),
    );

    if (scanResult == null || !mounted) {
      return;
    }

    final extracted = _buildAutoFillResult(
      detectedCode: _DetectedCouponCode(
        rawValue: scanResult.rawValue,
        couponTypeLabel: scanResult.couponTypeLabel,
        codeFormatLabel: scanResult.codeFormatLabel,
      ),
      detectedText: null,
    );

    _applyAutoFillResult(extracted);
    _showMessage('코드 스캔 결과를 입력란에 채웠어요.');
  }

  void _applyAutoFillResult(_AutoFillExtractionResult extracted) {
    setState(() {
      _usedAutoFill = true;
      _titleController.text = extracted.title.startsWith('인식 결과')
          ? _titleController.text
          : extracted.title;
      _memoController.text = extracted.memo;
      _codeController.text = extracted.detectedCode == '인식된 코드가 없어요'
          ? _codeController.text
          : extracted.detectedCode;
      _selectedBrand = extracted.brand == '미확인' ? _selectedBrand : extracted.brand;
      _selectedCouponType = switch (extracted.couponType) {
        '바코드' => CouponType.barcode,
        'QR' => CouponType.qr,
        _ => _selectedCouponType,
      };
      if (extracted.expiryDate != '미확인') {
        _selectedExpiryDate = _parseDate(extracted.expiryDate);
      }
      _detectedCodeFormatLabel = extracted.codeFormatLabel;
    });
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
                    '브랜드 선택',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._brands.map(
                    (brand) => ListTile(
                      title: Text(brand),
                      trailing: _selectedBrand == brand
                          ? const Icon(
                              CupertinoIcons.check_mark_circled_solid,
                              color: Color(0xFF64CAFA),
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(brand),
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

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      helpText: '만료일 선택',
      cancelText: '취소',
      confirmText: '선택',
    );

    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  Future<_DetectedCouponText?> _extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.korean,
    );

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text.trim();

      if (rawText.isEmpty) {
        return null;
      }

      final lines = rawText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      return _DetectedCouponText(
        rawText: rawText,
        brand: _extractBrand(lines),
        expiryDate: _extractExpiryDate(rawText),
        title: _extractTitle(lines),
      );
    } catch (_) {
      return null;
    } finally {
      textRecognizer.close();
    }
  }

  Future<_DetectedCouponCode?> _detectCodeFromImage(String imagePath) async {
    final controller = MobileScannerController(
      autoStart: false,
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.codabar,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.itf14,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.pdf417,
        BarcodeFormat.aztec,
      ],
    );

    try {
      final capture = await controller.analyzeImage(imagePath);
      Barcode? barcode;

      for (final item in capture?.barcodes ?? const <Barcode>[]) {
        if (_resolveBarcodeValue(item).isNotEmpty) {
          barcode = item;
          break;
        }
      }

      if (barcode == null) {
        return null;
      }

      return _DetectedCouponCode(
        rawValue: _resolveBarcodeValue(barcode),
        couponTypeLabel: barcode.format == BarcodeFormat.qrCode ? 'QR' : '바코드',
        codeFormatLabel: _formatLabel(barcode.format),
      );
    } catch (_) {
      return null;
    } finally {
      controller.dispose();
    }
  }

  String _resolveBarcodeValue(Barcode barcode) {
    return (barcode.rawValue ?? barcode.displayValue ?? '').trim();
  }

  String _formatLabel(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.qrCode:
        return 'QR';
      case BarcodeFormat.dataMatrix:
        return 'Data Matrix';
      case BarcodeFormat.pdf417:
        return 'PDF417';
      case BarcodeFormat.aztec:
        return 'Aztec';
      default:
        return '바코드';
    }
  }

  _AutoFillExtractionResult _buildAutoFillResult({
    required _DetectedCouponCode? detectedCode,
    required _DetectedCouponText? detectedText,
  }) {
    final hasCode = detectedCode != null;
    final hasText = detectedText != null;
    final hasUsableData = hasCode || hasText;

    if (!hasUsableData) {
      return const _AutoFillExtractionResult(
        title: '인식 결과를 확인할 수 없어요',
        brand: '미확인',
        expiryDate: '미확인',
        couponType: '미확인',
        memo: '이미지 안의 텍스트와 바코드/QR이 선명한지 다시 확인해보세요.',
        detectedCode: '인식된 코드가 없어요',
        codeFormatLabel: null,
        isRecognized: false,
      );
    }

    return _AutoFillExtractionResult(
      title: detectedText?.title ?? '쿠폰 정보를 일부 읽어왔어요',
      brand: detectedText?.brand ?? '미확인',
      expiryDate: detectedText?.expiryDate ?? '미확인',
      couponType: detectedCode?.couponTypeLabel ?? '미확인',
      memo: _buildMemo(detectedCode: detectedCode, detectedText: detectedText),
      detectedCode: detectedCode?.rawValue ?? '인식된 코드가 없어요',
      codeFormatLabel: detectedCode?.codeFormatLabel,
      isRecognized: true,
    );
  }

  String _buildMemo({
    required _DetectedCouponCode? detectedCode,
    required _DetectedCouponText? detectedText,
  }) {
    if (detectedText == null) {
      return detectedCode == null
          ? '이미지 안의 텍스트나 코드가 선명한지 다시 확인해보세요.'
          : '${detectedCode.codeFormatLabel} 인식 결과를 확인한 뒤 저장해보세요.';
    }

    final lines = detectedText.rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(2)
        .join(' / ');

    if (lines.isEmpty) {
      return 'OCR로 읽은 텍스트를 확인한 뒤 저장해보세요.';
    }

    return lines;
  }

  String? _extractBrand(List<String> lines) {
    final normalizedText = lines.join('\n').toLowerCase();

    for (final brand in _brands) {
      if (normalizedText.contains(brand.toLowerCase())) {
        return brand;
      }
    }

    return null;
  }

  String? _extractExpiryDate(String rawText) {
    final lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (final line in lines) {
      if (line.contains('유효기간') ||
          line.contains('사용기간') ||
          line.contains('기간')) {
        final dates = _extractAllDates(line);
        if (dates.isNotEmpty) {
          return dates.last;
        }
      }
    }

    final detectedDates = _extractAllDates(rawText);
    if (detectedDates.isNotEmpty) {
      return detectedDates.last;
    }

    return null;
  }

  List<String> _extractAllDates(String rawText) {
    final patterns = [
      RegExp(r'(20\d{2})[./-]\s?(\d{1,2})[./-]\s?(\d{1,2})'),
      RegExp(r'(\d{2})[./-]\s?(\d{1,2})[./-]\s?(\d{1,2})'),
    ];
    final detectedDates = <String>[];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(rawText)) {
        final yearGroup = match.group(1)!;
        final year = yearGroup.length == 2
            ? int.parse('20$yearGroup')
            : int.parse(yearGroup);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);

        if (month < 1 || month > 12 || day < 1 || day > 31) {
          continue;
        }

        final normalizedMonth = month.toString().padLeft(2, '0');
        final normalizedDay = day.toString().padLeft(2, '0');
        detectedDates.add('$year.$normalizedMonth.$normalizedDay');
      }

      if (detectedDates.isNotEmpty) {
        return detectedDates;
      }
    }

    return detectedDates;
  }

  String? _extractTitle(List<String> lines) {
    for (final line in lines) {
      final cleanedLine = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleanedLine.length < 4) {
        continue;
      }
      if (RegExp(r'^\d[\d\s./:-]+$').hasMatch(cleanedLine)) {
        continue;
      }
      if (cleanedLine.contains('쿠폰번호') ||
          cleanedLine.contains('barcode') ||
          cleanedLine.contains('qr') ||
          cleanedLine.contains('유효기간')) {
        continue;
      }

      return cleanedLine;
    }

    return null;
  }

  void _submitForm() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      _showMessage('제목을 입력해주세요.');
      return;
    }
    if (_selectedBrand == null) {
      _showMessage('브랜드를 선택해주세요.');
      return;
    }
    if (_selectedExpiryDate == null) {
      _showMessage('만료일을 선택해주세요.');
      return;
    }

    final entryType = _usedAutoFill ? '자동 입력' : '수동 입력';
    _showMessage('$entryType 방식으로 쿠폰이 등록되었어요.');
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

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }

  DateTime _parseDate(String formattedDate) {
    final parts = formattedDate.split('.');
    if (parts.length != 3) {
      return DateTime.now().add(const Duration(days: 7));
    }

    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('쿠폰 등록'),
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
              '자동 입력 또는 수동 입력으로 쿠폰을 등록할 수 있어요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ModeSection(
              title: '자동 입력',
              subtitle: '이미지를 업로드하거나 코드를 스캔해 입력을 도와줄 수 있어요.',
              child: _FormSection(
                children: [
                  _AutoEntryCard(
                    icon: CupertinoIcons.photo,
                    title: _selectedImagePath == null ? '이미지 업로드' : '이미지 변경',
                    subtitle: _selectedImagePath == null
                        ? '갤러리 이미지로 쿠폰을 불러와요.'
                        : '다른 이미지를 선택해서 다시 시도할 수 있어요.',
                    onTap: _pickImage,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OcrActionButton(
                    enabled: _selectedImagePath != null && !_isProcessingImage,
                    isLoading: _isProcessingImage,
                    onTap: _runImageOcr,
                  ),
                  if (_selectedImagePath != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SelectedImagePreview(
                      imageBytes: _selectedImageBytes,
                      onTap: _pickImage,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _AutoEntryCard(
                    icon: CupertinoIcons.camera_viewfinder,
                    title: '코드 인식',
                    subtitle: '바코드/QR 코드를 실시간으로 스캔해요.',
                    onTap: _startCameraScanFlow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ModeSection(
              title: '수동 입력',
              subtitle: '직접 값을 입력해 가장 안정적으로 등록할 수 있어요.',
              child: _FormSection(
                children: [
                  _SectionLabel(label: '제목'),
                  TextField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: '예: 스타벅스 아메리카노',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(label: '브랜드'),
                  _PickerField(
                    icon: CupertinoIcons.bag,
                    text: _selectedBrand ?? '브랜드를 선택해주세요',
                    isSelected: _selectedBrand != null,
                    onTap: _selectBrand,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(label: '만료일'),
                  _PickerField(
                    icon: CupertinoIcons.calendar,
                    text: _selectedExpiryDate == null
                        ? '만료일을 선택해주세요'
                        : _formatDate(_selectedExpiryDate!),
                    isSelected: _selectedExpiryDate != null,
                    onTap: _selectExpiryDate,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(label: '쿠폰 유형'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: CouponType.values.map((type) {
                      final selected = _selectedCouponType == type;

                      return _TypeChip(
                        label: type.label,
                        selected: selected,
                        onTap: () {
                          setState(() {
                            _selectedCouponType = type;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(label: '바코드 / 링크 / 번호'),
                  TextField(
                    controller: _codeController,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: '바코드 번호 또는 QR 링크를 입력해주세요',
                    ),
                  ),
                  if (_codeController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    CouponCodePreview(
                      code: _codeController.text.trim(),
                      couponType: _selectedCouponType,
                      codeFormatLabel: _detectedCodeFormatLabel,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(label: '메모(선택)'),
                  TextField(
                    controller: _memoController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '사용 조건, 매장 제한 등',
                      alignLabelWithHint: true,
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

class _DetectedCouponCode {
  const _DetectedCouponCode({
    required this.rawValue,
    required this.couponTypeLabel,
    required this.codeFormatLabel,
  });

  final String rawValue;
  final String couponTypeLabel;
  final String codeFormatLabel;
}

class _DetectedCouponText {
  const _DetectedCouponText({
    required this.rawText,
    required this.brand,
    required this.expiryDate,
    required this.title,
  });

  final String rawText;
  final String? brand;
  final String? expiryDate;
  final String? title;
}

class _AutoFillExtractionResult {
  const _AutoFillExtractionResult({
    required this.title,
    required this.brand,
    required this.expiryDate,
    required this.couponType,
    required this.memo,
    required this.detectedCode,
    required this.codeFormatLabel,
    required this.isRecognized,
  });

  final String title;
  final String brand;
  final String expiryDate;
  final String couponType;
  final String memo;
  final String detectedCode;
  final String? codeFormatLabel;
  final bool isRecognized;
}

enum CouponType {
  barcode('바코드'),
  qr('QR'),
  none('없음');

  const CouponType(this.label);

  final String label;
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.children,
  });

  final List<Widget> children;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ModeSection extends StatelessWidget {
  const _ModeSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _AutoEntryCard extends StatelessWidget {
  const _AutoEntryCard({
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD8E2F1)),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF64CAFA)),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Color(0xFF98A2B3),
            ),
          ],
        ),
      ),
    );
  }
}

class _OcrActionButton extends StatelessWidget {
  const _OcrActionButton({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: IgnorePointer(
        ignoring: !enabled,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onTap,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(CupertinoIcons.doc_text_viewfinder),
            label: Text(isLoading ? '이미지 스캔 중...' : '이미지 스캔 (OCR)'),
          ),
        ),
      ),
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  const _SelectedImagePreview({
    required this.imageBytes,
    required this.onTap,
  });

  final Uint8List? imageBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDDE5F0)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageBytes != null)
              Image.memory(
                imageBytes!,
                fit: BoxFit.cover,
              )
            else
              const ColoredBox(color: Color(0xFFF8FAFD)),
            Positioned(
              right: AppSpacing.sm,
              top: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(125),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_clockwise,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '이미지 변경',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CouponCodePreview extends StatelessWidget {
  const CouponCodePreview({
    super.key,
    required this.code,
    required this.couponType,
    required this.codeFormatLabel,
  });

  final String code;
  final CouponType couponType;
  final String? codeFormatLabel;

  @override
  Widget build(BuildContext context) {
    final isQr = couponType == CouponType.qr;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E2F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isQr ? 'QR 미리보기' : '바코드 미리보기',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (codeFormatLabel != null && codeFormatLabel!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              codeFormatLabel!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF667085),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Center(
            child: isQr
                ? _FakeQrWidget(value: code)
                : _FakeBarcodeWidget(value: code),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            code,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

class _FakeBarcodeWidget extends StatelessWidget {
  const _FakeBarcodeWidget({
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    final bars = value.codeUnits.isEmpty ? [1, 2, 3, 1, 2] : value.codeUnits;

    return Container(
      width: double.infinity,
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final unit in bars.take(40)) ...[
            SizedBox(width: (unit % 3 + 1).toDouble()),
            Container(
              width: (unit % 4 + 1).toDouble(),
              margin: EdgeInsets.symmetric(
                vertical: unit % 5 == 0 ? 10 : 4,
              ),
              color: Colors.black,
            ),
          ],
        ],
      ),
    );
  }
}

class _FakeQrWidget extends StatelessWidget {
  const _FakeQrWidget({
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(148, 148),
      painter: _FakeQrPainter(value),
    );
  }
}

class _FakeQrPainter extends CustomPainter {
  _FakeQrPainter(this.value);

  final String value;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.white;
    final blackPaint = Paint()..color = Colors.black;
    final cell = size.width / 21;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(16),
      ),
      backgroundPaint,
    );

    for (var row = 0; row < 21; row++) {
      for (var col = 0; col < 21; col++) {
        final inFinder = _isFinder(row, col);
        final shouldFill = inFinder || _hashFill(row, col);
        if (!shouldFill) {
          continue;
        }

        canvas.drawRect(
          Rect.fromLTWH(col * cell, row * cell, cell, cell),
          blackPaint,
        );
      }
    }
  }

  bool _isFinder(int row, int col) {
    bool inSquare(int top, int left) {
      return row >= top &&
          row < top + 5 &&
          col >= left &&
          col < left + 5 &&
          (row == top ||
              row == top + 4 ||
              col == left ||
              col == left + 4 ||
              (row >= top + 1 &&
                  row <= top + 3 &&
                  col >= left + 1 &&
                  col <= left + 3));
    }

    return inSquare(1, 1) || inSquare(1, 15) || inSquare(15, 1);
  }

  bool _hashFill(int row, int col) {
    final hash = value.hashCode;
    final seed = (hash + row * 31 + col * 17) & 0x7fffffff;
    return seed % 3 == 0;
  }

  @override
  bool shouldRepaint(covariant _FakeQrPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 15,
        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          border: Border.all(color: const Color(0xFFE8ECF4)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF8A94A6)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF1D2433)
                      : const Color(0xFF8A94A6),
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: Color(0xFF8A94A6),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF1FF) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFC7D8FF) : const Color(0xFFE8ECF4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF2F6BFF) : const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
