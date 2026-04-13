import 'dart:io';

import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/resources/app_strings.dart';
import '../../../../core/services/app_permission_service.dart';
import '../../../../repositories/coupon_repository.dart';
import '../../../../repositories/settings_repository.dart';
import '../../../../services/notification_service.dart';
import 'coupon_detail_screen.dart';


class CouponCreateScreen extends StatefulWidget {
  const CouponCreateScreen({
    super.key,
    this.coupon,
  });

  final CouponDetailModel? coupon;

  @override
  State<CouponCreateScreen> createState() => _CouponCreateScreenState();
}

class _CouponCreateScreenState extends State<CouponCreateScreen> {
  final _barcodeController = TextEditingController();
  final _couponNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _memoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;
  DateTime? _selectedDate;
  bool _isProcessingImage = false;
  bool _usedAutoFill = false;
  String _selectedCategory = '카페';
  CouponType _selectedCouponType = CouponType.barcode;

  static const List<String> _brands = [
    AppStrings.brandStarbucks,
    AppStrings.brandCu,
    AppStrings.brandGs25,
    AppStrings.brandOliveYoung,
    AppStrings.brandBbq,
    AppStrings.brandBaskin,
  ];

  static const List<String> _categories = [
    AppStrings.categoryCafe,
    AppStrings.categoryBakery,
    AppStrings.categoryConvenience,
    AppStrings.categoryFastFood,
    AppStrings.categoryRestaurant,
    AppStrings.categoryMart,
    AppStrings.categoryBeauty,
    AppStrings.categoryCulture,
    AppStrings.categoryLife,
    AppStrings.categoryEtc,
  ];

  bool get _isExtractEnabled => _selectedImage != null && !_isProcessingImage;

  bool get _isFormValid =>
      _barcodeController.text.trim().isNotEmpty &&
      _couponNameController.text.trim().isNotEmpty &&
      _brandController.text.trim().isNotEmpty &&
      _selectedDate != null;

