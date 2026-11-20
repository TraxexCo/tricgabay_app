import 'dart:convert';
import 'message_resolver.g.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_en.dart';
import '../../l10n/app_localizations_fil.dart';
export 'message_codes.g.dart';
export '../constants/app_brand.dart';

AppLocalizations get currentAppL10n =>
    {'fil', 'tl'}.contains(
      (Intl.defaultLocale ?? PlatformDispatcher.instance.locale.languageCode)
          .split('_')
          .first,
    )
    ? AppLocalizationsFil()
    : AppLocalizationsEn();

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      currentAppL10n;
  String message(String code) => resolveMessage(l10n, code);
  String? optionalMessage(String? code) => code == null ? null : message(code);
}

String? Function(String?)? localizeValidator(
  BuildContext context,
  String? Function(String?)? validator,
) => validator == null
    ? null
    : (value) => context.optionalMessage(validator(value));
String currentMessage(String code) => resolveMessage(currentAppL10n, code);
String resolveMessage(AppLocalizations l, String code) {
  if (!code.startsWith('@l10n/')) return code;
  try {
    final separator = code.indexOf('|');
    final key = separator < 0
        ? code.substring(6)
        : code.substring(6, separator);
    final args = separator < 0
        ? <dynamic>[]
        : jsonDecode(code.substring(separator + 1)) as List<dynamic>;
    return resolveTypedMessage(l, key, args);
  } on FormatException {
    return l.updateRequired;
  } on TypeError {
    return l.updateRequired;
  } on RangeError {
    return l.updateRequired;
  }
}
