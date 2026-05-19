// 쿠폰 등록/수정 화면.
//
// 수동 입력을 기본으로 두고, 이미지 OCR/바코드 인식은 보조 흐름으로 얹는다.
// 인수인계 시에는 `_runImageOcr`, `_buildAutoFillResult`, `_submitForm`
// 세 메서드를 먼저 읽으면 전체 데이터 흐름을 이해하기 쉽다.
import 'dart:io';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/resources/app_strings.dart';
import '../../../../core/services/app_permission_service.dart';
import '../../../../repositories/coupon_repository.dart';
import '../../../../repositories/settings_repository.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/notification_service.dart';
import 'coupon_detail_screen.dart';


// CouponCreateScreen 화면 역할을 담당하는 클래스.
class CouponCreateScreen extends StatefulWidget {
  const CouponCreateScreen({
    super.key,
    this.coupon,
    this.preloadedImage,
  });

  final CouponDetailModel? coupon;
  final File? preloadedImage;

  @override
  State<CouponCreateScreen> createState() => _CouponCreateScreenState();
}

// CouponCreateScreenState 관련 역할을 담당하는 클래스.
class _CouponCreateScreenState extends State<CouponCreateScreen> {
  // OCR 결과에서 상단 상태바/앱 헤더가 제목으로 섞이는 것을 줄이기 위한 컷오프 비율.
  static const double _ocrTopExclusionRatio = 0.12;
  static const Color _fieldFillColor = Color(0xFFF0F0F0);
  static const Color _fieldIconColor = Color(0xFFBDBDBD);

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
  bool _isSubmitting = false;
  bool _usedAutoFill = false;
  String _selectedCategory = '카페';
  CouponType _selectedCouponType = CouponType.barcode;

  static const Map<String, List<String>> _brandAliases = {
    AppStrings.brandStarbucks: ['스타벅스', 'starbucks'],
    AppStrings.brandCu: ['cu'],
    AppStrings.brandGs25: ['gs25', 'gs 25'],
    AppStrings.brandOliveYoung: ['올리브영', 'olive young'],
    AppStrings.brandBbq: ['bbq'],
    AppStrings.brandBaskin: ['배스킨', '배스킨라빈스', 'baskin', 'baskin robbins'],
    AppStrings.brandParisBaguette: ['파리바게뜨', '파리 바게뜨', 'paris baguette'],
    AppStrings.brandAbcMart: ['abc마트', 'abc mart'],
    AppStrings.brandDomino: ['도미노', '도미노피자', 'domino'],
    '투썸플레이스': ['투썸', '투썸플레이스', 'a twosome place'],
    '메가MGC커피': ['메가커피', '메가 mgc', 'megacoffee'],
    '빽다방': ['빽다방'],
    '컴포즈커피': ['컴포즈', 'compose coffee'],
    '이디야커피': ['이디야', 'ediya'],
    '뚜레쥬르': ['뚜레쥬르', 'tous les jours'],
    '교촌치킨': ['교촌', '교촌치킨'],
    'BHC': ['bhc'],
    '버거킹': ['버거킹', 'burger king'],
    '맥도날드': ['맥도날드', 'mcdonald'],
    '롯데리아': ['롯데리아', 'lotteria'],
    '피자헛': ['피자헛', 'pizza hut'],
    '세븐일레븐': ['세븐일레븐', '7-eleven', 'seven eleven'],
  };

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

  bool get _isExtractEnabled =>
      (_selectedImage != null || (_selectedImagePath?.isNotEmpty ?? false)) &&
      !_isProcessingImage;

  bool get _isFormValid =>
      _barcodeController.text.trim().isNotEmpty &&
      _couponNameController.text.trim().isNotEmpty &&
      _brandController.text.trim().isNotEmpty &&
      _selectedDate != null;

