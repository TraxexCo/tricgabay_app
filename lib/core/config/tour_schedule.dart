import '../services/server_clock.dart';
import '../utils/opening_hours.dart';

/// When and where tours run. Every tour starts and ends at the Bustos
/// Municipal Tourism Office, so the tourist picks a day and a start time,
/// not a pickup point.
///
/// Hours follow the Municipal Arts, Culture and Tourism Office: Monday to
/// Friday, 8:00 AM to 5:00 PM, closed on weekends and public holidays
/// (bustos.cloud/government/departments).
class TourSchedule {
  TourSchedule._();

  /// Bustos Municipal Hall (tourism office), Poblacion, Bustos, Bulacan.
  /// OpenStreetMap way 316341741.
  static const meetingPointLat = 14.95369;
  static const meetingPointLng = 120.91894;

  /// Office opens; the first tour leaves at this hour (Manila time).
  static const openHour = 8;

  /// Office closes; tours must be back by then.
  static const closeHour = 17;

  /// A day tour takes about four hours, so the last start is 1:00 PM.
  static const lastStartHour = 13;

  /// How long a tour takes. Every stop must still be open when it ends.
  static const tourHours = 4;

  /// Days the office runs tours: Monday to Friday (DateTime.monday = 1).
  static const openWeekdays = {1, 2, 3, 4, 5};

  /// Nationwide regular holidays and special non-working days, when the
  /// office is closed. 2026: Proclamation No. 1006; 2027: Proclamation
  /// No. 1427. Eid'l Fitr and Eid'l Adha are proclaimed separately each
  /// year, so add them (and any Bustos local holiday) when announced.
  static final closedDates = <DateTime>{
    // 2026
    DateTime(2026, 1, 1), DateTime(2026, 2, 17), DateTime(2026, 4, 2),
    DateTime(2026, 4, 3), DateTime(2026, 4, 4), DateTime(2026, 4, 9),
    DateTime(2026, 5, 1), DateTime(2026, 6, 12), DateTime(2026, 8, 21),
    DateTime(2026, 8, 31), DateTime(2026, 11, 1), DateTime(2026, 11, 2),
    DateTime(2026, 11, 30), DateTime(2026, 12, 8), DateTime(2026, 12, 24),
    DateTime(2026, 12, 25), DateTime(2026, 12, 30), DateTime(2026, 12, 31),
    // 2027
    DateTime(2027, 1, 1), DateTime(2027, 2, 6), DateTime(2027, 3, 25),
    DateTime(2027, 3, 26), DateTime(2027, 3, 27), DateTime(2027, 4, 9),
    DateTime(2027, 5, 1), DateTime(2027, 6, 12), DateTime(2027, 8, 21),
    DateTime(2027, 8, 30), DateTime(2027, 11, 1), DateTime(2027, 11, 2),
    DateTime(2027, 11, 30), DateTime(2027, 12, 8), DateTime(2027, 12, 24),
    DateTime(2027, 12, 25), DateTime(2027, 12, 30), DateTime(2027, 12, 31),
  };

  /// Whether the office runs tours on this calendar date.
  static bool isOpenDay(DateTime day) =>
      openWeekdays.contains(day.weekday) &&
      !closedDates.contains(DateTime(day.year, day.month, day.day));

  /// The office's contact details, shown on the booking screen.
  static const officeEmail = 'bustostourismofficial@gmail.com';
  static const officePhone = '+639179189665';

  /// The server only accepts bookings at least an hour ahead.
  static const minimumLead = Duration(hours: 1);

  /// And at most a year ahead (migration 20261122060000).
  static const bookingWindowDays = 365;

  /// Quick day buttons on the booking screen; the calendar covers the rest.
  static const quickDayCount = 10;

