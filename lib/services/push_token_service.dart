import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registers this device for FCM push and keeps its token fresh in
/// `user_push_tokens`. Mobile-only — FCM has no Windows support; the desktop
/// build keeps the realtime + local_notifier toast path instead.
///
/// Sending is fully server-side and already live: `send_quotation_to_warehouse`
/// inserts a `notifications` row per active warehouse manager, and the
/// `relay_push_on_notification` DB webhook forwards it to FCM with Android
/// channel id `warehouse_transfer`. This service's job is only to (a) make
/// that channel exist BEFORE the first push arrives — Android 8+ silently
/// drops notifications addressed to unknown channels — and (b) register the
/// device token so relay-push can find this phone.
class PushTokenService {
  PushTokenService._();
  static final instance = PushTokenService._();

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool _registered = false;

  /// Idempotent — safe to call on every auth-state build.
  Future<void> register() async {
    if (!isSupported || _registered) return;
    _registered = true;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      if (Platform.isAndroid) {
        const channels = [
          AndroidNotificationChannel(
            'warehouse_transfer',
            'Transfer Requests',
            description:
                'New quotations sent to the warehouse for stock checking',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
          AndroidNotificationChannel(
            'warehouse_transfer_urgent',
            'Urgent Transfer Requests',
            description:
                'Urgent quotations that must be prepared immediately',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
        ];
        final android = FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        for (final channel in channels) {
          await android?.createNotificationChannel(channel);
        }
      }

      final token = await messaging.getToken();
      await _upsert(token);
      messaging.onTokenRefresh.listen(_upsert);
    } catch (e) {
      debugPrint('[Push] registration failed: $e');
      _registered = false; // allow a retry on next auth build
    }
  }

  Future<void> _upsert(String? token) async {
    if (token == null || token.isEmpty) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client.from('user_push_tokens').upsert({
        'user_id': uid,
        'fcm_token': token,
        'device_platform': Platform.isAndroid ? 'android' : 'ios',
        'is_active': true,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,fcm_token');
    } catch (e) {
      debugPrint('[Push] token upsert failed: $e');
    }
  }
}