  @override
  // 화면 또는 객체가 처음 생성될 때 필요한 초기 설정을 수행한다.
  void initState() {
    super.initState();
    final coupon = widget.coupon;
    if (coupon != null) {
      _barcodeController.text = coupon.barcodeNumber;
      _couponNameController.text = coupon.name;
      _brandController.text = coupon.brand;
      _memoController.text = coupon.memo ?? '';
      _selectedCategory = coupon.category;
      _selectedDate = _tryParseDate(coupon.expiry);
      _selectedImageBytes = coupon.imageBytes;
      _selectedImagePath = coupon.imagePath;
    }

    if (widget.preloadedImage != null) {
      _selectedImagePath = widget.preloadedImage!.path;
      _selectedImage = XFile(widget.preloadedImage!.path);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _extractFromImage();
      });
    }
  }

  @override
  // 사용이 끝난 리소스를 정리한다.
  void dispose() {
    _barcodeController.dispose();
    _couponNameController.dispose();
    _brandController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // 사용자에게 선택 흐름을 열고 결과를 반영한다.
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

  // 다이얼로그, 시트, 상세 화면 등 표시 흐름을 담당한다.
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

  // 현재 상태를 바탕으로 표시용 데이터나 UI 조각을 만든다.
  Widget _buildSelectedImage(BoxFit fit) {
    if (kIsWeb || (_selectedImage == null && _selectedImageBytes != null)) {
      return Image.memory(_selectedImageBytes!, fit: fit);
    }
    if (_selectedImage != null) {
      return Image.file(File(_selectedImage!.path), fit: fit);
    }
    return Image.file(File(_selectedImagePath!), fit: fit);
  }

  // 입력값에서 필요한 정보만 추출한다.
  Future<void> _extractFromImage() async {
    await _runImageOcr();
  }

  // 여러 단계를 포함한 주요 실행 흐름을 처리한다.
  Future<void> _runImageOcr() async {
    // OCR은 "이미지 선택 -> 코드 감지 -> 텍스트 감지 -> 자동 입력 후보 생성"
    // 순서로 동작한다. 여기서는 사용자에게 보이는 성공/실패 메시지까지 맡는다.
    const analyticsSource = 'coupon_create';
    await AnalyticsService().logImageExtractAttempted(source: analyticsSource);

    if (kIsWeb) {
      await AnalyticsService().logImageExtractFailed(
        source: analyticsSource,
        reason: 'web_unsupported',
      );
      _showMessage(AppStrings.couponOcrWebUnsupported);
      return;
    }

    final imagePath = _selectedImage?.path ?? _selectedImagePath;
    if (imagePath == null) {
      await AnalyticsService().logImageExtractFailed(
        source: analyticsSource,
        reason: 'no_image',
      );
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
      await AnalyticsService().logImageExtractFailed(
        source: analyticsSource,
        reason: 'not_recognized',
      );
      _showMessage(AppStrings.couponExtractFailed);
      return;
    }

    final categoryResolved =
        _resolveCategoryFromExtractedData(extracted) != null;
    _applyAutoFillResult(extracted);
    await AnalyticsService().logImageExtractSucceeded(
      source: analyticsSource,
      couponType: extracted.couponType,
      categoryResolved: categoryResolved,
    );
    final missingRequiredFields = _resolveMissingRequiredExtractFields(extracted);
    if (missingRequiredFields.isEmpty) {
      _showMessage(AppStrings.couponExtractFilled);
      return;
    }

    _showMessage(
      '${AppStrings.couponExtractMissingPrefix}'
      '${missingRequiredFields.join(', ')}',
    );
  }

  // applyAutoFillResult 관련 처리를 수행한다.
  void _applyAutoFillResult(_AutoFillExtractionResult extracted) {
    // 인식값만 선택적으로 폼에 주입한다.
    // 부분 인식 상황이 많아서 기존 수동 입력값을 무조건 덮지 않도록 구성했다.
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

  List<String> _resolveMissingRequiredExtractFields(
    _AutoFillExtractionResult extracted,
  ) {
    final missing = <String>[];

    if (extracted.detectedCode == AppStrings.couponNoDetectedCode) {
      missing.add(AppStrings.couponFieldCode);
    }
    if (extracted.title == AppStrings.couponPartialResultTitle ||
        extracted.title == AppStrings.couponNoDetectionTitle ||
        extracted.title.trim().isEmpty) {
      missing.add(AppStrings.couponFieldTitle);
    }
    if (extracted.brand == AppStrings.couponUnknown ||
        extracted.brand.trim().isEmpty) {
      missing.add(AppStrings.couponFieldBrand);
    }
    if (extracted.expiryDate == AppStrings.couponUnknown ||
        extracted.expiryDate.trim().isEmpty) {
      missing.add(AppStrings.couponFieldExpiry);
    }

    return missing;
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

  // 사용자에게 선택 흐름을 열고 결과를 반영한다.
  Future<void> _pickDate() async {
    final minDate = DateTime(2000, 1, 1);
    final maxDate = DateTime(2099, 12, 31);
    final initialDate = _selectedDate == null
        ? DateTime.now()
        : DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          );

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var wheelDate = initialDate;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text(
                          AppStrings.couponCancel,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: () =>
                            Navigator.pop(sheetContext, wheelDate),
                        child: const Text(
                          AppStrings.couponDatePickerDone,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64CAFA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 216,
                  child: Localizations.override(
                    context: sheetContext,
                    locale: const Locale('ko', 'KR'),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      dateOrder: DatePickerDateOrder.ymd,
                      initialDateTime: initialDate,
                      minimumDate: minDate,
                      maximumDate: maxDate,
                      onDateTimeChanged: (date) {
                        wheelDate = date;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  // 입력값에서 필요한 정보만 추출한다.
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
      final imageHeight = await _resolveImageHeight(imagePath);
      final titleCandidateLines = _buildTitleCandidateLines(
        recognizedText,
        imageHeight: imageHeight,
      );

      return _DetectedCouponText(
        rawText: rawText,
        brand: _extractBrand(lines),
        expiryDate: _extractExpiryDate(rawText),
        title: _extractTitle(titleCandidateLines),
      );
    } catch (_) {
      return null;
    } finally {
      textRecognizer.close();
    }
  }

  // 입력 데이터에서 필요한 값을 탐지한다.
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

  // couponTypeLabelForBarcode 관련 처리를 수행한다.
  String _couponTypeLabelForBarcode(Barcode barcode) {
    if (barcode.format == BarcodeFormat.qrCode || barcode.type == BarcodeType.url) {
      return AppStrings.couponTypeQr;
    }
    return AppStrings.couponTypeBarcode;
  }

  // barcodeFormatLabel 관련 처리를 수행한다.
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

    for (final entry in _brandAliases.entries) {
      for (final alias in entry.value) {
        if (normalizedText.contains(alias.toLowerCase())) {
          return entry.key;
        }
      }
    }

    const labelKeywords = ['브랜드', '교환처', '사용처', '매장', '상호'];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final normalizedLine = line.toLowerCase();
      for (final keyword in labelKeywords) {
        if (!normalizedLine.contains(keyword.toLowerCase())) {
          continue;
        }

        final inlineValue = line
            .replaceFirst(RegExp('^.*?$keyword[:：]?', caseSensitive: false), '')
            .trim();
        final matchedInline = _matchKnownBrand(inlineValue);
        if (matchedInline != null) {
          return matchedInline;
        }

        if (i + 1 < lines.length) {
          final matchedNext = _matchKnownBrand(lines[i + 1].trim());
          if (matchedNext != null) {
            return matchedNext;
          }
        }
      }
    }

    for (final line in lines) {
      final matchedBrand = _matchKnownBrand(line);
      if (matchedBrand != null) {
        return matchedBrand;
      }
    }

    return null;
  }

  String? _extractExpiryDate(String rawText) {
    // 날짜는 점/하이픈/공백/한글 표기 등 변형이 많아서
    // 키워드가 있는 줄을 먼저 보고, 못 찾으면 전체 텍스트에서 한 번 더 찾는다.
    final lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (final line in lines) {
      if (_containsExpiryKeyword(line)) {
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

  // containsExpiryKeyword 관련 처리를 수행한다.
  bool _containsExpiryKeyword(String line) {
    const expiryKeywords = <String>[
      '유효기간',
      '유효 기간',
      '유효기한',
      '사용기한',
      '이용기한',
      '유효일',
      '만료일',
    ];

    if (line.contains(AppStrings.couponUsePeriodKeyword) ||
        line.contains(AppStrings.couponPeriodKeyword)) {
      return true;
    }

    return expiryKeywords.any(line.contains);
  }

  // 입력값에서 필요한 정보만 추출한다.
  List<String> _extractAllDates(String rawText) {
    final normalizedText = rawText
        .replaceAll('·', '.')
        .replaceAll('ㆍ', '.')
        .replaceAll('•', '.')
        .replaceAll('。', '.')
        .replaceAll(',', '.')
        .replaceAll(':', '.')
        .replaceAll(';', '.');
    final patterns = [
      RegExp(r'(20\d{2})년\s*(\d{1,2})월\s*(\d{1,2})일'),
      RegExp(r'(20\d{2})\s*[./\-\s]\s*(\d{1,2})\s*[./\-\s]\s*(\d{1,2})'),
      RegExp(r'(\d{2})\s*[./-]\s*(\d{1,2})\s*[./-]\s*(\d{1,2})'),
      RegExp(r'(?<!\d)(20\d{2})(\d{2})(\d{2})(?!\d)'),
    ];
    final detectedDates = <String>[];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(normalizedText)) {
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

  String? _extractTitle(List<_OcrLineCandidate> lines) {
    // 제목은 기본 1줄, 최대 2줄까지만 허용한다.
    // 그 이상 붙이면 상태바/설명 문구가 섞일 가능성이 높다.
    for (var i = 0; i < lines.length; i++) {
      final currentLine = lines[i].text;
      if (!_isTitleCandidate(currentLine)) {
        continue;
      }

      final titleLines = <String>[currentLine];

      for (var j = i + 1; j < lines.length; j++) {
        final nextLine = lines[j].text;
        if (!_isTitleContinuationCandidate(nextLine)) {
          break;
        }
        titleLines.add(nextLine);
        if (titleLines.length >= 2) {
          break;
        }
      }

      return titleLines.join('\n');
    }

    return null;
  }

  // normalizeOcrLine 관련 처리를 수행한다.
  String _normalizeOcrLine(String line) {
    return line.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // 주어진 값이나 상태가 조건을 만족하는지 검사한다.
  bool _isTitleCandidate(String line) {
    if (line.length < 4) {
      return false;
    }
    if (_looksLikeStatusBarText(line)) {
      return false;
    }
    if (RegExp(r'^\d[\d\s./:-]+$').hasMatch(line)) {
      return false;
    }
    if (line.contains(AppStrings.couponInfoKeyword) ||
        line.contains('barcode') ||
        line.contains('qr') ||
        line.contains(AppStrings.couponExpiryKeyword) ||
        line.contains('브랜드') ||
        line.contains('교환처') ||
        line.contains('사용처')) {
      return false;
    }
    if (_matchKnownBrand(line) != null) {
      return false;
    }

    return true;
  }

  // 주어진 값이나 상태가 조건을 만족하는지 검사한다.
  bool _isTitleContinuationCandidate(String line) {
    if (!_isTitleCandidate(line)) {
      return false;
    }

    if (line.length <= 2) {
      return false;
    }
    if (_containsDateLikeText(line)) {
      return false;
    }
    if (line.contains(AppStrings.couponUsePeriodKeyword) ||
        line.contains(AppStrings.couponPeriodKeyword) ||
        line.contains('유효') ||
        line.contains('기한') ||
        line.contains('교환') ||
        line.contains('사용처')) {
      return false;
    }

    return true;
  }

  // containsDateLikeText 관련 처리를 수행한다.
  bool _containsDateLikeText(String line) {
    return RegExp(r'(20\d{2}|\d{2})[./-]\s?\d{1,2}[./-]\s?\d{1,2}')
            .hasMatch(line) ||
        RegExp(r'20\d{2}년\s*\d{1,2}월\s*\d{1,2}일').hasMatch(line);
  }

  // looksLikeStatusBarText 관련 처리를 수행한다.
  bool _looksLikeStatusBarText(String line) {
    final normalized = line.toLowerCase();
    if (RegExp(r'^(오전|오후)?\s*\d{1,2}:\d{2}$').hasMatch(line)) {
      return true;
    }
    if (RegExp(r'^\d{1,2}:\d{2}\s*(am|pm)?$', caseSensitive: false).hasMatch(line)) {
      return true;
    }
    if (RegExp(r'^\d{1,3}%$').hasMatch(line)) {
      return true;
    }
    const statusBarKeywords = ['5g', 'lte', 'skt', 'kt', 'u+', 'battery', '알림'];
    return statusBarKeywords.any(normalized.contains);
  }

  // 현재 맥락에서 사용할 값을 계산하거나 선택한다.
  Future<double?> _resolveImageHeight(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = await decodeImageFromList(bytes);
      final height = image.height.toDouble();
      image.dispose();
      return height;
    } catch (_) {
      return null;
    }
  }

  List<_OcrLineCandidate> _buildTitleCandidateLines(
    RecognizedText recognizedText, {
    required double? imageHeight,
  }) {
    final exclusionThreshold = imageHeight == null
        ? null
        : imageHeight * _ocrTopExclusionRatio;
    final lines = <_OcrLineCandidate>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = _normalizeOcrLine(line.text);
        if (text.isEmpty) {
          continue;
        }

        final top = line.boundingBox.top.toDouble();
        final bottom = line.boundingBox.bottom.toDouble();

        if (exclusionThreshold != null && top < exclusionThreshold) {
          continue;
        }

        lines.add(
          _OcrLineCandidate(
            text: text,
            top: top,
            bottom: bottom,
          ),
        );
      }
    }

    lines.sort((a, b) {
      final topCompare = a.top.compareTo(b.top);
      if (topCompare != 0) {
        return topCompare;
      }
      return a.bottom.compareTo(b.bottom);
    });

    return lines;
  }

  // UI 이벤트 진입점 역할을 한다.
  Future<void> _onSubmit() async {
    await _submitForm();
  }

  // submitForm 관련 처리를 수행한다.
  Future<void> _submitForm() async {
    // 저장은 "DB 저장"과 "저장 후 후처리"를 분리한다.
    // 후처리(알림 재예약, analytics) 실패가 있어도 쿠폰 저장 자체는 성공으로 본다.
    if (_isSubmitting) {
      return;
    }
    FocusScope.of(context).unfocus();
    final title = _couponNameController.text.trim();
    final brand = _brandController.text.trim();
    final barcodeNumber = _barcodeController.text.trim();

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
    if (CouponRepository.findByBarcodeNumber(
          barcodeNumber,
          excludingId: widget.coupon?.id,
        ) !=
        null) {
      _showMessage(AppStrings.couponDuplicateCode);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final savedCoupon = CouponDetailModel(
        id:
            widget.coupon?.id ??
            'coupon_${DateTime.now().microsecondsSinceEpoch}',
        brand: brand,
        name: title,
        category: _selectedCategory,
        dday: _calculateDday(_selectedDate!),
        expiry: _formatSelectedDate(_selectedDate!),
        barcodeNumber: barcodeNumber,
        imagePath:
            _selectedImage?.path ?? _selectedImagePath ?? widget.coupon?.imagePath,
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
      try {
        final settings = SettingsRepository.load();
        final notificationService = NotificationService();

        if (widget.coupon != null) {
          await notificationService.cancelCouponNotifications(widget.coupon!.id);
        }
        await notificationService.scheduleCouponNotifications(
          repositoryCoupon,
          settings,
        );

        if (widget.coupon == null) {
          await AnalyticsService().logCouponCreated(
            category: repositoryCoupon.category,
            couponType:
                repositoryCoupon.couponType ?? AppStrings.couponTypeBarcode,
            entryType: _usedAutoFill
                ? AppStrings.couponEntryAuto
                : AppStrings.couponEntryManual,
            hasImage: repositoryCoupon.imagePath != null ||
                repositoryCoupon.imageBytes != null,
            dday: repositoryCoupon.dday,
          );
        }
      } catch (error, stackTrace) {
        debugPrint('Coupon post-save side effects failed: $error');
        await AnalyticsService().recordNonFatal(error, stackTrace);
      }

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(repositoryCoupon);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(AppStrings.couponRegistered),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      _showMessage(AppStrings.couponSaveFailed);
    }
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

  // calculateDday 관련 처리를 수행한다.
  int _calculateDday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  // 표시용 문자열로 값을 변환한다.
  String _formatSelectedDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }

  String? _matchKnownBrand(String text) {
    final normalizedText = text.toLowerCase().replaceAll(' ', '');
    if (normalizedText.isEmpty) {
      return null;
    }

    for (final entry in _brandAliases.entries) {
      for (final alias in entry.value) {
        final normalizedAlias = alias.toLowerCase().replaceAll(' ', '');
        if (normalizedText.contains(normalizedAlias)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  // 다이얼로그, 시트, 상세 화면 등 표시 흐름을 담당한다.
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

  // 문자열 또는 원시 데이터를 앱 모델 값으로 변환한다.
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

  // tryParseDate 관련 처리를 수행한다.
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
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 24;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(-14, 0),
                  child: IconButton(
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
                  minLines: 1,
                  maxLines: 2,
                  prefixIcon: const Icon(
                    Icons.confirmation_number_outlined,
                    size: 20,
                    color: _fieldIconColor,
                  ),
                  onChanged: (_) => setState(() {}),
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
                    color: _fieldIconColor,
                  ),
                  onChanged: (_) => setState(() {}),
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
                                color: _fieldFillColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: _fieldIconColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedDate == null
                                        ? 'yyyy / mm / dd'
                                        : '${_selectedDate!.year} / ${_selectedDate!.month.toString().padLeft(2, '0')} / ${_selectedDate!.day.toString().padLeft(2, '0')}',
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
                              color: _fieldFillColor,
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
                                  color: _fieldIconColor,
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
                    onPressed: _isFormValid && !_isSubmitting
                        ? () => _onSubmit()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid && !_isSubmitting
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
                      _isSubmitting
                          ? '저장 중...'
                          : widget.coupon == null
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

// DetectedCouponCode 관련 역할을 담당하는 클래스.
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

// DetectedCouponText 관련 역할을 담당하는 클래스.
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

// OcrLineCandidate 관련 역할을 담당하는 클래스.
class _OcrLineCandidate {
  const _OcrLineCandidate({
    required this.text,
    required this.top,
    required this.bottom,
  });

  final String text;
  final double top;
  final double bottom;
}

// AutoFillExtractionResult 관련 역할을 담당하는 클래스.
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

// CouponType 상태 값을 정의하는 enum.
enum CouponType {
  barcode(AppStrings.couponTypeBarcode),
  qr(AppStrings.couponTypeQr),
  none(AppStrings.couponTypeNone);

  const CouponType(this.label);

  final String label;
}

// CouponImagePicker 관련 역할을 담당하는 클래스.
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
  // 현재 상태를 기준으로 화면 UI를 구성한다.
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

// ExtractButton 관련 역할을 담당하는 클래스.
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
  // 현재 상태를 기준으로 화면 UI를 구성한다.
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

// RequiredLabel 관련 역할을 담당하는 클래스.
class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel(this.text);

  final String text;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
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

// OptionalLabel 관련 역할을 담당하는 클래스.
class _OptionalLabel extends StatelessWidget {
  const _OptionalLabel(this.text);

  final String text;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
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

// FilledTextField 관련 역할을 담당하는 클래스.
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
  // 현재 상태를 기준으로 화면 UI를 구성한다.
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

// CouponBarcodePreview 관련 역할을 담당하는 클래스.
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
  // 현재 상태를 기준으로 화면 UI를 구성한다.
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

// DashedBorderPainter 커스텀 페인터 역할을 담당하는 클래스.
class DashedBorderPainter extends CustomPainter {
  @override
  // paint 관련 처리를 수행한다.
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
  // shouldRepaint 관련 처리를 수행한다.
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
