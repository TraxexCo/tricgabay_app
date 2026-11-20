import '../utils/formatters.dart';

class ServerClock {
  static DateTime? _anchor;
  static final Stopwatch _elapsed = Stopwatch();
  static DateTime now() =>
      _anchor == null ? DateTime.now().toUtc() : _anchor!.add(_elapsed.elapsed);
  static void synchronize(
    DateTime serverTime, {
    Duration roundTrip = Duration.zero,
  }) {
    _anchor = serverTime.toUtc().add(
      Duration(microseconds: roundTrip.inMicroseconds ~/ 2),
    );
    _elapsed
      ..reset()
      ..start();
  }

  static DateTime manila(DateTime instant) =>
      instant.toUtc().add(const Duration(hours: 8));
  static DateTime fromManila(
    int year,
    int month,
    int day,
    int hour,
    int minute,
  ) => DateTime.utc(
    year,
    month,
    day,
    hour,
    minute,
  ).subtract(const Duration(hours: 8));
  static String formatManila(DateTime instant, {String? locale}) =>
      AppFormatters.philippineDateTime(instant, locale: locale);
  static void reset() {
    _anchor = null;
    _elapsed.stop();
  }
}
