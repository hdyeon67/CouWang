import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../resources/app_strings.dart';

class AppPermissionService {
  const AppPermissionService._();

  static Future<bool> isNotificationPermissionGranted() async {
    if (kIsWeb) {
      return true;
    }

    return _isGranted(await Permission.notification.status);
  }

  static Future<void> requestStartupPermissions(BuildContext context) async {
    if (kIsWeb || !context.mounted) {
      return;
    }

    await ensureNotificationPermission(context);
    if (!context.mounted) {
      return;
    }
    await ensurePhotoPermission(context);
  }

  static Future<bool> ensureNotificationPermission(BuildContext context) async {
    if (kIsWeb) {
      return true;
    }

    final currentStatus = await Permission.notification.status;
    if (_isGranted(currentStatus)) {
      return true;
    }
    if (!context.mounted) {
      return false;
    }

    final shouldRequest = await _showPermissionRequestDialog(
      context: context,
      title: AppStrings.notificationPermissionTitle,
      description: AppStrings.notificationPermissionDescription,
    );

    if (!shouldRequest || !context.mounted) {
      return false;
    }

    final requestedStatus = await Permission.notification.request();
    if (_isGranted(requestedStatus)) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    await _showOpenSettingsDialog(
      context: context,
      title: AppStrings.notificationPermissionTitle,
      description: AppStrings.notificationPermissionDenied,
    );
    return false;
  }

  static Future<bool> ensurePhotoPermission(BuildContext context) async {
    if (kIsWeb) {
      return true;
    }

    final currentStatus = await _currentPhotoPermissionStatus();
    if (_isGranted(currentStatus)) {
      return true;
    }
    if (!context.mounted) {
      return false;
    }

    final shouldRequest = await _showPermissionRequestDialog(
      context: context,
      title: AppStrings.photoPermissionTitle,
      description: AppStrings.photoPermissionDescription,
    );

    if (!shouldRequest || !context.mounted) {
      return false;
    }

    final requestedStatus = await _requestPhotoPermission();
    if (_isGranted(requestedStatus)) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    await _showOpenSettingsDialog(
      context: context,
      title: AppStrings.photoPermissionTitle,
      description: AppStrings.photoPermissionDenied,
    );
    return false;
  }

  static Future<PermissionStatus> _currentPhotoPermissionStatus() async {
    final photoStatus = await Permission.photos.status;
    if (_isGranted(photoStatus)) {
      return photoStatus;
    }

    final storageStatus = await Permission.storage.status;
    return _isGranted(storageStatus) ? storageStatus : photoStatus;
  }

  static Future<PermissionStatus> _requestPhotoPermission() async {
    final photoStatus = await Permission.photos.request();
    if (_isGranted(photoStatus)) {
      return photoStatus;
    }

    final storageStatus = await Permission.storage.request();
    return _isGranted(storageStatus) ? storageStatus : photoStatus;
  }

  static bool _isGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  static Future<bool> _showPermissionRequestDialog({
    required BuildContext context,
    required String title,
    required String description,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                AppStrings.permissionLater,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                AppStrings.permissionAllow,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64CAFA),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  static Future<void> _showOpenSettingsDialog({
    required BuildContext context,
    required String title,
    required String description,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                AppStrings.permissionLater,
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
                await openAppSettings();
              },
              child: const Text(
                AppStrings.permissionOpenSettings,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64CAFA),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
