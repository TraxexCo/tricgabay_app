import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/embedded_rows.dart';
import 'package:tricgabay_app/core/services/section_refresh.dart';

void main() {
  // The shapes PostgREST really returns for the bookings query's
  // booking_reviews(rating,review) embed. booking_reviews.booking_id is the
  // table's primary key, so it is an object or null; a one-to-many embed
  // (say booking_stops) would be a list.
  const reviewedObject =
      '{"id":"b1","booking_reviews":{"rating":5,"review":"Great driver"}}';
  const reviewedList =
      '{"id":"b2","booking_reviews":[{"rating":4,"review":"Good"}]}';
  const notReviewed = '{"id":"b3","booking_reviews":null}';
  const emptyList = '{"id":"b4","booking_reviews":[]}';
  Map<String, dynamic> decode(String json) =>
      jsonDecode(json) as Map<String, dynamic>;

  group('embeddedRows', () {
    test('a single object (the real one-to-one shape) is one row', () {
      final rows = embeddedRows(decode(reviewedObject)['booking_reviews']);
      expect(rows, hasLength(1));
      expect(rows.first['rating'], 5);
      expect(rows.first['review'], 'Great driver');
    });

    test('a list is its rows, in order', () {
      final rows = embeddedRows(decode(reviewedList)['booking_reviews']);
      expect(rows, hasLength(1));
      expect(rows.first['rating'], 4);
      expect(
        embeddedRows([
          {'n': 1},
          {'n': 2},
        ]).map((r) => r['n']),
        [1, 2],
      );
    });

    test('null and an empty list are no rows', () {
      expect(embeddedRows(decode(notReviewed)['booking_reviews']), isEmpty);
      expect(embeddedRows(decode(emptyList)['booking_reviews']), isEmpty);
      expect(embeddedRows(null), isEmpty);
    });

    test('an unexpected shape is an error, not silently "no rows"', () {
      expect(() => embeddedRows('rating'), throwsFormatException);
      expect(() => embeddedRows(5), throwsFormatException);
      expect(() => embeddedRows([1, 2]), throwsFormatException);
    });

    test('the result is typed, so rows can be read without casts', () {
      final rows = embeddedRows(decode(reviewedObject)['booking_reviews']);
      expect(rows, isA<List<Map<String, dynamic>>>());
    });
  });

  group('a booking with a review is not dropped', () {
    // The same steps the bookings mapper takes for the review: read the
    // embed, take the first row's rating and text.
    ({double? rating, Object? review}) reviewOf(Map<String, dynamic> row) {
      final reviews = embeddedRows(row['booking_reviews']);
      return (
        rating: reviews.isEmpty
            ? null
            : (reviews.first['rating'] as num).toDouble(),
        review: reviews.isEmpty ? null : reviews.first['review'],
      );
    }

    test(
      'object, list and null shapes in one page all keep their bookings',
      () async {
        final kept = <String, ({double? rating, Object? review})>{};
        final failures = <Object>[];
        for (final json in [
          reviewedObject,
          reviewedList,
          notReviewed,
          emptyList,
        ]) {
          final row = decode(json);
          await readRowIndependently(
            () async => kept[row['id'] as String] = reviewOf(row),
            (error, stack) => failures.add(error),
            rowName: 'booking ${row['id']}',
          );
        }
        expect(failures, isEmpty);
        expect(kept.keys, ['b1', 'b2', 'b3', 'b4']);
        expect(kept['b1']!.rating, 5.0);
        expect(kept['b1']!.review, 'Great driver');
        expect(kept['b2']!.rating, 4.0);
        expect(kept['b3']!.rating, isNull);
        expect(kept['b4']!.rating, isNull);
      },
    );

    test(
      'the old `as List?` read is what dropped the reviewed booking',
      () async {
        final failures = <Object>[];
        final dropped = await readRowIndependently(() async {
          final row = decode(reviewedObject);
          // ignore: unnecessary_cast
          final reviews = row['booking_reviews'] as List? ?? [];
          reviews.length;
        }, (error, stack) => failures.add(error));
        expect(dropped, isFalse);
        expect(failures.single, isA<TypeError>());
      },
    );
  });

  group('readRowIndependently', () {
    late DebugPrintCallback originalDebugPrint;
    late List<String> printed;

    setUp(() {
      originalDebugPrint = debugPrint;
      printed = [];
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) printed.add(message);
      };
    });
    tearDown(() => debugPrint = originalDebugPrint);

    test('names the skipped row and the reason in debug builds', () async {
      final failures = <Object>[];
      final ok = await readRowIndependently(
        () async => throw StateError('review has no rating'),
        (error, stack) => failures.add(error),
        rowName: 'booking 0ca0c9f8',
      );
      expect(ok, isFalse);
      expect(failures, hasLength(1)); // onFailure still runs
      expect(printed, hasLength(1));
      expect(printed.single, contains('skipped booking 0ca0c9f8'));
      expect(printed.single, contains('StateError'));
      expect(printed.single, contains('review has no rating'));
    });

    test('says "a row" when no label is given', () async {
      await readRowIndependently(() async => throw 'boom', (e, s) {});
      expect(printed.single, contains('skipped a row'));
      expect(printed.single, contains('boom'));
    });

    test('prints nothing for a row that reads fine', () async {
      final ok = await readRowIndependently(
        () async {},
        (e, s) {},
        rowName: 'x',
      );
      expect(ok, isTrue);
      expect(printed, isEmpty);
    });

    test('later rows are still read after a skipped one', () async {
      final collected = <int>[];
      for (final value in [1, 'bad', 2]) {
        await readRowIndependently(
          () async => collected.add(value as int),
          (error, stack) {},
          rowName: 'row $value',
        );
      }
      expect(collected, [1, 2]);
      expect(printed.single, contains('row bad'));
    });
  });
}
