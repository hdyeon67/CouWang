// 홈 대시보드이자 쿠폰 리스트 메인 화면.
//
// 정렬/검색/필터와 함께, 앱 foreground 진입 시 갤러리 자동 감지 팝업을
// 띄우는 진입점 역할도 겸한다.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// HomeDashboardScreen 화면 역할을 담당하는 클래스.
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

// HomeDashboardScreenState 관련 역할을 담당하는 클래스.
class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with WidgetsBindingObserver {
  static const double _horizontalPadding = 20;
  final TextEditingController _searchController = TextEditingController();
  int _bubbleMessageIndex = 0;
  bool _isScanningGallery = false;
  bool _isShowingDetectedDialog = false;
  List<DetectedCouponImage> _pendingImages = <DetectedCouponImage>[];

  String _searchQuery = '';
  HomeCouponSortType _sortType = HomeCouponSortType.expiry;
  HomeCouponFilterType _filterType = HomeCouponFilterType.available;

  @override
  // 화면 또는 객체가 처음 생성될 때 필요한 초기 설정을 수행한다.
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().rescheduleAllCouponNotifications();
      _runGalleryScan();
    });
  }

  @override
  // 앱 lifecycle 변화에 맞춰 후속 동작을 처리한다.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runGalleryScan();
    }
  }

  @override
  // 사용이 끝난 리소스를 정리한다.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  // 여러 단계를 포함한 주요 실행 흐름을 처리한다.
  Future<void> _runGalleryScan() async {
    // 자동 감지는 사용자가 설정에서 켠 경우에만 실행한다.
    // resumed 직후 중복 호출이 쉬워서 플래그로 재진입을 막는다.
    if (_isScanningGallery || _isShowingDetectedDialog) {
      return;
    }
    if ((ModalRoute.of(context)?.isCurrent ?? true) == false) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final autoScanEnabled =
        prefs.getBool(GalleryScanService.autoScanEnabledKey) ?? false;
    if (!autoScanEnabled) {
      return;
    }

    _isScanningGallery = true;
    try {
      final service = GalleryScanService();
      final detected = await service.scanNewImages();
      if (detected.isEmpty || !mounted) {
        return;
      }

      setState(() {
        _pendingImages = detected;
      });
      _showNextDetectedPopup();
    } finally {
      _isScanningGallery = false;
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

  // 사용자 입력이나 이벤트에 대한 후속 처리를 담당한다.
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

  // 사용자 입력이나 이벤트에 대한 후속 처리를 담당한다.
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
  // 현재 상태를 기준으로 화면 UI를 구성한다.
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
