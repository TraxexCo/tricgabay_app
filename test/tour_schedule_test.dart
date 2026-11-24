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
    // Christmas Eve, Christmas, Rizal Day and New Year's Eve are closed too.
    for (final day in [24, 25, 30, 31]) {
      expect(days, isNot(contains(DateTime(2026, 12, day))));
    }
  });

  test('the calendar reaches a year ahead', () {
    final days = TourSchedule.bookableDays(now: manila(11, 22, 7));
    expect(days.last.isAfter(DateTime(2027, 11, 1)), isTrue);
    expect(days.last.isBefore(DateTime(2027, 11, 23)), isTrue);
  });

  test('a custom start must be inside office hours and an hour ahead', () {
    final now = manila(11, 23, 9);
    // Monday 23 Nov 2026.
    expect(TourSchedule.isValidStart(manila(11, 23, 10, 30), now: now), true);
    expect(TourSchedule.isValidStart(manila(11, 23, 9, 30), now: now), false);
    expect(TourSchedule.isValidStart(manila(11, 23, 13, 15), now: now), false);
    expect(TourSchedule.isValidStart(manila(11, 24, 7, 45), now: now), false);
    expect(TourSchedule.isValidStart(manila(11, 24, 8, 30), now: now), true);
    // Saturday and Bonifacio Day.
    expect(TourSchedule.isValidStart(manila(11, 28, 9), now: now), false);
    expect(TourSchedule.isValidStart(manila(11, 30, 9), now: now), false);
  });

  group('start window from the stops\' opening hours', () {
    final tuesday = DateTime(2026, 11, 24);
    const chapel = 'Mon–Fri 8:00 AM–5:00 PM';
    const zenys = 'Mon–Fri 7:00 AM–6:00 PM · Sat, Sun 7:00 AM–5:00 PM';
    const galilee = 'Mon–Sun 7:00 AM–3:00 PM · Mon–Sun 4:00 PM–11:00 PM';

    test('without stop hours the office window is unchanged', () {
      final window = TourSchedule.startWindow(tuesday)!;
      expect(window.first, 8 * 60);
      expect(window.last, 13 * 60);
    });

    test('stops open 8-5 and 7-6 keep the usual 8:00 to 1:00 window', () {
      final window = TourSchedule.startWindow(
        tuesday,
        stopHours: const [chapel, zenys],
      )!;
      expect((window.first, window.last), (8 * 60, 13 * 60));
    });

    test('a stop that closes at 3 PM ends the last start at 11:00 AM', () {
      final window = TourSchedule.startWindow(
        tuesday,
        stopHours: const [chapel, galilee],
      )!;
      expect(window.last, 11 * 60);
    });

    test('a late opening pushes the first start later', () {
      final window = TourSchedule.startWindow(
        tuesday,
        stopHours: const ['Mon–Fri 9:30 AM–5:00 PM'],
      )!;
      expect(window.first, 9 * 60 + 30);
    });

    test('a stop closed that weekday, or hours too short, leave no start', () {
      expect(
        TourSchedule.startWindow(
          DateTime(2026, 11, 28),
          stopHours: const [chapel],
        ),
        isNull,
      );
      expect(
        TourSchedule.startWindow(
          tuesday,
          stopHours: const ['Mon–Fri 8:00 AM–11:00 AM'],
        ),
        isNull,
      );
    });

    test('unreadable or all-day hours set no limit', () {
      final window = TourSchedule.startWindow(
        tuesday,
        stopHours: const ['Check locally', 'Open 24 hours, daily'],
      )!;
      expect((window.first, window.last), (8 * 60, 13 * 60));
    });

    test('offered times and the custom check follow the window', () {
      final now = manila(11, 23, 7);
      final hours = TourSchedule.startTimes(
        tuesday,
        now: now,
        stopHours: const [chapel, galilee],
      );
      expect(hours.length, 4); // 8, 9, 10, 11
      final quarters = TourSchedule.quarterHourStarts(
        tuesday,
        now: now,
        stopHours: const [chapel, galilee],
      );
      expect(quarters.first, manila(11, 24, 8));
      expect(quarters.last, manila(11, 24, 11));
      expect(
        TourSchedule.isValidStart(
          manila(11, 24, 11, 15),
          now: now,
          stopHours: const [chapel, galilee],
        ),
        false,
      );
      expect(
        TourSchedule.isValidStart(
          manila(11, 24, 11),
          now: now,
          stopHours: const [chapel, galilee],
        ),
        true,
      );
    });
  });
}
