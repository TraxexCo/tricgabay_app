import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_config.dart';

/// Privacy-conscious operational telemetry for supported mobile builds.
/// Never attach names, email addresses, phone numbers, coordinates, payment
/// data, pickup codes, or free-form user text to reports.
class TelemetryService {
  TelemetryService._();

  static bool _ready = false;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> initialize() async {
    if (_ready || !_supported || !FirebaseConfig.isConfigured) return;
    final prefs = await SharedPreferences.getInstance();
    final consent = prefs.getBool('telemetry_consent_v1') ?? false;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: FirebaseConfig.options);
      }
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        consent && !kDebugMode,
      );
      // Keep automatic URL/network traces disabled: route paths may contain coordinates.
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(false);
      final previousFlutterHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        previousFlutterHandler?.call(details);
        if (!kDebugMode) {
          FirebaseCrashlytics.instance.recordError(
            StateError(
              MessageCode.flutterFailureValue(
                (details.exception.runtimeType).toString(),
              ),
            ),
            details.stack,
            fatal: false,
          );
        }
      };
      final previousPlatformHandler = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (error, stack) {
        if (!kDebugMode) {
          FirebaseCrashlytics.instance.recordError(
            StateError(
              MessageCode.platformFailureValue((error.runtimeType).toString()),
            ),
            stack,
            fatal: false,
          );
        }
        return previousPlatformHandler?.call(error, stack) ?? true;
      };
      _ready = true;
    } catch (error) {
      debugPrint('Operational telemetry is unavailable.');
    }
  }

  static Future<void> setConsent(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('telemetry_consent_v1', enabled);
    try {
      if (_supported && Firebase.apps.isNotEmpty) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          enabled && !kDebugMode,
        );
        // Keep automatic URL/network traces disabled: route paths may contain coordinates.
        await FirebasePerformance.instance.setPerformanceCollectionEnabled(
          false,
        );
      }
    } catch (_) {
      /* Optional diagnostics must not block registration. */
    }
  }

  static Future<void> recordNonFatal(Object error, StackTrace stack) async {
    if (!_ready || kDebugMode) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        StateError(
          MessageCode.operationFailureValue((error.runtimeType).toString()),
        ),
        stack,
        fatal: false,
      );
    } catch (_) {
      /* Reporting failures must not create unhandled errors. */
    }
  }
}
