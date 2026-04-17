import 'dart:io';
import 'dart:typed_data';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/resources/app_strings.dart';
import '../../../../core/widgets/empty_state_mascot.dart';
import '../../../../repositories/coupon_repository.dart';
import '../../../../repositories/membership_repository.dart';
import '../../../../repositories/settings_repository.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/notification_service.dart';
import 'coupon_create_screen.dart';
import '../../../memberships/presentation/screens/membership_detail_screen.dart';

class CouponDetailScreen extends StatefulWidget {
  const CouponDetailScreen({
    super.key,
    this.coupon = const CouponDetailModel(
      name: '카페라떼',
      category: AppStrings.categoryCafe,
      brand: AppStrings.brandStarbucks,
      expiry: '2025.12.10',
      dday: 0,
      barcodeNumber: '7742990122284',
      isUsed: false,
      imagePath: null,
    ),
  });

  final CouponDetailModel coupon;

  @override
  State<CouponDetailScreen> createState() => _CouponDetailScreenState();
}

class _CouponDetailScreenState extends State<CouponDetailScreen> {
  final GlobalKey _menuButtonKey = GlobalKey();
  late bool _isUsed = widget.coupon.isUsed ||
      widget.coupon.status == CouponDetailStatus.redeemed;

  CouponDetailModel get _coupon =>
      CouponRepository.findById(widget.coupon.id) ?? widget.coupon;

  List<_MembershipSheetItem> get _memberships {
    return MembershipRepository.getAll()
        .map((membership) => _MembershipSheetItem.fromMembership(membership))
        .toList();
  }

