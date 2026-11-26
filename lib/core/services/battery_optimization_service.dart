import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BatteryStatus { unrestricted, restricted, unknown }

/// Reads whether Android's battery optimization limits this app, and opens the
/// system screen where the driver can lift it. The app does not request any
/// extra permission for this: it only opens the settings list.
class BatteryOptimizationService {
  BatteryOptimizationService._();

  static const _promptedKey = 'battery_prompt_shown_v1';
  static MethodChannel channel = const MethodChannel(
    'com.tricgabay.app/battery',
  );
  static Future<SharedPreferences> Function() preferences =
      SharedPreferences.getInstance;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<BatteryStatus> status() async {
    if (!_supported) return BatteryStatus.unknown;
    try {
      final ignoring = await channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      if (ignoring == null) return BatteryStatus.unknown;
      return ignoring ? BatteryStatus.unrestricted : BatteryStatus.restricted;
    } on PlatformException {
      return BatteryStatus.unknown;
    } on MissingPluginException {
      return BatteryStatus.unknown;
    }
  }

  static Future<bool> openSettings() async {
    if (!_supported) return false;
    try {
      return await channel.invokeMethod<bool>('openBatterySettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// True once, for a driver whose app is still restricted.
  static Future<bool> shouldPrompt() async {
    final prefs = await preferences();
    if (prefs.getBool(_promptedKey) ?? false) return false;
    return await status() == BatteryStatus.restricted;
  }

  static Future<void> markPrompted() async {
    final prefs = await preferences();
    await prefs.setBool(_promptedKey, true);
  }
}