  @override
  void initState() {
    super.initState();
    final coupon = widget.coupon;
    if (coupon == null) {
      return;
    }

    _barcodeController.text = coupon.barcodeNumber;
    _couponNameController.text = coupon.name;
    _brandController.text = coupon.brand;
    _memoController.text = coupon.memo ?? '';
    _selectedCategory = coupon.category;
    _selectedDate = _tryParseDate(coupon.expiry);
    _selectedImageBytes = coupon.imageBytes;
    _selectedImagePath = coupon.imagePath;
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _couponNameController.dispose();
    _brandController.dispose();
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
      _selectedImage = image;
      _selectedImageBytes = imageBytes;
      _selectedImagePath = image.path;
    });
  }

  void _showImageFullScreen() {
    if (_selectedImageBytes == null && (_selectedImagePath == null || _selectedImagePath!.isEmpty)) {
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) {
          return Scaffold(
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
          );
        },
      ),
    );
  }

  Widget _buildSelectedImage(BoxFit fit) {
    if (kIsWeb || (_selectedImage == null && _selectedImageBytes != null)) {
      return Image.memory(_selectedImageBytes!, fit: fit);
    }
    if (_selectedImage != null) {
      return Image.file(File(_selectedImage!.path), fit: fit);
    }
    return Image.file(File(_selectedImagePath!), fit: fit);
  }

  Future<void> _extractFromImage() async {
    await _runImageOcr();
  }

  Future<void> _runImageOcr() async {
    if (kIsWeb) {
      _showMessage(AppStrings.couponOcrWebUnsupported);
      return;
    }

    final imagePath = _selectedImage?.path;
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
      _showMessage(AppStrings.couponExtractFailed);
      return;
    }

    _applyAutoFillResult(extracted);
    _showMessage(AppStrings.couponExtractFilled);
  }

  void _applyAutoFillResult(_AutoFillExtractionResult extracted) {
    setState(() {
      _usedAutoFill = true;
      if (!extracted.title.startsWith('인식 결과')) {
        _couponNameController.text = extracted.title;
      }
      if (extracted.brand != '미확인') {
        _brandController.text = extracted.brand;
      }
      if (extracted.detectedCode != '인식된 코드가 없어요') {
        _barcodeController.text = extracted.detectedCode;
      }
      _memoController.text = extracted.memo;
      if (extracted.expiryDate != '미확인') {
        _selectedDate = _parseDate(extracted.expiryDate);
      }
      _selectedCouponType = switch (extracted.couponType) {
        '바코드' => CouponType.barcode,
        AppStrings.couponTypeQr => CouponType.qr,
        _ => _selectedCouponType,
      };
      final resolvedCategory = _resolveCategoryFromExtractedData(extracted);
      if (resolvedCategory != null) {
        _selectedCategory = resolvedCategory;
      }
    });
  }

  String? _resolveCategoryFromExtractedData(_AutoFillExtractionResult extracted) {
    final source = [
      extracted.title,
      extracted.brand,
      extracted.memo,
      extracted.couponType,
    ].join(' ').toLowerCase();

    if (source.contains('스타벅스') ||
        source.contains('투썸') ||
        source.contains('커피') ||
        source.contains('라떼') ||
        source.contains('아메리카노') ||
        source.contains('카페')) {
      return AppStrings.categoryCafe;
    }
    if (source.contains('베이커리') ||
        source.contains('파리바게뜨') ||
        source.contains('뚜레쥬르') ||
        source.contains('도넛')) {
      return AppStrings.categoryBakery;
    }
    if (source.contains('cu') ||
        source.contains('gs25') ||
        source.contains('세븐일레븐') ||
        source.contains('편의점')) {
      return AppStrings.categoryConvenience;
    }
    if (source.contains('버거') ||
        source.contains('맥도날드') ||
        source.contains('롯데리아') ||
        source.contains('bbq') ||
        source.contains('치킨') ||
        source.contains('패스트푸드')) {
      return AppStrings.categoryFastFood;
    }
    if (source.contains('피자') ||
        source.contains('레스토랑') ||
        source.contains('외식')) {
      return AppStrings.categoryRestaurant;
    }
    if (source.contains('마트') ||
        source.contains('abc마트') ||
        source.contains('올리브영') ||
        source.contains('상품권') ||
        source.contains('쇼핑')) {
      return AppStrings.categoryMart;
    }
    if (source.contains('뷰티') || source.contains('헬스')) {
      return AppStrings.categoryBeauty;
    }
    if (source.contains('영화') || source.contains('문화') || source.contains('티켓')) {
      return AppStrings.categoryCulture;
    }
    if (source.contains('생활') || source.contains('세탁')) {
      return AppStrings.categoryLife;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF64CAFA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
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
    final scanner = BarcodeScanner(
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upca,
        BarcodeFormat.upce,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.itf,
        BarcodeFormat.codabar,
        BarcodeFormat.pdf417,
        BarcodeFormat.aztec,
        BarcodeFormat.dataMatrix,
      ],
    );

    try {
      final barcodes = await scanner.processImage(
        InputImage.fromFilePath(imagePath),
      );
      if (barcodes.isEmpty) {
        return null;
      }

      final barcode = _selectBestBarcode(barcodes);
      final rawValue = barcode.rawValue?.trim();
      final displayValue = barcode.displayValue?.trim();
      final resolvedValue = (rawValue?.isNotEmpty ?? false)
          ? rawValue!
          : (displayValue?.isNotEmpty ?? false)
              ? displayValue!
              : null;
      if (resolvedValue == null) {
        return null;
      }

      return _DetectedCouponCode(
        rawValue: resolvedValue,
        couponTypeLabel: _couponTypeLabelForBarcode(barcode),
        codeFormatLabel: _barcodeFormatLabel(barcode.format),
      );
    } catch (_) {
      return null;
    } finally {
      await scanner.close();
    }
  }

  Barcode _selectBestBarcode(List<Barcode> barcodes) {
    final usableBarcodes = barcodes.where((barcode) {
      final rawValue = barcode.rawValue?.trim();
      final displayValue = barcode.displayValue?.trim();
      return (rawValue?.isNotEmpty ?? false) || (displayValue?.isNotEmpty ?? false);
    }).toList();

    if (usableBarcodes.isEmpty) {
      return barcodes.first;
    }

    usableBarcodes.sort((a, b) {
      final aIsQr = a.format == BarcodeFormat.qrCode;
      final bIsQr = b.format == BarcodeFormat.qrCode;
      if (aIsQr != bIsQr) {
        return aIsQr ? -1 : 1;
      }

      final aLength = (a.rawValue ?? a.displayValue ?? '').length;
      final bLength = (b.rawValue ?? b.displayValue ?? '').length;
      return bLength.compareTo(aLength);
    });

    return usableBarcodes.first;
  }

  String _couponTypeLabelForBarcode(Barcode barcode) {
    if (barcode.format == BarcodeFormat.qrCode || barcode.type == BarcodeType.url) {
      return AppStrings.couponTypeQr;
    }
    return AppStrings.couponTypeBarcode;
  }

  String _barcodeFormatLabel(BarcodeFormat format) {
    return switch (format) {
      BarcodeFormat.qrCode => AppStrings.couponTypeQr,
      BarcodeFormat.code128 => 'Code 128',
      BarcodeFormat.code39 => 'Code 39',
      BarcodeFormat.code93 => 'Code 93',
      BarcodeFormat.codabar => 'Codabar',
      BarcodeFormat.dataMatrix => 'Data Matrix',
      BarcodeFormat.ean13 => 'EAN-13',
      BarcodeFormat.ean8 => 'EAN-8',
      BarcodeFormat.itf => 'ITF',
      BarcodeFormat.upca => 'UPC-A',
      BarcodeFormat.upce => 'UPC-E',
      BarcodeFormat.pdf417 => 'PDF417',
      BarcodeFormat.aztec => 'Aztec',
      BarcodeFormat.unknown || BarcodeFormat.all => AppStrings.couponTypeBarcode,
    };
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
        title: AppStrings.couponNoDetectionTitle,
        brand: AppStrings.couponUnknown,
        expiryDate: AppStrings.couponUnknown,
        couponType: AppStrings.couponUnknown,
        memo: AppStrings.couponNoDetectionMemo,
        detectedCode: AppStrings.couponNoDetectedCode,
        codeFormatLabel: null,
        isRecognized: false,
      );
    }

    return _AutoFillExtractionResult(
      title: detectedText?.title ?? AppStrings.couponPartialResultTitle,
      brand: detectedText?.brand ?? AppStrings.couponUnknown,
      expiryDate: detectedText?.expiryDate ?? AppStrings.couponUnknown,
      couponType: detectedCode?.couponTypeLabel ?? AppStrings.couponUnknown,
      memo: _buildMemo(detectedCode: detectedCode, detectedText: detectedText),
      detectedCode: detectedCode?.rawValue ?? AppStrings.couponNoDetectedCode,
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
          ? AppStrings.couponRetryImageMemo
          : '${detectedCode.codeFormatLabel} 인식 결과를 확인한 뒤 저장해보세요.';
    }

    final lines = detectedText.rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(2)
        .join(' / ');

    if (lines.isEmpty) {
      return AppStrings.couponReadTextMemo;
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
      if (line.contains(AppStrings.couponExpiryKeyword) ||
          line.contains(AppStrings.couponUsePeriodKeyword) ||
          line.contains(AppStrings.couponPeriodKeyword)) {
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
      if (cleanedLine.contains(AppStrings.couponInfoKeyword) ||
          cleanedLine.contains('barcode') ||
          cleanedLine.contains('qr') ||
          cleanedLine.contains(AppStrings.couponExpiryKeyword)) {
        continue;
      }

      return cleanedLine;
    }

    return null;
  }

  Future<void> _onSubmit() async {
    await _submitForm();
  }

  Future<void> _submitForm() async {
    final title = _couponNameController.text.trim();
    final brand = _brandController.text.trim();

    if (title.isEmpty) {
      _showMessage(AppStrings.couponInputTitleRequired);
      return;
    }
    if (brand.isEmpty) {
      _showMessage(AppStrings.couponBrandRequired);
      return;
    }
    if (_selectedDate == null) {
      _showMessage(AppStrings.couponDateRequired);
      return;
    }

    final savedCoupon = CouponDetailModel(
      id:
          widget.coupon?.id ??
          'coupon_${DateTime.now().microsecondsSinceEpoch}',
      brand: brand,
      name: title,
      category: _selectedCategory,
      dday: _calculateDday(_selectedDate!),
      expiry: _formatSelectedDate(_selectedDate!),
      barcodeNumber: _barcodeController.text.trim(),
      imagePath: _selectedImage?.path ?? widget.coupon?.imagePath,
      imageBytes: _selectedImageBytes,
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      isUsed: widget.coupon?.isUsed ?? false,
      status: _resolveStatus(
        selectedDate: _selectedDate!,
        isUsed: widget.coupon?.isUsed ?? false,
      ),
      couponType: _selectedCouponType == CouponType.qr
          ? AppStrings.couponTypeQr
          : AppStrings.couponTypeBarcode,
      createdAt: widget.coupon?.createdAt ?? DateTime.now().toIso8601String(),
      usedAt: widget.coupon?.usedAt,
    );

    final repositoryCoupon = await CouponRepository.saveDraft(
      CouponDraft(
        id: savedCoupon.id,
        name: savedCoupon.name,
        brand: savedCoupon.brand,
        category: savedCoupon.category,
        barcodeNumber: savedCoupon.barcodeNumber,
        expiry: savedCoupon.expiry,
        memo: savedCoupon.memo,
        isUsed: savedCoupon.isUsed,
        couponType: savedCoupon.couponType,
        status: savedCoupon.status,
        imageBytes: savedCoupon.imageBytes,
        sourceImagePath: savedCoupon.imagePath,
        createdAt: savedCoupon.createdAt,
        usedAt: savedCoupon.usedAt,
      ),
    );
    final settings = SettingsRepository.load();
    final notificationService = NotificationService();

    if (widget.coupon != null) {
      await notificationService.cancelCouponNotifications(widget.coupon!.id);
    }
    await notificationService.scheduleCouponNotifications(
      repositoryCoupon,
      settings,
    );

    final entryType = _usedAutoFill
        ? AppStrings.couponEntryAuto
        : AppStrings.couponEntryManual;
    _showMessage('$entryType${AppStrings.couponRegisteredSuffix}');
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        Navigator.of(context).pop(repositoryCoupon);
      }
    });
  }

  CouponDetailStatus _resolveStatus({
    required DateTime selectedDate,
    required bool isUsed,
  }) {
    if (isUsed) {
      return CouponDetailStatus.redeemed;
    }
    if (_calculateDday(selectedDate) < 0) {
      return CouponDetailStatus.expired;
    }
    if (_calculateDday(selectedDate) <= 3) {
      return CouponDetailStatus.urgent;
    }
    return CouponDetailStatus.available;
  }

  int _calculateDday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  String _formatSelectedDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
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

  DateTime? _tryParseDate(String formattedDate) {
    final parts = formattedDate.split('.');
    if (parts.length != 3) {
      return null;
    }

    return DateTime.tryParse(
      '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}',
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
                _CouponImagePicker(
                  selectedImage: _selectedImage,
                  selectedImageBytes: _selectedImageBytes,
                  selectedImagePath: _selectedImagePath,
                  onTap: _pickImage,
                  onPreview: _showImageFullScreen,
                ),
                const SizedBox(height: 16),
                _ExtractButton(
                  enabled: _isExtractEnabled,
                  isLoading: _isProcessingImage,
                  onTap: _extractFromImage,
                ),
                const SizedBox(height: 24),
                _RequiredLabel(AppStrings.couponInputCode),
                const SizedBox(height: 8),
                _FilledTextField(
                  controller: _barcodeController,
                  hintText: AppStrings.couponInputCodeHint,
                  keyboardType: TextInputType.text,
                  prefixIcon: const Icon(
                    Icons.view_week_outlined,
                    size: 20,
                    color: Color(0xFFBDBDBD),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                CouponBarcodePreview(
                  code: _barcodeController.text.trim(),
                ),
                const SizedBox(height: 18),
                _RequiredLabel(AppStrings.couponNameLabel),
                const SizedBox(height: 8),
                _FilledTextField(
                  controller: _couponNameController,
                  hintText: AppStrings.couponNameHint,
                  prefixIcon: const Icon(
                    Icons.confirmation_number_outlined,
                    size: 20,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
                const SizedBox(height: 18),
                _RequiredLabel(AppStrings.couponBrandLabel),
                const SizedBox(height: 8),
                _FilledTextField(
                  controller: _brandController,
                  hintText: AppStrings.couponBrandHint,
                  prefixIcon: const Icon(
                    Icons.storefront_outlined,
                    size: 20,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RequiredLabel(AppStrings.couponExpiryLabel),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: Color(0xFFBDBDBD),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedDate == null
                                        ? 'mm / dd / yyyy'
                                        : '${_selectedDate!.month.toString().padLeft(2, '0')} / ${_selectedDate!.day.toString().padLeft(2, '0')} / ${_selectedDate!.year}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _selectedDate == null
                                          ? const Color(0xFFBDBDBD)
                                          : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _OptionalLabel(AppStrings.couponCategoryLabel),
                          const SizedBox(height: 8),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: Color(0xFF9E9E9E),
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1A1A1A),
                                ),
                                items: _categories
                                    .map(
                                      (cat) => DropdownMenuItem<String>(
                                        value: cat,
                                        child: Text(cat),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val == null) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedCategory = val;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _OptionalLabel(AppStrings.couponMemoLabel),
                const SizedBox(height: 8),
                _FilledTextField(
                  controller: _memoController,
                  hintText: AppStrings.couponMemoHint,
                  minLines: 4,
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isFormValid ? () => _onSubmit() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid
                          ? const Color(0xFF64CAFA)
                          : const Color(0xFFBDBDBD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: const Color(0xFFBDBDBD),
                    ),
                    child: Text(
                      widget.coupon == null
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
  barcode(AppStrings.couponTypeBarcode),
  qr(AppStrings.couponTypeQr),
  none(AppStrings.couponTypeNone);

  const CouponType(this.label);

  final String label;
}

class _CouponImagePicker extends StatelessWidget {
  const _CouponImagePicker({
    required this.selectedImage,
    required this.selectedImageBytes,
    required this.selectedImagePath,
    required this.onTap,
    required this.onPreview,
  });

  final XFile? selectedImage;
  final Uint8List? selectedImageBytes;
  final String? selectedImagePath;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    if (selectedImage != null || selectedImageBytes != null || (selectedImagePath?.isNotEmpty ?? false)) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 170,
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
                if (kIsWeb || (selectedImage == null && selectedImageBytes != null))
                  Image.memory(
                    selectedImageBytes!,
                    fit: BoxFit.cover,
                  )
                else if (selectedImage != null)
                  Image.file(
                    File(selectedImage!.path),
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
                            AppStrings.couponPreviewImage,
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
          height: 170,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE0F4FF),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 24,
                  color: Color(0xFF64CAFA),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                AppStrings.couponPickImage,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
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
    required this.onTap,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground =
        enabled ? const Color(0xFF64CAFA) : const Color(0xFFBDBDBD);

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFD6EFFF) : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextButton(
        onPressed: enabled && !isLoading ? onTap : null,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(foreground),
                ),
              )
            else
              Icon(
                Icons.auto_fix_high,
                size: 18,
                color: foreground,
              ),
            const SizedBox(width: 8),
            Text(
              AppStrings.couponExtract,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(width: 3),
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFF3B30),
          ),
        ),
      ],
    );
  }
}

class _OptionalLabel extends StatelessWidget {
  const _OptionalLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
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
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final int? minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;

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
        onChanged: onChanged,
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

class CouponBarcodePreview extends StatelessWidget {
  const CouponBarcodePreview({
    super.key,
    required this.code,
  });

  final String code;

  bool get _isLink {
    final normalized = code.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (code.isEmpty) {
      return Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            AppStrings.couponAutoPreviewPlaceholder,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFBDBDBD),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _isLink ? AppStrings.couponQrPreview : AppStrings.couponBarcodePreview,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64CAFA),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          bw.BarcodeWidget(
            barcode: _isLink ? bw.Barcode.qrCode() : bw.Barcode.code128(),
            data: code,
            width: double.infinity,
            height: _isLink ? 120 : 60,
            drawText: !_isLink,
            errorBuilder: (context, error) {
              return Container(
                width: double.infinity,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isLink ? AppStrings.couponQrError : AppStrings.couponBarcodeError,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
              );
            },
          ),
        ],
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

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
