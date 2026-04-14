import 'dart:io';
import 'dart:typed_data';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/resources/app_strings.dart';
import '../../../../core/widgets/empty_state_mascot.dart';
import '../../../../repositories/coupon_repository.dart';
import '../../../../repositories/membership_repository.dart';
import '../../../coupons/presentation/screens/coupon_detail_screen.dart';
import 'membership_create_screen.dart';

class MembershipDetailScreen extends StatefulWidget {
  const MembershipDetailScreen({
    super.key,
    this.membership = const MembershipDetailModel(
      name: AppStrings.membershipSkt,
      brand: AppStrings.membershipTelecom,
      cardNumber: '7742990122284',
      imagePath: null,
    ),
  });

  final MembershipDetailModel membership;

  @override
  State<MembershipDetailScreen> createState() => _MembershipDetailScreenState();
}

class _MembershipDetailScreenState extends State<MembershipDetailScreen> {
  final GlobalKey _menuButtonKey = GlobalKey();
  MembershipDetailModel get _membership =>
      MembershipRepository.findById(widget.membership.id) ?? widget.membership;

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
        builder: (_) => MembershipCreateScreen(membership: _membership),
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
            AppStrings.membershipDeleteTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: const Text(
            AppStrings.membershipDeleteDescription,
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
                await MembershipRepository.delete(_membership.id);
                if (!mounted) {
                  return;
                }
                Navigator.pop(context);
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: const Text(AppStrings.membershipDeleteDone),
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

  void _showImageFullScreen() {
    _showFullscreenOverlay(
      child: InteractiveViewer(
        panEnabled: true,
        minScale: 0.8,
        maxScale: 4.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _MembershipImage(
            membership: _membership,
            fit: BoxFit.contain,
            fallbackWidth: 300,
            fallbackHeight: 180,
          ),
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
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
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
                barcode: Barcode.code128(),
                data: _membership.cardNumber,
                width: 280,
                height: 120,
                drawText: false,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatCardNumber(_membership.cardNumber),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.0,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCouponListBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return _CouponListSheet(
          coupons: CouponRepository.getAll()
              .map(
                (coupon) => _SampleCoupon(
                  detail: coupon,
                  name: coupon.name,
                  expiry: coupon.expiry,
                  dday: coupon.dday,
                  imagePath: coupon.imagePath,
                  imageBytes: coupon.imageBytes,
                ),
              )
              .toList(),
          onClose: () => Navigator.pop(ctx),
          onCouponTap: (coupon) {
            Navigator.pop(ctx);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CouponDetailScreen(coupon: coupon.detail),
              ),
            );
          },
        );
      },
    );
  }

  String _formatCardNumber(String raw) {
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

  @override
  Widget build(BuildContext context) {
    final membership = _membership;

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
                      onPressed: () => Navigator.pop(context),
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
                  const Spacer(),
                  IconButton(
                    key: _menuButtonKey,
                    onPressed: _showContextMenu,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 40, height: 40),
                    icon: const Icon(
                      Icons.more_vert,
                      size: 24,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                membership.brand,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                membership.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showImageFullScreen,
                child: Container(
                  width: double.infinity,
                  height: 200,
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
                    child: _MembershipImage(
                      membership: membership,
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
                          BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: membership.cardNumber,
                            width: double.infinity,
                            height: 80,
                            drawText: false,
                            color: const Color(0xFF1A1A1A),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatCardNumber(membership.cardNumber),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.0,
                              color: Color(0xFF1A1A1A),
                            ),
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
                child: OutlinedButton.icon(
                  onPressed: _showCouponListBottomSheet,
                  icon: const Icon(
                    Icons.confirmation_number_outlined,
                    size: 20,
                    color: Color(0xFF9E9E9E),
                  ),
                  label: const Text(
                    AppStrings.membershipCouponList,
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

class MembershipDetailModel {
  const MembershipDetailModel({
    this.id = '',
    required this.name,
    required this.brand,
    required this.cardNumber,
    this.memo,
    this.imagePath,
    this.imageBytes,
    this.createdAt,
  });

  final String id;
  final String name;
  final String brand;
  final String cardNumber;
  final String? memo;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String? createdAt;

  MembershipDetailModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? cardNumber,
    String? memo,
    String? imagePath,
    Uint8List? imageBytes,
    String? createdAt,
  }) {
    return MembershipDetailModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      cardNumber: cardNumber ?? this.cardNumber,
      memo: memo ?? this.memo,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class _MembershipImage extends StatelessWidget {
  const _MembershipImage({
    required this.membership,
    required this.fit,
    this.fallbackWidth,
    this.fallbackHeight,
  });

  final MembershipDetailModel membership;
  final BoxFit fit;
  final double? fallbackWidth;
  final double? fallbackHeight;

  @override
  Widget build(BuildContext context) {
    if (membership.imageBytes != null) {
      return Image.memory(
        membership.imageBytes!,
        fit: fit,
      );
    }

    if (membership.imagePath != null && membership.imagePath!.isNotEmpty) {
      return Image.file(
        File(membership.imagePath!),
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
      color: const Color(0xFF3D2FEE),
      alignment: Alignment.center,
      child: Text(
        membership.name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CouponListSheet extends StatelessWidget {
  const _CouponListSheet({
    required this.coupons,
    required this.onClose,
    required this.onCouponTap,
  });

  final List<_SampleCoupon> coupons;
  final VoidCallback onClose;
  final ValueChanged<_SampleCoupon> onCouponTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
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
                  AppStrings.membershipMyCoupons,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close,
                    size: 22,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: coupons.isEmpty
                ? const Center(
                    child: EmptyStateMascot(
                      message: AppStrings.homeNoCoupons,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: coupons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final coupon = coupons[index];
                      return InkWell(
                        onTap: () => onCouponTap(coupon),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0xFFE0E0E0),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: coupon.imageBytes != null
                                      ? Image.memory(
                                          coupon.imageBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : (coupon.imagePath != null &&
                                              coupon.imagePath!.isNotEmpty)
                                          ? Image.file(
                                              File(coupon.imagePath!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.confirmation_number_outlined,
                                                size: 24,
                                                color: Color(0xFFBDBDBD),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.confirmation_number_outlined,
                                              size: 24,
                                              color: Color(0xFFBDBDBD),
                                            ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      coupon.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '유효기간: ${coupon.expiry}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _DdayBadge(dday: coupon.dday),
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

class _DdayBadge extends StatelessWidget {
  const _DdayBadge({required this.dday});

  final int dday;

  @override
  Widget build(BuildContext context) {
    late final Color bgColor;
    late final Color textColor;
    BoxBorder? border;
    final label = dday == 0 ? 'D-DAY' : 'D-$dday';

    if (dday == 0) {
      bgColor = const Color(0xFF64CAFA);
      textColor = Colors.white;
    } else if (dday <= 9) {
      bgColor = Colors.white;
      textColor = const Color(0xFF64CAFA);
      border = Border.all(color: const Color(0xFF64CAFA), width: 1.5);
    } else {
      bgColor = Colors.white;
      textColor = const Color(0xFFBDBDBD);
      border = Border.all(color: const Color(0xFFBDBDBD), width: 1.2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _SampleCoupon {
  const _SampleCoupon({
    required this.detail,
    required this.name,
    required this.expiry,
    required this.dday,
    this.imagePath,
    this.imageBytes,
  });

  final CouponDetailModel detail;
  final String name;
  final String expiry;
  final int dday;
  final String? imagePath;
  final Uint8List? imageBytes;
}
