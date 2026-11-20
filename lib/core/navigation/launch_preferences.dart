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
}
