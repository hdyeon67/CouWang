import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_spacing.dart';

class CouponCameraScanScreen extends StatefulWidget {
  const CouponCameraScanScreen({super.key});

  @override
  State<CouponCameraScanScreen> createState() => _CouponCameraScanScreenState();
}

class _CouponCameraScanScreenState extends State<CouponCameraScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
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

  bool _isHandling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_isHandling) {
      return;
    }

    Barcode? barcode;
    for (final item in capture.barcodes) {
      final value = (item.rawValue ?? item.displayValue ?? '').trim();
      if (value.isNotEmpty) {
        barcode = item;
        break;
      }
    }

    if (barcode == null) {
      return;
    }

    _isHandling = true;
    final value = (barcode.rawValue ?? barcode.displayValue ?? '').trim();

    Navigator.of(context).pop(
      CameraScanResult(
        rawValue: value,
        couponTypeLabel: barcode.format == BarcodeFormat.qrCode ? 'QR' : '바코드',
        codeFormatLabel: _formatLabel(barcode.format),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('코드 스캔'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetection,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC101522),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      '바코드 또는 QR 코드를 화면 중앙에 맞춰주세요.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: const Color(0xCC101522),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.viewfinder,
                          color: Color(0xFF8DB2FF),
                          size: 28,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          '스캔되면 자동으로 다음 단계로 넘어갑니다.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF8DB2FF),
                  width: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CameraScanResult {
  const CameraScanResult({
    required this.rawValue,
    required this.couponTypeLabel,
    required this.codeFormatLabel,
  });

  final String rawValue;
  final String couponTypeLabel;
  final String codeFormatLabel;
}
