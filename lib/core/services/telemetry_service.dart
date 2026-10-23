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
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: FirebaseConfig.options);
      }
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        !kDebugMode,
      );
      final previousFlutterHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        previousFlutterHandler?.call(details);
        if (!kDebugMode) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
      };
      final previousPlatformHandler = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (error, stack) {
        if (!kDebugMode) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
        return previousPlatformHandler?.call(error, stack) ?? true;
      };
      _ready = true;
    } catch (error) {
      debugPrint('Operational telemetry is unavailable: $error');
    }
  }

  static Future<T> trace<T>(
    String safeName,
    Future<T> Function() action,
  ) async {
    final normalized = safeName.replaceAll(RegExp('[^a-zA-Z0-9_]'), '_');
    final trace = _ready
        ? FirebasePerformance.instance.newTrace(normalized)
        : null;
    await trace?.start();
    try {
      return await action();
    } catch (error, stack) {
      if (_ready && !kDebugMode) {
        await FirebaseCrashlytics.instance.recordError(error, stack);
      }
      rethrow;
    } finally {
      await trace?.stop();
    }
  }

  static Future<void> recordNonFatal(Object error, StackTrace stack) async {
    if (_ready && !kDebugMode) {
      await FirebaseCrashlytics.instance.recordError(error, stack);
    }
  }
}
