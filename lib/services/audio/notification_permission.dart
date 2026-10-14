import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

import '../../data/local_store.dart';

/// Android 13+ needs the POST_NOTIFICATIONS runtime permission for the playback
/// notification (and therefore the lock-screen controls on many devices).
/// Asked once, right after the first time the user starts playback, never at launch.
class NotificationPermission {
  static Future<void> ensureRequested(LocalStore store) async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.notification.status;
      if (status.isGranted || status.isPermanentlyDenied) return;
      if (store.notificationPermissionAsked) return;
      await store.setNotificationPermissionAsked();
      await Permission.notification.request();
    } catch (_) {
      // Playback must never depend on this.
    }
  }

  static Future<bool> isGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      return await Permission.notification.isGranted;
    } catch (_) {
      return true;
    }
  }
}
