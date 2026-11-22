import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/config/tour_schedule.dart';
import 'package:tricgabay_app/core/services/server_clock.dart';

void main() {
  // Manila wall-clock time as the UTC instant the app uses.
  DateTime manila(int month, int day, int hour, [int minute = 0]) =>
      ServerClock.fromManila(2026, month, day, hour, minute);

  test('at 8:00 PM today is closed and tomorrow opens at 8:00 AM', () {
    final now = manila(11, 22, 20);
    final days = TourSchedule.bookableDays(now: now);
    expect(days.first, DateTime(2026, 11, 23));
    final times = TourSchedule.startTimes(days.first, now: now);
    expect(times.first, manila(11, 23, 8));
    expect(times.last, manila(11, 23, 13));
  });

  test('in the morning today offers only starts at least an hour away', () {
    // Tuesday 24 November 2026.
    final now = manila(11, 24, 9, 30);
    final days = TourSchedule.bookableDays(now: now);
    expect(days.first, DateTime(2026, 11, 24));
    final times = TourSchedule.startTimes(days.first, now: now);
    expect(times.first, manila(11, 24, 11));
    expect(times.last, manila(11, 24, 13));
  });

  test('after noon the last 1:00 PM start is gone, so today drops out', () {
    final now = manila(11, 24, 12, 30);
    expect(TourSchedule.bookableDays(now: now).first, DateTime(2026, 11, 25));
  });

  test('weekends and public holidays are closed', () {
    // From Sunday 22 Nov: Bonifacio Day (30 Nov) and the Immaculate
    // Conception (8 Dec) fall inside the 30-day window.
    final days = TourSchedule.bookableDays(now: manila(11, 22, 7));
    expect(days.every((d) => d.weekday <= DateTime.friday), isTrue);
    expect(days, isNot(contains(DateTime(2026, 11, 22))));
    expect(days, isNot(contains(DateTime(2026, 11, 30))));
    expect(days, isNot(contains(DateTime(2026, 12, 8))));
    expect(days.first, DateTime(2026, 11, 23));
    expect(days.last, DateTime(2026, 12, 21));
    expect(days, hasLength(19));
  });
}
