import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_spacing.dart';
import 'coupon_camera_scan_screen.dart';
import 'coupon_image_auto_fill_screen.dart';

class CouponCreateScreen extends StatefulWidget {
  const CouponCreateScreen({super.key});

  @override
  State<CouponCreateScreen> createState() => _CouponCreateScreenState();
}

class _CouponCreateScreenState extends State<CouponCreateScreen> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedBrand;
  DateTime? _selectedExpiryDate;
  CouponType _selectedCouponType = CouponType.barcode;

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

  Future<void> _startGalleryAutoFillFlow() async {
    final selectedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (selectedImage == null || !mounted) {
      return;
    }

    final detectedCode = await _detectCodeFromImage(selectedImage.path);
    final detectedText = await _extractTextFromImage(selectedImage.path);
    final extracted = _buildAutoFillResult(
      detectedCode: detectedCode,
      detectedText: detectedText,
    );

    if (!mounted) {
      return;
    }

    final draft = await Navigator.of(context).push<CouponAutoFillDraft>(
      CupertinoPageRoute<CouponAutoFillDraft>(
        builder: (_) => CouponImageAutoFillScreen(
          draft: CouponAutoFillDraft(
            title: extracted.title,
            brand: extracted.brand,
            expiryDate: extracted.expiryDate,
            couponType: extracted.couponType,
            memo: extracted.memo,
            detectedCode: extracted.detectedCode,
            imagePath: selectedImage.path,
            isRecognized: extracted.isRecognized,
            statusTitle: extracted.statusTitle,
            statusDescription: extracted.statusDescription,
          ),
        ),
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    if (!draft.isRecognized) {
      _showMessage('다른 이미지로 다시 시도해보세요.');
      return;
    }

    setState(() {
      _titleController.text = draft.title;
      _memoController.text = draft.memo;
      _selectedBrand = draft.brand;
      _selectedCouponType = switch (draft.couponType) {
        '바코드' => CouponType.barcode,
        'QR' => CouponType.qr,
        _ => CouponType.none,
      };
      _selectedExpiryDate = _parseDate(draft.expiryDate);
    });

    _showMessage('자동 입력 결과를 등록 화면에 채웠어요.');
  }

  Future<void> _startCameraScanFlow() async {
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

    final draft = await Navigator.of(context).push<CouponAutoFillDraft>(
      CupertinoPageRoute<CouponAutoFillDraft>(
        builder: (_) => CouponImageAutoFillScreen(
          draft: CouponAutoFillDraft(
            title: extracted.title,
            brand: extracted.brand,
            expiryDate: extracted.expiryDate,
            couponType: extracted.couponType,
            memo: extracted.memo,
            detectedCode: extracted.detectedCode,
            imagePath: null,
            isRecognized: extracted.isRecognized,
            statusTitle: extracted.statusTitle,
            statusDescription: extracted.statusDescription,
          ),
        ),
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    if (!draft.isRecognized) {
      _showMessage('다시 스캔해보세요.');
      return;
    }

    setState(() {
      _titleController.text = draft.title;
      _memoController.text = draft.memo;
      _selectedBrand = draft.brand == '미확인' ? null : draft.brand;
      _selectedCouponType = switch (draft.couponType) {
        '바코드' => CouponType.barcode,
        'QR' => CouponType.qr,
        _ => CouponType.none,
      };
      if (draft.expiryDate != '미확인') {
        _selectedExpiryDate = _parseDate(draft.expiryDate);
      }
    });

    _showMessage('스캔 결과를 등록 화면에 채웠어요.');
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
        isRecognized: false,
        statusTitle: '자동 입력에 실패했어요',
        statusDescription: '텍스트나 바코드를 읽지 못했어요. 더 선명한 이미지로 다시 시도해보세요.',
      );
    }

    final title = detectedText?.title ?? '쿠폰 정보를 일부 읽어왔어요';
    final brand = detectedText?.brand ?? '미확인';
    final expiryDate = detectedText?.expiryDate ?? '미확인';
    final couponType = detectedCode?.couponTypeLabel ?? '미확인';
    final detectedCodeText = detectedCode?.rawValue ?? '인식된 코드가 없어요';
    final memo = _buildMemo(detectedCode: detectedCode, detectedText: detectedText);

    if (hasCode && hasText) {
      return _AutoFillExtractionResult(
        title: title,
        brand: brand,
        expiryDate: expiryDate,
        couponType: couponType,
        memo: memo,
        detectedCode: detectedCodeText,
        isRecognized: true,
        statusTitle: '코드와 텍스트를 읽어왔어요',
        statusDescription: '바코드/QR 값과 이미지 속 텍스트를 함께 분석해 등록 후보를 만들었어요.',
      );
    }

    if (hasText) {
      return _AutoFillExtractionResult(
        title: title,
        brand: brand,
        expiryDate: expiryDate,
        couponType: couponType,
        memo: memo,
        detectedCode: detectedCodeText,
        isRecognized: true,
        statusTitle: '텍스트를 읽어왔어요',
        statusDescription: 'OCR로 읽은 텍스트를 바탕으로 등록 후보를 만들었어요. 코드값은 확인되지 않았어요.',
      );
    }

    return _AutoFillExtractionResult(
      title: title,
      brand: brand,
      expiryDate: expiryDate,
      couponType: couponType,
      memo: memo,
      detectedCode: detectedCodeText,
      isRecognized: true,
      statusTitle: '코드 인식이 완료됐어요',
      statusDescription:
          '${detectedCode!.codeFormatLabel} 형식을 읽어 등록 화면에 반영할 준비를 마쳤어요.',
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

    // If a validity-range line exists, prefer the last date on that line.
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

    // Later, real save logic can be connected here.
    _showMessage('쿠폰이 등록되었어요.');
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
              '직접 입력해서 가장 간단하게 쿠폰을 등록할 수 있어요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ModeSection(
              title: '자동 입력',
              subtitle: '이미지나 코드 인식을 붙일 수 있는 확장 영역이에요.',
              child: _FormSection(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _AutoEntryCard(
                          icon: CupertinoIcons.photo,
                          title: '이미지 업로드',
                          subtitle: '앨범 이미지로 자동 입력',
                          onTap: () {
                            _startGalleryAutoFillFlow();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _AutoEntryCard(
                          icon: CupertinoIcons.camera_viewfinder,
                          title: '코드 인식',
                          subtitle: '바코드/QR 읽기',
                          onTap: () {
                            _startCameraScanFlow();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '이미지 업로드와 카메라 스캔 중 편한 방식으로 자동 입력을 시작할 수 있어요.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF8A94A6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ModeSection(
              title: '수동 입력',
              subtitle: '이번 MVP에서는 가장 안정적인 등록 방식입니다.',
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
            const SizedBox(height: AppSpacing.lg),
            _ModeSection(
              title: '이미지 추가',
              subtitle: '수동 등록과 함께 쿠폰 이미지를 보관하는 영역입니다.',
              child: _FormSection(
                children: [
                  _SectionLabel(label: '이미지 추가(선택)'),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBFF),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFD8E2F1),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            CupertinoIcons.camera,
                            color: Color(0xFF2F6BFF),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '이미지 추가',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '지금은 UI만 준비되어 있어요.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '이미지 보관 기능은 아직 placeholder 상태입니다.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF8A94A6),
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
  final bool isRecognized;
  final String statusTitle;
  final String statusDescription;
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD8E2F1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF2F6BFF)),
            ),
            const SizedBox(height: AppSpacing.md),
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
    );
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
