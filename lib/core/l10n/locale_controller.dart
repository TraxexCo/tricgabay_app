import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { device, english, filipino }

class LocaleController with WidgetsBindingObserver {
  static const preferenceKey = 'app_language_override_v2';
  static const legacyPreferenceKey = 'tric_gabay_language_v1';
  static final revision = ValueNotifier<int>(0);
  static AppLanguage selection = AppLanguage.device;
  static Locale deviceLocale = PlatformDispatcher.instance.locale;
  static SharedPreferences? _preferences;
  static final _observer = LocaleController();
  static bool _observing = false;
  static Locale resolve(
    Locale device, {
    AppLanguage choice = AppLanguage.device,
  }) => switch (choice) {
    AppLanguage.english => const Locale('en'),
    AppLanguage.filipino => const Locale('fil'),
    AppLanguage.device => Locale(
      {'fil', 'tl'}.contains(device.languageCode) ? 'fil' : 'en',
    ),
  };
  static Locale get effectiveLocale => resolve(deviceLocale, choice: selection);
  static Locale? get overrideLocale =>
      selection == AppLanguage.device ? null : effectiveLocale;
  static Future<void> initialize(
    SharedPreferences preferences, {
    Locale? device,
  }) async {
    _preferences = preferences;
    deviceLocale = device ?? PlatformDispatcher.instance.locale;
    final saved = preferences.getString(preferenceKey);
    selection = switch (saved) {
      'en' => AppLanguage.english,
      'fil' => AppLanguage.filipino,
      _ => AppLanguage.device,
    };
    if (saved == null && preferences.containsKey(legacyPreferenceKey)) {
      selection = preferences.getBool(legacyPreferenceKey) == true
          ? AppLanguage.filipino
          : AppLanguage.english;
      await preferences.remove(legacyPreferenceKey);
      await _persist();
    }
    if (!_observing) {
      WidgetsBinding.instance.addObserver(_observer);
      _observing = true;
    }
    revision.value++;
  }

  static Future<void> choose(AppLanguage value) async {
    selection = value;
    revision.value++;
    await _persist();
  }

  static Future<void> _persist() async {
    if (selection == AppLanguage.device) {
      await _preferences?.remove(preferenceKey);
    } else {
      await _preferences?.setString(
        preferenceKey,
        effectiveLocale.languageCode,
      );
    }
  }

  static void updateDevice(Locale locale) {
    deviceLocale = locale;
    if (selection == AppLanguage.device) revision.value++;
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (locales?.isNotEmpty ?? false) updateDevice(locales!.first);
  }

  @visibleForTesting
  static void resetForTesting() {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(_observer);
      _observing = false;
    }
    _preferences = null;
    selection = AppLanguage.device;
  }
}
