import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether this device has already seen the intro slides, so
/// returning visitors go from the logo straight into sign-in.
abstract final class LaunchPreferences {
  static const _onboardingSeenKey = 'onboarding_seen_v1';

  static Future<bool> onboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingSeenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingSeenKey, true);
    } catch (_) {
      // Showing the intro again is harmless.
    }
  }

  static const _locationExplainedKey = 'location_explained_v1';

  /// Whether the tourist map has already explained why it wants location.
  static Future<bool> locationExplained() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_locationExplainedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markLocationExplained() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationExplainedKey, true);
    } catch (_) {
      // Explaining again is harmless.
    }
  }
}
