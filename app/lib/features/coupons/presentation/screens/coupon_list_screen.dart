// 홈 대시보드이자 쿠폰 리스트 메인 화면.
//
// 정렬/검색/필터와 함께, 사용자가 포토 피커로 고른 이미지에서 쿠폰을 찾아주는
// "갤러리에서 쿠폰 찾기" 진입점을 함께 제공한다.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/resources/app_strings.dart';
import '../../../../core/widgets/app_tab_scaffold.dart';
import '../../../../core/widgets/empty_state_mascot.dart';
import '../../../../repositories/coupon_repository.dart';
import '../../../../services/gallery_scan_service.dart';
import '../../../notifications/presentation/screens/notification_list_screen.dart';
import '../../../../services/notification_service.dart';
import '../../../../utils/scanned_image_store.dart';
import 'coupon_create_screen.dart';
import 'coupon_detail_screen.dart';

// HomeCouponSortType 상태 값을 정의하는 enum.
enum HomeCouponSortType { expiry, name }

// HomeCouponFilterType 상태 값을 정의하는 enum.
enum HomeCouponFilterType { available, used, expired }

// 쿠폰 홈 화면을 그리는 StatefulWidget이다.
//
// 검색어, 정렬, 필터, 갤러리 감지 팝업처럼 화면 안에서 변하는 값이 많아서
// 이 화면은 StatefulWidget으로 관리한다.
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    super.key,
    this.onCouponClick,
    this.onFabClick,
  });

  final ValueChanged<String>? onCouponClick;
  final VoidCallback? onFabClick;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