  void _showContextMenu() {
    final buttonContext = _menuButtonKey.currentContext;
    if (buttonContext == null) {
      return;
    }

    final button = buttonContext.findRenderObject() as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: const [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: Color(0xFF555555)),
              SizedBox(width: 10),
              Text(
                AppStrings.couponEdit,
                style: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Color(0xFFE53935)),
              SizedBox(width: 10),
              Text(
                AppStrings.couponDelete,
                style: TextStyle(fontSize: 14, color: Color(0xFFE53935)),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _navigateToEdit();
      } else if (value == 'delete') {
        _showDeleteDialog();
      }
    });
  }

  void _navigateToEdit() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CouponCreateScreen(coupon: _coupon),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _showDeleteDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            AppStrings.couponDeleteTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: const Text(
            AppStrings.couponDeleteDescription,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                AppStrings.couponCancel,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                await CouponRepository.delete(_coupon.id);
                await NotificationService().cancelCouponNotifications(_coupon.id);
                if (!mounted) {
                  return;
                }
                Navigator.pop(context);
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: const Text(AppStrings.couponDeleteDone),
                      backgroundColor: const Color(0xFF1A1A1A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      duration: const Duration(seconds: 2),
                    ),
                  );
              },
              child: const Text(
                AppStrings.couponDelete,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getDdayColor(int dday) {
    if (dday == 0) return const Color(0xFF55C8FF);
    if (dday <= 1) return const Color(0xFF55C8FF);
    if (dday <= 3) return const Color(0xFF7DD4FF);
    if (dday <= 7) return const Color(0xFFA3E0FF);
    if (dday <= 15) return const Color(0xFFC2EAFF);
    return const Color(0xFFDDF3FF);
  }

  bool get _isExpired => widget.coupon.status == CouponDetailStatus.expired;
  bool get _resolvedIsExpired => _coupon.isExpired;

  bool get _showsQrCode {
    final normalized = _coupon.barcodeNumber.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
  }

  Widget _buildDdayBadge(int dday) {
    late final Color color;
    late final String label;

    if (_isUsed) {
      color = const Color(0xFF8E9AAF);
      label = AppStrings.couponUsed;
    } else if (_resolvedIsExpired || _isExpired) {
      color = const Color(0xFFE58C73);
      label = AppStrings.couponExpired;
    } else {
      color = _getDdayColor(dday);
      label = dday == 0 ? 'D-DAY' : 'D-$dday';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _showFullscreenOverlay({
    required Widget child,
  }) async {
    await Navigator.of(context).push(
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
                  child: Container(
                    color: Colors.transparent,
                    width: double.infinity,
                    height: double.infinity,
                  ),
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
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: Center(child: child)),
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

  void _showImageFullScreen() {
    _showFullscreenOverlay(
      child: InteractiveViewer(
        panEnabled: true,
        minScale: 0.8,
        maxScale: 4.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _CouponImage(
            coupon: _coupon,
            fit: BoxFit.contain,
            fallbackWidth: 300,
            fallbackHeight: 200,
          ),
        ),
      ),
    );
  }

  String _formatBarcodeNumber(String raw) {
    if (_showsQrCode) {
      return raw;
    }
    final digits = raw.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  void _showBarcodeFullScreen() {
    _showFullscreenOverlay(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(
              panEnabled: false,
              minScale: 1.0,
              maxScale: 3.0,
              child: BarcodeWidget(
                barcode: _showsQrCode ? Barcode.qrCode() : Barcode.code128(),
                data: _coupon.barcodeNumber,
                width: _showsQrCode ? 220 : 280,
                height: _showsQrCode ? 220 : 120,
                drawText: false,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatBarcodeNumber(_coupon.barcodeNumber),
              style: TextStyle(
                fontSize: _showsQrCode ? 13 : 20,
                fontWeight: FontWeight.w600,
                letterSpacing: _showsQrCode ? 0 : 3.0,
                color: const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _markAsUsed() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            AppStrings.couponMarkUsedTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: const Text(
            AppStrings.couponMarkUsedDescription,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                AppStrings.couponCancel,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await NotificationService().cancelCouponNotifications(_coupon.id);
                await CouponRepository.markUsed(_coupon.id);
                await AnalyticsService().logCouponUsed(
                  category: _coupon.category,
                  dday: _coupon.dday,
                );
                if (!mounted) {
                  return;
                }
                setState(() {
                  _isUsed = true;
                });
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: const Text(AppStrings.couponMarkUsedDone),
                      backgroundColor: const Color(0xFF1A1A1A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      duration: const Duration(seconds: 2),
                    ),
                  );
              },
              child: const Text(
                AppStrings.couponMarkUsedConfirm,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF55C8FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _markAsUnused() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            AppStrings.couponMarkUnusedTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: const Text(
            AppStrings.couponMarkUnusedDescription,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                AppStrings.couponCancel,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final updated = await CouponRepository.markUnused(_coupon.id);
                if (updated != null) {
                  await NotificationService().scheduleCouponNotifications(
                    updated,
                    SettingsRepository.load(),
                  );
                }
                if (!mounted) {
                  return;
                }
                setState(() {
                  _isUsed = false;
                });
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: const Text(AppStrings.couponMarkUnusedDone),
                      backgroundColor: const Color(0xFF1A1A1A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      duration: const Duration(seconds: 2),
                    ),
                  );
              },
              child: const Text(
                AppStrings.couponMarkUnusedConfirm,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF55C8FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMembershipListBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return _MembershipListSheet(
          memberships: _memberships,
          onClose: () => Navigator.pop(ctx),
          onMembershipTap: (membership) {
            Navigator.pop(ctx);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MembershipDetailScreen(
                  membership: membership.detail,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final coupon = _coupon;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Transform.translate(
                    offset: const Offset(-14, 0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: Color(0xFF222222),
                      ),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 40, height: 40),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    key: _menuButtonKey,
                    icon: const Icon(
                      Icons.more_vert,
                      size: 24,
                      color: Color(0xFF222222),
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 40, height: 40),
                    onPressed: _showContextMenu,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${coupon.category} > ${coupon.brand}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                coupon.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    coupon.expiry,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildDdayBadge(coupon.dday),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showImageFullScreen,
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _CouponImage(
                      coupon: coupon,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _showBarcodeFullScreen,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _showsQrCode
                                      ? AppStrings.couponTypeQr
                                      : AppStrings.couponTypeBarcode,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF55C8FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          BarcodeWidget(
                            barcode: _showsQrCode
                                ? Barcode.qrCode()
                                : Barcode.code128(),
                            data: coupon.barcodeNumber,
                            width: _showsQrCode ? 140 : double.infinity,
                            height: _showsQrCode ? 140 : 80,
                            drawText: false,
                            color: const Color(0xFF1A1A1A),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatBarcodeNumber(coupon.barcodeNumber),
                            style: TextStyle(
                              fontSize: _showsQrCode ? 13 : 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: _showsQrCode ? 0 : 3.0,
                              color: const Color(0xFF1A1A1A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(
                          Icons.fullscreen,
                          size: 22,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/icon/2-1.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.tipTitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE8900A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            AppStrings.tipBody,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isUsed ? _markAsUnused : _markAsUsed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isUsed
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFF55C8FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                  ),
                  child: Text(
                    _isUsed ? AppStrings.couponUsedDone : AppStrings.couponMarkUsed,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _showMembershipListBottomSheet,
                  icon: const Icon(
                    Icons.qr_code_2_outlined,
                    size: 20,
                    color: Color(0xFF9E9E9E),
                  ),
                  label: const Text(
                    AppStrings.couponMembershipButton,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555555),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F0F0),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class CouponDetailModel {
  const CouponDetailModel({
    this.id = '',
    required this.brand,
    String? name,
    String? title,
    this.category = AppStrings.categoryEtc,
    int? dday,
    int? dDay,
    String? expiry,
    String? expiryDate,
    String? barcodeNumber,
    String? couponNumber,
    this.imagePath,
    this.imageBytes,
    this.memo,
    this.isUsed = false,
    this.avatarText,
    this.status,
    this.couponType,
    this.createdAt,
    this.usedAt,
  })  : name = name ?? title ?? '',
        dday = dday ?? dDay ?? 0,
        expiry = expiry ?? expiryDate ?? '',
        barcodeNumber = barcodeNumber ?? couponNumber ?? '';

  final String id;
  final String brand;
  final String category;
  final String name;
  final int dday;
  final String expiry;
  final String barcodeNumber;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String? memo;
  final bool isUsed;
  final String? avatarText;
  final CouponDetailStatus? status;
  final String? couponType;
  final String? createdAt;
  final String? usedAt;

  DateTime? get expiryDateTime {
    final parts = expiry.split('.');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  bool get isExpired {
    if (status == CouponDetailStatus.expired) {
      return true;
    }
    final date = expiryDateTime;
    if (date == null) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }

  CouponDetailModel copyWith({
    String? id,
    String? brand,
    String? category,
    String? name,
    int? dday,
    String? expiry,
    String? barcodeNumber,
    String? imagePath,
    Uint8List? imageBytes,
    String? memo,
    bool? isUsed,
    String? avatarText,
    CouponDetailStatus? status,
    String? couponType,
    String? createdAt,
    String? usedAt,
  }) {
    return CouponDetailModel(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      category: category ?? this.category,
      dday: dday ?? this.dday,
      expiry: expiry ?? this.expiry,
      barcodeNumber: barcodeNumber ?? this.barcodeNumber,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      memo: memo ?? this.memo,
      isUsed: isUsed ?? this.isUsed,
      avatarText: avatarText ?? this.avatarText,
      status: status ?? this.status,
      couponType: couponType ?? this.couponType,
      createdAt: createdAt ?? this.createdAt,
      usedAt: usedAt ?? this.usedAt,
    );
  }
}

enum CouponDetailStatus {
  available,
  urgent,
  expired,
  redeemed,
}

class _CouponImage extends StatelessWidget {
  const _CouponImage({
    required this.coupon,
    required this.fit,
    this.fallbackWidth,
    this.fallbackHeight,
  });

  final CouponDetailModel coupon;
  final BoxFit fit;
  final double? fallbackWidth;
  final double? fallbackHeight;

  @override
  Widget build(BuildContext context) {
    if (coupon.imageBytes != null) {
      return Image.memory(
        coupon.imageBytes!,
        fit: fit,
      );
    }

    if (coupon.imagePath != null && coupon.imagePath!.isNotEmpty) {
      return Image.file(
        File(coupon.imagePath!),
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: fallbackWidth,
      height: fallbackHeight,
      color: const Color(0xFFF0F0F0),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 48,
        color: Color(0xFFBDBDBD),
      ),
    );
  }
}

class _MembershipListSheet extends StatelessWidget {
  const _MembershipListSheet({
    required this.memberships,
    required this.onClose,
    required this.onMembershipTap,
  });

  final List<_MembershipSheetItem> memberships;
  final VoidCallback onClose;
  final ValueChanged<_MembershipSheetItem> onMembershipTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.60,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                const Text(
                  AppStrings.membershipTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 22,
                    color: Color(0xFF555555),
                  ),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: memberships.isEmpty
                ? const Center(
                    child: EmptyStateMascot(
                      message: AppStrings.membershipEmpty,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: memberships.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 1),
                    itemBuilder: (_, index) {
                      final m = memberships[index];
                      return InkWell(
                        onTap: () => onMembershipTap(m),
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 64,
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                decoration: BoxDecoration(
                                  color: m.barColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: m.iconBgColor,
                                ),
                                child: Icon(
                                  m.icon,
                                  size: 20,
                                  color: m.iconColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  m.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Color(0xFFBDBDBD),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MembershipSheetItem {
  const _MembershipSheetItem({
    required this.name,
    required this.detail,
    required this.barColor,
    required this.iconColor,
    required this.iconBgColor,
    required this.icon,
  });

  final String name;
  final MembershipDetailModel detail;
  final Color barColor;
  final Color iconColor;
  final Color iconBgColor;
  final IconData icon;

  factory _MembershipSheetItem.fromMembership(MembershipDetailModel membership) {
    final brand = membership.brand.toLowerCase();

    if (brand.contains('cj')) {
      return _MembershipSheetItem(
        name: AppStrings.membershipCjOne,
        detail: membership,
        barColor: Color(0xFFE53935),
        iconColor: Color(0xFFE53935),
        iconBgColor: Color(0xFFFFEBEE),
        icon: Icons.star,
      );
    }

    if (brand.contains('스타벅스') || brand.contains('cafe')) {
      return _MembershipSheetItem(
        name: AppStrings.brandStarbucks,
        detail: membership,
        barColor: Color(0xFF1B5E20),
        iconColor: Color(0xFF2E7D32),
        iconBgColor: Color(0xFFE8F5E9),
        icon: Icons.local_cafe_outlined,
      );
    }

    if (brand.contains('해피') || brand.contains('베이커리')) {
      return _MembershipSheetItem(
        name: AppStrings.membershipHappyPoint,
        detail: membership,
        barColor: Color(0xFFE91E8C),
        iconColor: Color(0xFFE91E8C),
        iconBgColor: Color(0xFFFCE4EC),
        icon: Icons.favorite,
      );
    }

    return _MembershipSheetItem(
      name: membership.name,
      detail: membership,
      barColor: const Color(0xFF212121),
      iconColor: const Color(0xFF424242),
      iconBgColor: const Color(0xFFF5F5F5),
      icon: Icons.business,
    );
  }
}
