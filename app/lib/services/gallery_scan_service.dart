// 갤러리 자동 감지 핵심 서비스.
//
// 최근 저장 이미지 조회, 쿠폰 후보 판별, 중복 감지, 스캔 빈도 제한을 한곳에 모은다.
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/coupon_repository.dart';
import '../utils/scanned_image_store.dart';

// CouponConfidence 상태 값을 정의하는 enum.
enum CouponConfidence { high, medium, low }

// DetectedCouponImage 관련 역할을 담당하는 클래스.
class DetectedCouponImage {
  const DetectedCouponImage({
    required this.asset,
    required this.file,
    required this.imageHash,
    required this.confidence,
  });

  final AssetEntity asset;
  final File file;
  final String imageHash;
  final CouponConfidence confidence;
}

// 갤러리 자동 감지 흐름을 담당하는 서비스.
class GalleryScanService {
  GalleryScanService._internal();

  static final GalleryScanService _instance = GalleryScanService._internal();

  factory GalleryScanService() => _instance;

  static const String autoScanEnabledKey = 'auto_scan_enabled';
  static const String autoScanGuideShownKey = 'auto_scan_guide_shown';
  static const int maxScanImages = 50;
  static const int scanRangeDays = 30;
  static const int maxDailyScans = 5;

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

  // warmUp 관련 처리를 수행한다.
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

  // checkAndRequestPermission 관련 처리를 수행한다.
  Future<bool> checkAndRequestPermission() async {
    if (kIsWeb) {
      return false;
    }
    final currentStatus = await _currentPhotoPermissionStatus();
    if (_isGranted(currentStatus)) {
      return true;
    }

    final requestedStatus = await _requestPhotoPermission();
    return _isGranted(requestedStatus);
  }

  // hasPermission 관련 처리를 수행한다.
  Future<bool> hasPermission() async {
    if (kIsWeb) {
      return false;
    }
    final currentStatus = await _currentPhotoPermissionStatus();
    return _isGranted(currentStatus);
  }

  // currentPhotoPermissionStatus 관련 처리를 수행한다.
  Future<PermissionStatus> _currentPhotoPermissionStatus() async {
    final photoStatus = await Permission.photos.status;
    if (_isGranted(photoStatus)) {
      return photoStatus;
    }

    final storageStatus = await Permission.storage.status;
    return _isGranted(storageStatus) ? storageStatus : photoStatus;
  }

  // 외부 권한이나 리소스를 요청한다.
  Future<PermissionStatus> _requestPhotoPermission() async {
    final photoStatus = await Permission.photos.request();
    if (_isGranted(photoStatus)) {
      return photoStatus;
    }

    final storageStatus = await Permission.storage.request();
    return _isGranted(storageStatus) ? storageStatus : photoStatus;
  }

  // 주어진 값이나 상태가 조건을 만족하는지 검사한다.
  bool _isGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  Future<List<DetectedCouponImage>> scanNewImages() async {
    return scanNewImagesWithOptions();
  }

  Future<List<DetectedCouponImage>> scanNewImagesWithOptions({
    bool respectAutoSetting = true,
    bool respectDailyLimit = true,
    bool forceRescan = false,
  }) async {
    // 자동 감지는 설정값, 권한, 일일 제한을 모두 통과해야 실제 스캔을 시작한다.
    final prefs = await SharedPreferences.getInstance();
    final autoScanEnabled = prefs.getBool(autoScanEnabledKey) ?? false;
    if (respectAutoSetting && !autoScanEnabled) {
      return const <DetectedCouponImage>[];
    }

    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      return const <DetectedCouponImage>[];
    }

    final canScanToday = await _canScanToday();
    if (respectDailyLimit && !canScanToday) {
      return const <DetectedCouponImage>[];
    }

    warmUp();

    final assets = await _fetchNewImages(ignoreLastScan: forceRescan);
    if (assets.isEmpty) {
      return const <DetectedCouponImage>[];
    }

    final detected = <DetectedCouponImage>[];
    for (final asset in assets) {
      final image = await _analyzeImage(asset);
      if (image != null) {
        detected.add(image);
      }
    }
    return detected;
  }

  // 현재 조건에서 동작 가능 여부를 판단한다.
  Future<bool> _canScanToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'scan_count_$today';
    final count = prefs.getInt(key) ?? 0;
    if (count >= maxDailyScans) {
      return false;
    }
    await prefs.setInt(key, count + 1);
    return true;
  }

  Future<List<AssetEntity>> _fetchNewImages({
    bool ignoreLastScan = false,
  }) async {
    // photo_manager는 앨범별로 결과를 주기 때문에, id 중복 제거와 최근순 정렬을
    // 서비스 레벨에서 다시 맞춰준다.
    final lastScan = await ScannedImageStore.getLastScanTime();
    final now = DateTime.now();
    final minDate = now.subtract(const Duration(days: scanRangeDays));

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    final assets = <AssetEntity>[];
    final seenIds = <String>{};

    for (final album in albums) {
      if (assets.length >= maxScanImages) {
        break;
      }
      final items = await album.getAssetListRange(start: 0, end: maxScanImages);
      for (final asset in items) {
        if (assets.length >= maxScanImages) {
          break;
        }
        if (!seenIds.add(asset.id)) {
          continue;
        }

        final createdAt = asset.createDateTime;
        final modifiedAt = asset.modifiedDateTime;
        final latestDate = modifiedAt.isAfter(createdAt) ? modifiedAt : createdAt;

        if (latestDate.isBefore(minDate)) {
          continue;
        }
        if (!ignoreLastScan &&
            lastScan != null &&
            !latestDate.isAfter(lastScan)) {
          continue;
        }
        assets.add(asset);
      }
    }

    assets.sort((a, b) {
      final aDate = a.modifiedDateTime.isAfter(a.createDateTime)
          ? a.modifiedDateTime
          : a.createDateTime;
      final bDate = b.modifiedDateTime.isAfter(b.createDateTime)
          ? b.modifiedDateTime
          : b.createDateTime;
      return bDate.compareTo(aDate);
    });

    await ScannedImageStore.saveLastScanTime(now);
    return assets.take(maxScanImages).toList();
  }

  // 관련 상태를 초기값으로 되돌린다.
  Future<void> resetScanState() async {
    await ScannedImageStore.clearProcessedState();
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (key.startsWith('scan_count_')) {
        await prefs.remove(key);
      }
    }
  }

  // analyzeImage 관련 처리를 수행한다.
  Future<DetectedCouponImage?> _analyzeImage(AssetEntity asset) async {
    // 후보 판정은 "해시 중복 확인 -> 바코드 감지 -> OCR 키워드 감지 ->
    // 기존 저장 쿠폰 비교" 순으로 진행한다.
    final bytes = await asset.thumbnailDataWithSize(
      const ThumbnailSize(800, 800),
    );
    if (bytes == null) {
      return null;
    }

    final hash = generateImageHash(bytes);
    if (await ScannedImageStore.isProcessed(hash)) {
      return null;
    }

    final file = await asset.file;
    if (file == null) {
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
      asset: asset,
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