// 홈 화면의 검색/필터 상태와 사용자 선택형 갤러리 감지 흐름을 관리한다.
class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  static const double _horizontalPadding = 20;
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  int _bubbleMessageIndex = 0;
  bool _isScanningGallery = false;
  bool _isShowingDetectedDialog = false;
  List<DetectedCouponImage> _pendingImages = <DetectedCouponImage>[];

  String _searchQuery = '';
  HomeCouponSortType _sortType = HomeCouponSortType.expiry;
  HomeCouponFilterType _filterType = HomeCouponFilterType.available;

  @override
  // initState에서는 listener 등록과 앱 진입 직후 필요한 비동기 후처리를 연결한다.
  //
  // 검색 입력값 감시, 알림 재예약처럼 build에 두면 안 되는 1회성 작업을 분리한다.
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().rescheduleAllCouponNotifications();
    });
  }

  @override
  // 사용이 끝난 리소스를 정리한다.
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // "갤러리에서 쿠폰 찾기" 흐름. 포토 피커로 고른 이미지만 분석한다.
  //
  // 포토 피커는 사진 접근 권한(READ_MEDIA_IMAGES)이 필요 없어서 정책 위반 없이
  // 동작한다. 사용자가 고른 이미지에서 쿠폰 후보를 찾아 순차 팝업으로 보여준다.
  Future<void> _pickAndScanGallery() async {
    if (_isScanningGallery || _isShowingDetectedDialog) {
      return;
    }

    final picked = await _imagePicker.pickMultiImage(imageQuality: 90);
    if (picked.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _isScanningGallery = true;
    });
    try {
      final files = picked.map((image) => File(image.path)).toList();
      final detected = await GalleryScanService().analyzePickedImages(files);
      if (!mounted) {
        return;
      }

      if (detected.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('쿠폰으로 보이는 이미지를 찾지 못했어요.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        return;
      }

      setState(() {
        _pendingImages = detected;
      });
      _showNextDetectedPopup();
    } finally {
      if (mounted) {
        setState(() {
          _isScanningGallery = false;
        });
      }
    }
  }

  // 다이얼로그, 시트, 상세 화면 등 표시 흐름을 담당한다.
  void _showNextDetectedPopup() {
    // 감지 결과는 한 장씩 순차 처리해야 사용자가 저장/거절 여부를 명확히 선택할 수 있다.
    if (_pendingImages.isEmpty || !mounted || _isShowingDetectedDialog) {
      return;
    }
    if ((ModalRoute.of(context)?.isCurrent ?? true) == false) {
      return;
    }

    final current = _pendingImages.first;
    final remaining = _pendingImages.length - 1;
    _isShowingDetectedDialog = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _CouponDetectedDialog(
          detectedImage: current,
          remainingCount: remaining,
          onSave: () {
            Navigator.pop(ctx);
            setState(() {
              _pendingImages.removeAt(0);
            });
            _isShowingDetectedDialog = false;
            Navigator.of(context)
                .push<CouponDetailModel>(
                  MaterialPageRoute(
                    builder: (_) => CouponCreateScreen(
                      preloadedImage: current.file,
                    ),
                  ),
                )
                .then((savedCoupon) async {
                  if (savedCoupon != null) {
                    await ScannedImageStore.addRegisteredHash(
                      current.imageHash,
                    );
                    if (mounted) {
                      setState(() {});
                    }
                  }
                  _showNextDetectedPopup();
                });
          },
          onReject: () async {
            Navigator.pop(ctx);
            await ScannedImageStore.addRejectedHash(current.imageHash);
            if (!mounted) {
              _isShowingDetectedDialog = false;
              return;
            }
            setState(() {
              _pendingImages.removeAt(0);
            });
            _isShowingDetectedDialog = false;
            _showNextDetectedPopup();
          },
        );
      },
    ).then((_) {
      _isShowingDetectedDialog = false;
    });
  }

  List<HomeCouponItem> get _filteredCouponList {
    final query = _searchQuery.trim().toLowerCase();

    final items = _couponList.where((coupon) {
      final matchesFilter = coupon.filterType == _filterType;
      final matchesSearch =
          query.isEmpty ||
          coupon.title.toLowerCase().contains(query) ||
          coupon.brand.toLowerCase().contains(query) ||
          coupon.detail.category.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();

    switch (_sortType) {
      case HomeCouponSortType.expiry:
        items.sort((a, b) => a.dDay.compareTo(b.dDay));
        break;
      case HomeCouponSortType.name:
        items.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return items;
  }

  String get _monthlySavingText {
    final messages = [
      '${_couponList.where((coupon) => coupon.filterType == HomeCouponFilterType.available).length}장의 쿠폰이 아직 기다리고 있다 멍!',
      AppStrings.homeBubbleReminder,
      AppStrings.homeBubbleCheer,
    ];
    return messages[_bubbleMessageIndex % messages.length];
  }

  List<HomeCouponItem> get _couponList {
    return CouponRepository.getAll().map((coupon) {
      return HomeCouponItem(
        id: coupon.id,
        brand: coupon.brand,
        title: coupon.name,
        expiryDate: coupon.expiry,
        dDay: coupon.dday,
        imagePath: coupon.imagePath ?? '',
        imageBytes: coupon.imageBytes,
        filterType: _resolveFilterType(coupon),
        detail: coupon,
      );
    }).toList();
  }

  HomeCouponFilterType _resolveFilterType(CouponDetailModel coupon) {
    if (coupon.isUsed || coupon.status == CouponDetailStatus.redeemed) {
      return HomeCouponFilterType.used;
    }
    if (coupon.isExpired || coupon.status == CouponDetailStatus.expired) {
      return HomeCouponFilterType.expired;
    }
    return HomeCouponFilterType.available;
  }

  // 쿠폰 카드 탭 시 상세 화면으로 이동하고, 복귀 후 목록을 다시 그린다.
  //
  // Navigator.push(...).then(...) 패턴을 써서 상세 화면에서 수정/삭제가 발생해도
  // 홈 목록이 최신 상태를 반영하도록 했다.
  void _handleCouponClick(HomeCouponItem coupon) {
    FocusScope.of(context).unfocus();
    if (widget.onCouponClick != null) {
      widget.onCouponClick!(coupon.id);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CouponDetailScreen(coupon: coupon.detail),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // FAB 탭 시 등록 화면으로 이동하고, 저장 후 돌아오면 목록을 새로 그린다.
  void _handleFabClick() {
    FocusScope.of(context).unfocus();
    if (widget.onFabClick != null) {
      widget.onFabClick!.call();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CouponCreateScreen(),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  // build는 현재 검색/필터 상태를 기반으로 홈 화면 UI를 조합한다.
  //
  // 화면 상태가 바뀌면 setState를 통해 build가 다시 호출되고, 그 결과 필터링된
  // 쿠폰 목록과 배지/버블 메시지가 함께 갱신된다.
  Widget build(BuildContext context) {
    return AppTabScaffold(
      currentTab: BottomTabItem.home,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingAddButton(onPressed: _handleFabClick),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              _horizontalPadding,
              8,
              _horizontalPadding,
              210,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TopMascotHeader(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _bubbleMessageIndex++;
                    });
                  },
                  onNotificationClick: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationListScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SavingSpeechBubbleCard(message: _monthlySavingText),
                const SizedBox(height: 16),
                GalleryScanButton(
                  isScanning: _isScanningGallery,
                  onTap: _pickAndScanGallery,
                ),
                const SizedBox(height: 28),
                const Text(
                  AppStrings.homeSectionTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 14),
                FilterAndSortRow(
                  selectedFilter: _filterType,
                  sortType: _sortType,
                  onFilterChanged: (value) {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _filterType = value;
                    });
                  },
                  onSortChanged: (value) {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _sortType = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                CouponSearchField(controller: _searchController),
                const SizedBox(height: 12),
                CouponListSection(
                  coupons: _filteredCouponList,
                  onCouponClick: _handleCouponClick,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// CouponListScreen 화면 역할을 담당하는 클래스.
class CouponListScreen extends StatelessWidget {
  const CouponListScreen({super.key});

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    return const HomeDashboardScreen();
  }
}

// GalleryScanButton 관련 역할을 담당하는 클래스.
//
// 포토 피커를 열어 사용자가 고른 이미지에서 쿠폰을 찾는 진입점 버튼이다.
class GalleryScanButton extends StatelessWidget {
  const GalleryScanButton({
    super.key,
    required this.isScanning,
    required this.onTap,
  });

  final bool isScanning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD0ECFF), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isScanning ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (isScanning)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xFF64CAFA),
                  ),
                )
              else
                const Icon(
                  Icons.photo_library_outlined,
                  size: 22,
                  color: Color(0xFF64CAFA),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isScanning ? '쿠폰 이미지를 분석하고 있어요...' : '갤러리에서 쿠폰 찾기',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (!isScanning)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Color(0xFF9E9E9E),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// CouponDetectedDialog 관련 역할을 담당하는 클래스.
class _CouponDetectedDialog extends StatelessWidget {
  const _CouponDetectedDialog({
    required this.detectedImage,
    required this.remainingCount,
    required this.onSave,
    required this.onReject,
  });

  final DetectedCouponImage detectedImage;
  final int remainingCount;
  final VoidCallback onSave;
  final VoidCallback onReject;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                detectedImage.file,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Image.asset('assets/icon/4.png', width: 36, height: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '쿠폰 이미지를 발견했어요!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (remainingCount > 0)
                        Text(
                          '외 $remainingCount개가 더 있어요',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64CAFA),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '아니요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64CAFA),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '저장할게요',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// HomeCouponItem 관련 역할을 담당하는 클래스.
class HomeCouponItem {
  const HomeCouponItem({
    required this.id,
    required this.brand,
    required this.title,
    required this.expiryDate,
    required this.dDay,
    required this.imagePath,
    this.imageBytes,
    required this.filterType,
    required this.detail,
  });

  final String id;
  final String brand;
  final String title;
  final String expiryDate;
  final int dDay;
  final String imagePath;
  final Uint8List? imageBytes;
  final HomeCouponFilterType filterType;
  final CouponDetailModel detail;
}

// TopMascotHeader 관련 역할을 담당하는 클래스.
class TopMascotHeader extends StatelessWidget {
  const TopMascotHeader({
    super.key,
    required this.onTap,
    required this.onNotificationClick,
  });

  final VoidCallback onTap;
  final VoidCallback onNotificationClick;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icon/2-1.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onNotificationClick,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          icon: const Icon(
            Icons.notifications_outlined,
            size: 26,
            color: Color(0xFF222222),
          ),
        ),
      ],
    );
  }
}

// SavingSpeechBubbleCard 관련 역할을 담당하는 클래스.
class SavingSpeechBubbleCard extends StatelessWidget {
  const SavingSpeechBubbleCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '"$message"',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
          height: 1.5,
        ),
      ),
    );
  }
}

