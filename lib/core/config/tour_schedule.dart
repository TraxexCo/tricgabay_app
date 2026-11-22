import '../services/server_clock.dart';

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

  /// Whether [start] is a time a tour may start: an open day, between
  /// [openHour] and [lastStartHour] Manila time, and at least
  /// [minimumLead] from now. Used for a custom time picked by hand.
  static bool isValidStart(DateTime start, {DateTime? now}) {
    final local = ServerClock.manila(start);
    final day = DateTime(local.year, local.month, local.day);
    final minutes = local.hour * 60 + local.minute;
    return isOpenDay(day) &&
        minutes >= openHour * 60 &&
        minutes <= lastStartHour * 60 &&
        !start.isBefore((now ?? ServerClock.now()).add(minimumLead));
  }

  /// Start times offered on [day] (a Manila calendar date). For today only
  /// the times at least [minimumLead] away remain; a closed day has none.
  static List<DateTime> startTimes(DateTime day, {DateTime? now}) {
    if (!isOpenDay(day)) return const [];
    final earliest = (now ?? ServerClock.now()).add(minimumLead);
    return [
      for (var hour = openHour; hour <= lastStartHour; hour++)
        ServerClock.fromManila(day.year, day.month, day.day, hour, 0),
    ].where((start) => !start.isBefore(earliest)).toList();
  }

  /// The next days a tour can still be booked, starting today (Manila).
  /// Today drops out once its last start time is less than an hour away,
  /// e.g. after 12:00 noon, or at 8:00 PM as in the example.
  static List<DateTime> bookableDays({DateTime? now}) {
    final current = now ?? ServerClock.now();
    final today = ServerClock.manila(current);
    return [
      for (var i = 0; i < bookingWindowDays; i++)
        DateTime(today.year, today.month, today.day + i),
    ].where((day) => startTimes(day, now: current).isNotEmpty).toList();
  }
}
