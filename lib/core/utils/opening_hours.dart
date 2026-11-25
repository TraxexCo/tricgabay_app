import 'package:flutter/material.dart' show TimeOfDay;
import 'package:intl/intl.dart';

/// One block of opening hours, such as Monday to Friday, 8 AM to 5 PM.
class HoursBlock {
  HoursBlock(this.days, this.opens, this.closes);

  /// Weekdays, 1 = Monday ... 7 = Sunday.
  final Set<int> days;
  TimeOfDay opens, closes;
}

/// Turns opening hours into the stored text and back.
///
/// The text is kept in English because it is the record the server holds,
/// for example "Mon–Fri 8:00 AM–5:00 PM · Sat–Sun 7:00 AM–5:00 PM".
class OpeningHoursText {
  OpeningHoursText._();

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const open24 = 'Open 24 hours, daily';
  static const _separator = ' · ';

  static String _time(TimeOfDay t) =>
      DateFormat('h:mm a', 'en').format(DateTime(2000, 1, 1, t.hour, t.minute));

  static String _days(Set<int> days) {
    final sorted = days.toList()..sort();
    final ranges = <String>[];
    var start = sorted.first, previous = sorted.first;
    void flush() => ranges.add(
      start == previous
          ? _dayNames[start - 1]
          : previous == start + 1
          ? '${_dayNames[start - 1]}, ${_dayNames[previous - 1]}'
          : '${_dayNames[start - 1]}–${_dayNames[previous - 1]}',
    );
    for (final day in sorted.skip(1)) {
      if (day == previous + 1) {
        previous = day;
        continue;
      }
      flush();
      start = previous = day;
    }
    flush();
    return ranges.join(', ');
  }

  static String format(List<HoursBlock> blocks, {bool allDay = false}) {
    if (allDay) return open24;
    return blocks
        .where((b) => b.days.isNotEmpty)
        .map((b) => '${_days(b.days)} ${_time(b.opens)}–${_time(b.closes)}')
        .join(_separator);
  }

  static TimeOfDay? _parseTime(String text) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AP]M)$',
    ).firstMatch(text.trim());
    if (match == null) return null;
    var hour = int.parse(match[1]!) % 12;
    if (match[3] == 'PM') hour += 12;
    return TimeOfDay(hour: hour, minute: int.parse(match[2]!));
  }

  static Set<int>? _parseDays(String text) {
    final days = <int>{};
    for (final part in text.split(',')) {
      final bounds = part.trim().split('–');
      final first = _dayNames.indexOf(bounds.first.trim()) + 1;
      final last = _dayNames.indexOf(bounds.last.trim()) + 1;
      if (first == 0 || last == 0 || last < first) return null;
      for (var d = first; d <= last; d++) {
        days.add(d);
      }
    }
    return days.isEmpty ? null : days;
  }

  /// Blocks read back from [text], or null when it is not in this format.
  static List<HoursBlock>? parse(String text) {
    final blocks = <HoursBlock>[];
    for (final part in text.split(_separator)) {
      final match = RegExp(
        r'^(.+?)\s(\d{1,2}:\d{2}\s[AP]M)–(\d{1,2}:\d{2}\s[AP]M)$',
      ).firstMatch(part.trim());
      if (match == null) return null;
      final days = _parseDays(match[1]!);
      final opens = _parseTime(match[2]!);
      final closes = _parseTime(match[3]!);
      if (days == null || opens == null || closes == null) return null;
      blocks.add(HoursBlock(days, opens, closes));
    }
    return blocks.isEmpty ? null : blocks;
  }
}