// FilterAndSortRow 관련 역할을 담당하는 클래스.
class FilterAndSortRow extends StatelessWidget {
  const FilterAndSortRow({
    super.key,
    required this.selectedFilter,
    required this.sortType,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final HomeCouponFilterType selectedFilter;
  final HomeCouponSortType sortType;
  final ValueChanged<HomeCouponFilterType> onFilterChanged;
  final ValueChanged<HomeCouponSortType> onSortChanged;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Move the sort button down only when the row is nearly out of room.
        final isCompact = constraints.maxWidth < 330;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 3,
                runSpacing: 8,
                children: [
                  FilterChipButton(
                    label: AppStrings.homeFilterAvailable,
                    isSelected:
                        selectedFilter == HomeCouponFilterType.available,
                    onTap: () =>
                        onFilterChanged(HomeCouponFilterType.available),
                  ),
                  FilterChipButton(
                    label: AppStrings.homeFilterUsed,
                    isSelected: selectedFilter == HomeCouponFilterType.used,
                    onTap: () => onFilterChanged(HomeCouponFilterType.used),
                  ),
                  FilterChipButton(
                    label: AppStrings.homeFilterExpired,
                    isSelected:
                        selectedFilter == HomeCouponFilterType.expired,
                    onTap: () => onFilterChanged(HomeCouponFilterType.expired),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: CouponSortDropdown(
                  currentSortType: sortType,
                  onChanged: onSortChanged,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Wrap(
              spacing: 3,
              children: [
                FilterChipButton(
                  label: AppStrings.homeFilterAvailable,
                  isSelected: selectedFilter == HomeCouponFilterType.available,
                  onTap: () => onFilterChanged(HomeCouponFilterType.available),
                ),
                FilterChipButton(
                  label: AppStrings.homeFilterUsed,
                  isSelected: selectedFilter == HomeCouponFilterType.used,
                  onTap: () => onFilterChanged(HomeCouponFilterType.used),
                ),
                FilterChipButton(
                  label: AppStrings.homeFilterExpired,
                  isSelected: selectedFilter == HomeCouponFilterType.expired,
                  onTap: () => onFilterChanged(HomeCouponFilterType.expired),
                ),
              ],
            ),
            const Spacer(),
            CouponSortDropdown(
              currentSortType: sortType,
              onChanged: onSortChanged,
            ),
          ],
        );
      },
    );
  }
}

