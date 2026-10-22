import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/backend_config.dart';
import '../config/firebase_config.dart';
import 'backend_repository.dart';

@pragma('vm:entry-point')
Future<void> tricGabayFirebaseBackgroundHandler(RemoteMessage message) async {
  if (!FirebaseConfig.isConfigured) return;
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: FirebaseConfig.options);
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();
  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;
  static String? _token;
  static void Function(String route)? _routeHandler;
  static bool _coreReady = false;
  static bool _active = false;

  static bool get isConfigured => FirebaseConfig.isConfigured;

  static Future<void> initializeCore() async {
    if (_coreReady || !FirebaseConfig.isConfigured) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: FirebaseConfig.options);
      }
      FirebaseMessaging.onBackgroundMessage(tricGabayFirebaseBackgroundHandler);
      _coreReady = true;
    } catch (error) {
      // Unit/widget tests and unsupported desktop targets have no native
      // Firebase channel. The rest of the app must remain usable there.
      debugPrint('Push notifications are unavailable on this target: $error');
      _coreReady = false;
    }
  }

  static Future<void> activate({
    required void Function(String route) onOpenRoute,
  }) async {
    _routeHandler = onOpenRoute;
    if (_active || !FirebaseConfig.isConfigured) return;
    await initializeCore();
    if (!_coreReady) return;
    try {
      const channel = AndroidNotificationChannel(
        'tric_gabay_updates',
        'Trip updates',
        description: 'Booking, driver, payment, and safety updates',
        importance: Importance.high,
        enableVibration: true,
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) {
          final route = response.payload;
          if (route != null && route.startsWith('/')) onOpenRoute(route);
        },
      );
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification == null) return;
        final route = message.data['route_path']?.toString();
        unawaited(
          _local.show(
            message.messageId.hashCode,
            notification.title ?? 'Tric-Gabay update',
            notification.body ?? 'Open Tric-Gabay to view this update.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'tric_gabay_updates',
                'Trip updates',
                channelDescription:
                    'Booking, driver, payment, and safety updates',
                importance: Importance.high,
                priority: Priority.high,
                visibility: NotificationVisibility.private,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            payload: route,
          ),
        );
      });
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
        message,
      ) {
        final route = message.data['route_path']?.toString();
        if (route != null && route.startsWith('/')) onOpenRoute(route);
      });
      final initial = await _messaging.getInitialMessage();
      final initialRoute = initial?.data['route_path']?.toString();
      if (initialRoute != null && initialRoute.startsWith('/')) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => onOpenRoute(initialRoute),
        );
      }
      _token = await _messaging.getToken();
      if (_token != null) await _register(_token!);
      _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
        _token = token;
        unawaited(_register(token));
      });
      _active = true;
    } catch (error) {
      debugPrint('Push notification activation failed: $error');
      _active = false;
    }
  }

  static Future<void> _register(String token) async {
    if (!BackendConfig.isConfigured ||
        BackendConfig.client.auth.currentUser == null) {
      return;
    }
    final platform = kIsWeb
        ? 'web'
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => 'android',
            TargetPlatform.iOS => 'ios',
            TargetPlatform.macOS => 'macos',
            TargetPlatform.windows => 'windows',
            TargetPlatform.linux => 'linux',
            TargetPlatform.fuchsia => 'other',
          };
    await BackendRepository.registerPushToken(
      token: token,
      platform: platform,
      deviceLabel: '${defaultTargetPlatform.name} app',
    );
  }

  static Future<void> refreshRegistration() async {
    if (!FirebaseConfig.isConfigured) return;
    try {
      if (!_active && _routeHandler != null) {
        await activate(onOpenRoute: _routeHandler!);
        return;
      }
      await initializeCore();
      if (!_coreReady) return;
      _token ??= await _messaging.getToken();
      if (_token != null) await _register(_token!);
    } catch (error) {
      debugPrint('Push token registration failed: $error');
    }
  }

  static Future<void> deactivate() async {
    final token = _token;
    if (token != null && BackendConfig.isConfigured) {
      try {
        await BackendRepository.revokePushToken(token);
      } catch (_) {}
    }
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _openedSubscription = null;
    _active = false;
  }
}