  /// The earliest and latest start, in minutes after midnight, on [day]
  /// (a Manila calendar date) for a tour whose stops keep [stopHours].
  ///
  /// It starts from the office window ([openHour] to [lastStartHour]) and
  /// narrows it to the stops: no start before the last stop to open, and the
  /// tour ([tourHours]) must end before the first stop to close. A stop with
  /// two sittings in a day counts its first. Hours that cannot be read, and
  /// "open 24 hours", set no limit. Null when a stop is closed that day or
  /// the window is empty.
  static ({int first, int last})? startWindow(
    DateTime day, {
    Iterable<String> stopHours = const [],
  }) {
    var first = openHour * 60;
    var last = lastStartHour * 60;
    for (final text in stopHours) {
      final blocks = OpeningHoursText.parse(text);
      if (blocks == null) continue;
      final today = blocks.where((b) => b.days.contains(day.weekday)).toList()
        ..sort(
          (a, b) => (a.opens.hour * 60 + a.opens.minute).compareTo(
            b.opens.hour * 60 + b.opens.minute,
          ),
        );
      if (today.isEmpty) return null;
      final opens = today.first.opens.hour * 60 + today.first.opens.minute;
      final closes = today.first.closes.hour * 60 + today.first.closes.minute;
      if (opens > first) first = opens;
      if (closes - tourHours * 60 < last) last = closes - tourHours * 60;
    }
    return first > last ? null : (first: first, last: last);
  }

  /// Whether [start] is a time a tour may start: an open day, inside the
  /// [startWindow] for [stopHours] Manila time, and at least [minimumLead]
  /// from now. Used for a custom time picked by hand.
  static bool isValidStart(
    DateTime start, {
    DateTime? now,
    Iterable<String> stopHours = const [],
  }) {
    final local = ServerClock.manila(start);
    final day = DateTime(local.year, local.month, local.day);
    final minutes = local.hour * 60 + local.minute;
    final window = startWindow(day, stopHours: stopHours);
    return isOpenDay(day) &&
        window != null &&
        minutes >= window.first &&
        minutes <= window.last &&
        !start.isBefore((now ?? ServerClock.now()).add(minimumLead));
  }

  /// Start times offered on [day] (a Manila calendar date), on the hour
  /// inside the [startWindow]. For today only the times at least
  /// [minimumLead] away remain; a closed day has none.
  static List<DateTime> startTimes(
    DateTime day, {
    DateTime? now,
    Iterable<String> stopHours = const [],
  }) {
    if (!isOpenDay(day)) return const [];
    final window = startWindow(day, stopHours: stopHours);
    if (window == null) return const [];
    final earliest = (now ?? ServerClock.now()).add(minimumLead);
    return [
      for (
        var hour = (window.first + 59) ~/ 60;
        hour * 60 <= window.last;
        hour++
      )
        ServerClock.fromManila(day.year, day.month, day.day, hour, 0),
    ].where((start) => !start.isBefore(earliest)).toList();
  }

  /// Every start on [day] in 15-minute steps inside the [startWindow], for
  /// the custom time sheet. Same lead-time rule as [startTimes].
  static List<DateTime> quarterHourStarts(
    DateTime day, {
    DateTime? now,
    Iterable<String> stopHours = const [],
  }) {
    if (!isOpenDay(day)) return const [];
    final window = startWindow(day, stopHours: stopHours);
    if (window == null) return const [];
    final earliest = (now ?? ServerClock.now()).add(minimumLead);
    return [
      for (var m = (window.first + 14) ~/ 15 * 15; m <= window.last; m += 15)
        ServerClock.fromManila(day.year, day.month, day.day, m ~/ 60, m % 60),
    ].where((start) => !start.isBefore(earliest)).toList();
  }

  /// The next days a tour can still be booked, starting today (Manila).
  /// Today drops out once its last start time is less than an hour away,
  /// e.g. after 12:00 noon, or at 8:00 PM as in the example.
  static List<DateTime> bookableDays({
    DateTime? now,
    Iterable<String> stopHours = const [],
  }) {
    final current = now ?? ServerClock.now();
    final today = ServerClock.manila(current);
    return [
          for (var i = 0; i < bookingWindowDays; i++)
            DateTime(today.year, today.month, today.day + i),
        ]
        .where(
          (day) =>
              startTimes(day, now: current, stopHours: stopHours).isNotEmpty,
        )
        .toList();
  }
}