// FilterChipButton 관련 역할을 담당하는 클래스.
class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF64CAFA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }
}

// CouponSearchField 관련 역할을 담당하는 클래스.
class CouponSearchField extends StatelessWidget {
  const CouponSearchField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7DEE7), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        // Keep the editable area slightly inset so it does not overlap the rounded border.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.5),
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: controller,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1A1A),
              ),
              decoration: const InputDecoration(
                hintText: AppStrings.homeSearchHint,
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFBDBDBD),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.search,
                    color: Color(0xFF9E9E9E),
                    size: 22,
                  ),
                ),
                suffixIconConstraints: BoxConstraints(
                  minWidth: 44,
                  minHeight: 38,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// CouponSortDropdown 관련 역할을 담당하는 클래스.
class CouponSortDropdown extends StatelessWidget {
  const CouponSortDropdown({
    super.key,
    required this.currentSortType,
    required this.onChanged,
  });

  final HomeCouponSortType currentSortType;
  final ValueChanged<HomeCouponSortType> onChanged;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged(
          currentSortType == HomeCouponSortType.expiry
              ? HomeCouponSortType.name
              : HomeCouponSortType.expiry,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentSortType == HomeCouponSortType.expiry
                  ? AppStrings.homeSortExpiry
                  : AppStrings.homeSortName,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.swap_horiz_rounded,
              size: 16,
              color: Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }
}

// CouponListSection 관련 역할을 담당하는 클래스.
class CouponListSection extends StatelessWidget {
  const CouponListSection({
    super.key,
    required this.coupons,
    required this.onCouponClick,
  });

  final List<HomeCouponItem> coupons;
  final ValueChanged<HomeCouponItem> onCouponClick;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: EmptyStateMascot(
            message: AppStrings.homeNoCoupons,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: coupons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        return CouponCard(
          coupon: coupon,
          isHighlighted: index == 0 && coupon.dDay == 0,
          onTap: () => onCouponClick(coupon),
        );
      },
    );
  }
}

