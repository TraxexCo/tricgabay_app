import '../services/server_clock.dart';

/// When and where tours run. Every tour starts and ends at the Bustos
/// Municipal Tourism Office, so the tourist picks a day and a start time,
/// not a pickup point.
///
/// Office hours below are the working assumption (8:00 AM to 5:00 PM, every
/// day); change them here if the tourism office confirms different hours.
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

  /// Days the office runs tours (DateTime.monday = 1 ... sunday = 7).
  static const openWeekdays = {1, 2, 3, 4, 5, 6, 7};

  /// The server only accepts bookings at least an hour ahead.
  static const minimumLead = Duration(hours: 1);

  /// And at most 30 days ahead.
  static const bookingWindowDays = 30;

  /// Start times offered on [day] (a Manila calendar date). For today only
  /// the times at least [minimumLead] away remain; a closed day has none.
  static List<DateTime> startTimes(DateTime day, {DateTime? now}) {
    if (!openWeekdays.contains(day.weekday)) return const [];
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
