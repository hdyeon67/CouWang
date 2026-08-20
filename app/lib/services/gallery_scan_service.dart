// 갤러리 쿠폰 감지 핵심 서비스.
//
// 사용자가 포토 피커로 직접 고른 이미지들만 받아서, 쿠폰 후보 판별과 중복 감지를
// 수행한다. 갤러리 전체를 열거하던 자동 스캔 방식은 Google Play "사진 및 동영상
// 권한 정책"을 피하기 위해 제거했고, READ_MEDIA_IMAGES 권한 없이 동작한다.
//
// OCR/바코드 분석은 모두 Future 기반 비동기로 수행하고, 성능을 위해 한 번에
// 분석하는 이미지 수를 제한한다.
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../repositories/coupon_repository.dart';
import '../utils/scanned_image_store.dart';

// CouponConfidence 상태 값을 정의하는 enum.
enum CouponConfidence { high, medium, low }

// 감지 결과에서 "등록 후보로 보여줄 이미지 1건"을 표현하는 모델.
class DetectedCouponImage {
  const DetectedCouponImage({
    required this.file,
    required this.imageHash,
    required this.confidence,
  });

  final File file;
  final String imageHash;
  final CouponConfidence confidence;
}

// 사용자가 고른 이미지에서 쿠폰 후보를 판별하는 서비스.
class GalleryScanService {
  GalleryScanService._internal();

  static final GalleryScanService _instance = GalleryScanService._internal();

  factory GalleryScanService() => _instance;

  // 한 번에 분석하는 이미지 수 상한. 포토 피커에서 많은 장을 골라도 성능을 지킨다.
  static const int maxScanImages = 50;

  static const List<String> _couponKeywords = <String>[
    '유효기간',
    '유효 기간',
    '유효기한',
    '사용기한',
    '만료일',
    '교환권',
    '기프티콘',
    '쿠폰',
    '상품권',
    '까지 사용',
    '이용기한',
    '유효일',
  ];

  BarcodeScanner? _barcodeScanner;
  TextRecognizer? _textRecognizer;

  // ML Kit 인스턴스를 미리 준비해 첫 스캔 지연을 줄인다.
  void warmUp() {
    if (kIsWeb) {
      return;
    }
    _barcodeScanner ??= BarcodeScanner();
    _textRecognizer ??=
        TextRecognizer(script: TextRecognitionScript.korean);
  }

  // 사용이 끝난 리소스를 정리한다.
  Future<void> dispose() async {
    await _barcodeScanner?.close();
    await _textRecognizer?.close();
    _barcodeScanner = null;
    _textRecognizer = null;
  }

  // 사용자가 포토 피커로 직접 고른 이미지들을 분석해 쿠폰 후보만 골라 돌려준다.
  //
  // 갤러리 전체 접근 권한이 필요 없고, 넘어온 파일만 순차적으로 분석한다.
  Future<List<DetectedCouponImage>> analyzePickedImages(
    List<File> files,
  ) async {
    if (kIsWeb || files.isEmpty) {
      return const <DetectedCouponImage>[];
    }

    warmUp();

    final detected = <DetectedCouponImage>[];
    for (final file in files.take(maxScanImages)) {
      final image = await _analyzeImage(file);
      if (image != null) {
        detected.add(image);
      }
    }
    return detected;
  }

  // 감지 이력(등록/거절 해시)을 초기화한다.
  Future<void> resetScanState() async {
    await ScannedImageStore.clearProcessedState();
  }

  // analyzeImage 관련 처리를 수행한다.
  Future<DetectedCouponImage?> _analyzeImage(File file) async {
    // 후보 판정은 "해시 중복 확인 -> 바코드 감지 -> OCR 키워드 감지 ->
    // 기존 저장 쿠폰 비교" 순으로 진행한다.
    if (!file.existsSync()) {
      return null;
    }

    final bytes = await file.readAsBytes();
    final hash = generateImageHash(bytes);
    if (await ScannedImageStore.isProcessed(hash)) {
      return null;
    }

    final inputImage = InputImage.fromFile(file);

    final barcodes = await (_barcodeScanner ??= BarcodeScanner()).processImage(
      inputImage,
    );
    final hasBarcode = barcodes.isNotEmpty;
    final barcodeValue = _resolveBarcodeValue(barcodes);

    final recognized =
        await (_textRecognizer ??=
                TextRecognizer(script: TextRecognitionScript.korean))
            .processImage(inputImage);

    bool hasKeyword = false;
    for (final block in recognized.blocks) {
      for (final keyword in _couponKeywords) {
        if (block.text.contains(keyword)) {
          hasKeyword = true;
          break;
        }
      }
      if (hasKeyword) {
        break;
      }
    }

    if (!hasBarcode && !hasKeyword) {
      return null;
    }

    final extractedText = recognized.text;
    final extractedExpiry = _extractExpiryDate(extractedText);
    final extractedTitle = _extractTitle(recognized);
    if (_matchesExistingCoupon(
      barcodeValue: barcodeValue,
      extractedTitle: extractedTitle,
      extractedExpiry: extractedExpiry,
    )) {
      return null;
    }

    final confidence = hasBarcode && hasKeyword
        ? CouponConfidence.high
        : CouponConfidence.medium;

    return DetectedCouponImage(
      file: file,
      imageHash: hash,
      confidence: confidence,
    );
  }

  String? _resolveBarcodeValue(List<Barcode> barcodes) {
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue?.isNotEmpty ?? false) {
        return rawValue;
      }
      final displayValue = barcode.displayValue?.trim();
      if (displayValue?.isNotEmpty ?? false) {
        return displayValue;
      }
    }
    return null;
  }

  bool _matchesExistingCoupon({
    required String? barcodeValue,
    required String? extractedTitle,
    required String? extractedExpiry,
  }) {
    if (barcodeValue != null &&
        CouponRepository.findByBarcodeNumber(barcodeValue) != null) {
      return true;
    }

    final normalizedTitle = _normalizeComparisonText(extractedTitle);
    final normalizedExpiry = _normalizeDateText(extractedExpiry);
    if (normalizedTitle.isEmpty || normalizedExpiry.isEmpty) {
      return false;
    }

    for (final coupon in CouponRepository.getAll()) {
      final sameTitle =
          _normalizeComparisonText(coupon.name) == normalizedTitle;
      final sameExpiry =
          _normalizeDateText(coupon.expiry) == normalizedExpiry;
      if (sameTitle && sameExpiry) {
        return true;
      }
    }
    return false;
  }

  // normalizeComparisonText 관련 처리를 수행한다.
  String _normalizeComparisonText(String? value) {
    if (value == null) {
      return '';
    }
    return value.replaceAll(RegExp(r'\s+'), '').trim().toLowerCase();
  }

  // normalizeDateText 관련 처리를 수행한다.
  String _normalizeDateText(String? value) {
    if (value == null) {
      return '';
    }
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String? _extractExpiryDate(String rawText) {
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
      '만료일',
      '이용기한',
      '유효일',
    ];

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

    final patterns = <RegExp>[
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

  String? _extractTitle(RecognizedText recognizedText) {
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.length < 4) {
          continue;
        }
        if (_containsExpiryKeyword(text)) {
          continue;
        }
        if (RegExp(r'^[0-9\s./:-]+$').hasMatch(text)) {
          continue;
        }
        return text;
      }
    }
    return null;
  }
}