// CouponCard 관련 역할을 담당하는 클래스.
class CouponCard extends StatelessWidget {
  const CouponCard({
    super.key,
    required this.coupon,
    required this.isHighlighted,
    required this.onTap,
  });

  final HomeCouponItem coupon;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    final borderSide = isHighlighted
        ? const BorderSide(color: Color(0xFF64CAFA), width: 1.8)
        : const BorderSide(color: Color(0xFFD7DEE7), width: 1);

    final cardRadius = BorderRadius.circular(18);

    return Container(
      decoration: BoxDecoration(
        borderRadius: cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CouponThumbnail(
                  imagePath: coupon.imagePath,
                  imageBytes: coupon.imageBytes,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${AppStrings.homeCouponExpiryPrefix}${coupon.expiryDate}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DdayBadge(coupon: coupon.detail),
                    if (coupon.dDay == 0) ...[
                      const SizedBox(height: 4),
                      const Text(
                        AppStrings.homeTodayExpires,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64CAFA),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// CouponThumbnail 관련 역할을 담당하는 클래스.
class CouponThumbnail extends StatelessWidget {
  const CouponThumbnail({
    super.key,
    required this.imagePath,
    this.imageBytes,
  });

  final String imagePath;
  final Uint8List? imageBytes;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null || imagePath.isNotEmpty;

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF0F0F0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: hasImage
            ? (imageBytes != null
                ? Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ))
            : const SizedBox.shrink(),
      ),
    );
  }
}

// DdayBadge 관련 역할을 담당하는 클래스.
class DdayBadge extends StatelessWidget {
  const DdayBadge({
    super.key,
    required this.coupon,
  });

  final CouponDetailModel coupon;

  @override
  // 현재 상태를 기준으로 화면 UI를 구성한다.
  Widget build(BuildContext context) {
    final style = _badgeStyleForCoupon(coupon);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: style.textColor,
        ),
      ),
    );
  }

  _BadgeStyle _badgeStyleForCoupon(CouponDetailModel coupon) {
    if (coupon.isUsed || coupon.status == CouponDetailStatus.redeemed) {
      return _BadgeStyle(
        label: AppStrings.couponUsed,
        backgroundColor: const Color(0xFF8E9AAF),
        textColor: Colors.white,
      );
    }
    if (coupon.isExpired || coupon.status == CouponDetailStatus.expired) {
      return _BadgeStyle(
        label: AppStrings.couponExpired,
        backgroundColor: const Color(0xFFE58C73),
        textColor: Colors.white,
      );
    }

    final value = coupon.dday;
    return _BadgeStyle(
      label: value == 0 ? 'D-DAY' : 'D-$value',
      backgroundColor: _getDdayBadgeColor(value),
      textColor: Colors.white,
    );
  }

  Color _getDdayBadgeColor(int dday) {
    if (dday <= 1) return const Color(0xFF55C8FF);
    if (dday <= 3) return const Color(0xFF7DD4FF);
    if (dday <= 7) return const Color(0xFFA3E0FF);
    if (dday <= 15) return const Color(0xFFC2EAFF);
    return const Color(0xFFDDF3FF);
  }
}

// BadgeStyle 관련 역할을 담당하는 클래스.
class _BadgeStyle {
  const _BadgeStyle({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
}
