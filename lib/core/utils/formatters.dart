import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_en.dart';
import '../../l10n/app_localizations_fil.dart';

class AppFormatters {
  AppFormatters._();
  static String resolvedLocale(String? locale) =>
      {
        'fil',
        'tl',
      }.contains((locale ?? Intl.defaultLocale ?? 'en').split('_').first)
      ? 'fil_PH'
      : 'en_PH';
  static AppLocalizations _labels(String? locale) =>
      resolvedLocale(locale).startsWith('fil')
      ? AppLocalizationsFil()
      : AppLocalizationsEn();
  static String currency(num amount, {String? locale}) => NumberFormat.currency(
    locale: resolvedLocale(locale),
    name: 'PHP',
    symbol: '₱',
    decimalDigits: 2,
  ).format(amount);
  static String amount(num amount, {String? locale}) =>
      NumberFormat('#,##0.00', resolvedLocale(locale)).format(amount);

  /// Editable decimal/CSV protocol values must not gain grouping or a symbol.
  static String decimalInput(num amount) =>
      NumberFormat('0.00', 'en_PH').format(amount);
  static String currencyShort(num amount, {String? locale}) =>
      NumberFormat.currency(
        locale: resolvedLocale(locale),
        name: 'PHP',
        symbol: '₱',
        decimalDigits: 0,
      ).format(amount);

  /// Distances: one decimal place, no unit (the message adds "km").
  static String distanceKm(num km, {String? locale}) =>
      NumberFormat('#,##0.0', resolvedLocale(locale)).format(km);
  static String integer(num value, {String? locale}) =>
      NumberFormat('#,##0', resolvedLocale(locale)).format(value);
  static String monthShort(DateTime value, {String? locale}) =>
      DateFormat.MMM(resolvedLocale(locale)).format(value);
  static String weekdayShort(DateTime value, {String? locale}) =>
      DateFormat.E(resolvedLocale(locale)).format(value);
  static String monthDay(DateTime value, {String? locale}) =>
      DateFormat.Md(resolvedLocale(locale)).format(value);
  static String date(DateTime value, {String? locale}) =>
      DateFormat.yMMMMd(resolvedLocale(locale)).format(value);
  static String dateShort(DateTime value, {String? locale}) =>
      DateFormat.yMMMd(resolvedLocale(locale)).format(value);
  static String weekdayDate(DateTime value, {String? locale}) =>
      DateFormat.MMMMEEEEd(resolvedLocale(locale)).format(value);
  static String time(DateTime value, {String? locale}) =>
      DateFormat.jm(resolvedLocale(locale)).format(value);
  static String dateTime(DateTime value, {String? locale}) =>
      DateFormat.yMMMd(resolvedLocale(locale)).add_jm().format(value);
  static String philippineDateTime(DateTime instant, {String? locale}) =>
      _labels(locale).philippineDateTime(
        dateTime(instant.toUtc().add(const Duration(hours: 8)), locale: locale),
        _labels(locale).philippineTime,
      );
  static String distance(num metres, {String? locale}) => metres < 1000
      ? '${NumberFormat('0', resolvedLocale(locale)).format(metres)} m'
      : '${NumberFormat('0.0', resolvedLocale(locale)).format(metres / 1000)} km';
  static String duration(int minutes, {String? locale}) {
    final l = _labels(locale), hours = minutes ~/ 60, remainder = minutes % 60;
    if (hours == 0) return l.minutesDuration(minutes);
    return remainder == 0
        ? l.hoursDuration(hours)
        : l.hoursMinutesDuration(hours, remainder);
  }

  static String tripCount(int count, {String? locale}) =>
      _labels(locale).numberOfTrips(count);
  static String phoneDisplay(String phone) => phone.length == 11
      ? '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}'
      : phone;
  static String bookingId(String id) =>
      '#${id.substring(0, id.length < 8 ? id.length : 8).toUpperCase()}';
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (name.trim().isEmpty) return '?';
    return '${parts.first[0]}${parts.length > 1 ? parts.last[0] : ''}'
        .toUpperCase();
  }

  static String rating(num value, {String? locale}) =>
      NumberFormat('0.0', resolvedLocale(locale)).format(value);
}
