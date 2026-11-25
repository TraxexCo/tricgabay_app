import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/constants/app_colors.dart';
import 'package:tricgabay_app/core/session/app_session.dart';
import 'package:tricgabay_app/features/admin/reviewed_bookings.dart';
import 'package:tricgabay_app/features/admin/screens/ratings_feedback_screen.dart';
import 'package:tricgabay_app/models/booking_model.dart';

import 'trip_rules_test.dart' show accepted;

const _placeholder = 'Great ride, very knowledgeable about Bustos!';

/// A completed booking; pass [rating] to give it a review.
BookingModel booking(
  String id, {
  double? rating,
  String? review,
  DateTime? reviewedAt,
  String tourist = 'Tourist',
  String driver = 'Marco',
  BookingStatus status = BookingStatus.completed,
}) => accepted().copyWith(
  id: id,
  touristName: tourist,
  driverName: driver,
  status: status,
  completedAt: DateTime(2026, 11, 1),
  driverRating: rating,
  driverReview: review,
  driverReviewedAt: reviewedAt,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppSession.bookings.value = [];
    await AppSession.initialize();
  });

  Future<void> showScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RatingsFeedbackScreen())),
    );
    await tester.pumpAndSettle();
  }

  /// How many of a card's five stars are filled.
  int filledStars(WidgetTester tester, String bookingId) {
    final icons = tester.widgetList<Icon>(
      find.descendant(
        of: find.byKey(Key('review-stars-$bookingId')),
        matching: find.byIcon(Icons.star),
      ),
    );
    expect(icons, hasLength(5));
    return icons.where((i) => i.color == AppColors.secondary).length;
  }

  group('reviewedBookings', () {
    test('keeps only bookings with a review, newest review first', () {
      final list = reviewedBookings([
        booking('old', rating: 4, reviewedAt: DateTime(2026, 11, 2)),
        booking('unreviewed'),
        booking('new', rating: 5, reviewedAt: DateTime(2026, 11, 20)),
        booking('cancelled', status: BookingStatus.cancelled),
        booking('mid', rating: 3, reviewedAt: DateTime(2026, 11, 10)),
      ]);
      expect(list.map((b) => b.id), ['new', 'mid', 'old']);
    });

    test('falls back to the completion time, then keeps a stable order', () {
      final list = reviewedBookings([
        booking('a', rating: 5),
        booking('b', rating: 5),
        booking('c', rating: 5, reviewedAt: DateTime(2027)),
      ]);
      expect(list.map((b) => b.id), ['c', 'b', 'a']);
    });

    test('nothing reviewed is an empty list', () {
      expect(reviewedBookings([booking('x'), booking('y')]), isEmpty);
      expect(reviewedBookings(const []), isEmpty);
    });

    test('stars are whole numbers from 0 to 5', () {
      expect(starCount(5), 5);
      expect(starCount(3.4), 3);
      expect(starCount(3.5), 4);
      expect(starCount(0), 0);
      expect(starCount(9), 5);
      expect(starCount(-2), 0);
    });
  });

  group('the Reviews tab shows the real review', () {
    testWidgets('a 5-star review with no text shows five stars and no text', (
      tester,
    ) async {
      AppSession.bookings.value = [
        booking(
          'aaaa1111-0000-4000-8000-000000000001',
          rating: 5,
          review: '',
          reviewedAt: DateTime(2026, 11, 21),
          tourist: 'Rosa Reyes',
          driver: 'Marco Cruz',
        ),
      ];
      await showScreen(tester);
      expect(find.text('Rosa Reyes'), findsOneWidget);
      expect(find.text('Driver: Marco Cruz'), findsOneWidget);
      expect(find.text('Booking #AAAA1111'), findsOneWidget);
      expect(filledStars(tester, 'aaaa1111-0000-4000-8000-000000000001'), 5);
      expect(find.text(_placeholder), findsNothing);
      // Nothing is drawn for the missing text: no empty text line at all.
      expect(find.text(''), findsNothing);
    });

    testWidgets('a 3-star review shows three stars and its text', (
      tester,
    ) async {
      AppSession.bookings.value = [
        booking(
          'bbbb2222-0000-4000-8000-000000000002',
          rating: 3,
          review: 'Tricycle was a bit cramped for three, but fun.',
          reviewedAt: DateTime(2026, 11, 22),
          tourist: 'Ivan Soriano',
          driver: 'Allan Pascual',
        ),
      ];
      await showScreen(tester);
      expect(
        find.text('Tricycle was a bit cramped for three, but fun.'),
        findsOneWidget,
      );
      expect(find.text('Ivan Soriano'), findsOneWidget);
      expect(find.text('Driver: Allan Pascual'), findsOneWidget);
      expect(find.text('Booking #BBBB2222'), findsOneWidget);
      expect(filledStars(tester, 'bbbb2222-0000-4000-8000-000000000002'), 3);
      expect(find.text(_placeholder), findsNothing);
    });

    testWidgets('no reviews shows the empty state', (tester) async {
      AppSession.bookings.value = [];
      await showScreen(tester);
      expect(find.text('No reviews yet'), findsOneWidget);
      expect(
        find.text('Reviews from completed tours appear here.'),
        findsOneWidget,
      );
      expect(
        find.byType(Icon).evaluate().where((e) {
          final icon = e.widget as Icon;
          return icon.icon == Icons.flag;
        }),
        isEmpty,
      );
    });

    testWidgets('completed bookings without a review are not listed', (
      tester,
    ) async {
      AppSession.bookings.value = [
        booking('cccc0000-0000-4000-8000-00000000000a'), // completed, unrated
        booking(
          'cccc0000-0000-4000-8000-00000000000b',
          rating: 4,
          review: 'Good tour, the dam was beautiful.',
          reviewedAt: DateTime(2026, 11, 5),
        ),
        booking('cccc0000-0000-4000-8000-00000000000c'), // completed, unrated
        booking(
          'cccc0000-0000-4000-8000-00000000000d',
          rating: 5,
          review: 'Smooth ride, arrived on time.',
          reviewedAt: DateTime(2026, 11, 9),
        ),
        booking(
          'cccc0000-0000-4000-8000-00000000000e',
          status: BookingStatus.cancelled,
        ),
      ];
      await showScreen(tester);
      expect(
        find.byKey(
          const Key('review-stars-cccc0000-0000-4000-8000-00000000000b'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('review-stars-cccc0000-0000-4000-8000-00000000000d'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Booking #CCCC0000'), findsNWidgets(2));
      expect(find.text('No reviews yet'), findsNothing);
      // Newest review (…d, Nov 9) is above the older one (…b, Nov 5).
      expect(
        tester.getTopLeft(find.text('Smooth ride, arrived on time.')).dy,
        lessThan(
          tester.getTopLeft(find.text('Good tour, the dam was beautiful.')).dy,
        ),
      );
    });

    testWidgets('the list follows the bookings as they change', (tester) async {
      AppSession.bookings.value = [
        booking('dddd0000-0000-4000-8000-000000000001'),
      ];
      await showScreen(tester);
      expect(find.text('No reviews yet'), findsOneWidget);
      AppSession.bookings.value = [
        booking(
          'dddd0000-0000-4000-8000-000000000001',
          rating: 5,
          review: 'Driver waited patiently at every stop.',
          reviewedAt: DateTime(2026, 11, 23),
        ),
      ];
      await tester.pumpAndSettle();
      expect(
        find.text('Driver waited patiently at every stop.'),
        findsOneWidget,
      );
      expect(find.text('No reviews yet'), findsNothing);
    });
  });

  group('the review time and the placeholder text', () {
    test('driverReviewedAt survives the map round trip and copyWith', () {
      final at = DateTime.utc(2026, 11, 21, 4, 5, 6);
      final b = booking('r1', rating: 5, review: 'x', reviewedAt: at);
      final back = BookingModel.fromMap(b.toMap(), 'r1');
      expect(back.driverReviewedAt, at);
      expect(back.copyWith(driverRating: 4).driverReviewedAt, at);
    });

    test(
      'a stored booking from before this field loads with no review time',
      () {
        final map = booking('r2', rating: 5).toMap()
          ..remove('driverReviewedAt');
        expect(BookingModel.fromMap(map, 'r2').driverReviewedAt, isNull);
      },
    );

    test('the sample sentence is gone from both language files', () {
      for (final lang in ['en', 'fil']) {
        final arb =
            jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
                as Map<String, dynamic>;
        expect(
          arb.containsKey('greatRideVeryKnowledgeableAboutBustos'),
          isFalse,
        );
        expect(arb.containsKey('noReviewsYet'), isTrue);
        expect(arb.containsKey('noReviewsYetBody'), isTrue);
        expect(arb.containsKey('ratingOutOfFiveValue'), isTrue);
      }
    });
  });
}
