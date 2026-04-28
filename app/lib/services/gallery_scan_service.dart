import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/scanned_image_store.dart';

enum CouponConfidence { high, medium, low }

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

  void warmUp() {
    if (kIsWeb) {
      return;
    }
    _barcodeScanner ??= BarcodeScanner();
    _textRecognizer ??=
        TextRecognizer(script: TextRecognitionScript.korean);
  }

  Future<void> dispose() async {
    await _barcodeScanner?.close();
    await _textRecognizer?.close();
    _barcodeScanner = null;
    _textRecognizer = null;
  }

  Future<bool> checkAndRequestPermission() async {
    if (kIsWeb) {
      return false;
    }
    if (Platform.isAndroid) {
      final state = await PhotoManager.requestPermissionExtend();
      return state.isAuth || state.hasAccess;
    } else if (Platform.isIOS) {
      final state = await PhotoManager.requestPermissionExtend();
      return state.isAuth || state.hasAccess;
    }
    return false;
  }

  Future<List<DetectedCouponImage>> scanNewImages() async {
    return scanNewImagesWithOptions();
  }

  Future<List<DetectedCouponImage>> scanNewImagesWithOptions({
    bool respectAutoSetting = true,
    bool respectDailyLimit = true,
    bool forceRescan = false,
  }) async {
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

  Future<void> resetScanState() async {
    await ScannedImageStore.clearProcessedState();
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (key.startsWith('scan_count_')) {
        await prefs.remove(key);
      }
    }
  }

  Future<DetectedCouponImage?> _analyzeImage(AssetEntity asset) async {
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
}
