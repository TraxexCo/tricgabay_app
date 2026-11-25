import 'package:tricgabay_app/core/widgets/app_button.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Response;
import 'package:tricgabay_app/core/services/map_route_service.dart';
import 'package:tricgabay_app/core/services/error_messages.dart';
import 'package:tricgabay_app/features/admin/screens/send_announcement_screen.dart';

class FakeDirectionsAdapter implements HttpClientAdapter {
  FakeDirectionsAdapter({this.hang = false, this.alternatives = false});

  final bool hang;
  final bool alternatives;
  int calls = 0;
  final cancelled = Completer<void>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    expect(options.path, contains('/mapbox/driving-traffic/'));
    if (hang) {
      await cancelFuture;
      cancelled.complete();
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'routes': [
          if (alternatives)
            {
              'geometry': {
                'coordinates': [
                  [120.9, 14.95],
                  [121.0, 14.95],
                ],
              },
              'duration': 60,
              'notifications': ['restriction violation'],
            },
          {
            'geometry': {
              'coordinates': [
                [120.9, 14.95],
                [121.0, 14.95],
              ],
            },
            'distance': 1000,
            'duration': 300,
            'legs': [],
          },
          if (alternatives)
            {
              'geometry': {
                'coordinates': [
                  [120.9, 14.95],
                  [121.0, 14.95],
                ],
              },
              'duration': 240,
            },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Directions supports 13-coordinate trips, caches plans and bounds requests',
    () async {
      final adapter = FakeDirectionsAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      MapRouteService.configureForTesting(dio);
      final points = List.generate(
        13,
        (i) => Position(120.9 + i * 0.001, 14.95),
      );
      final concurrent = await Future.wait([
        MapRouteService.tricyclePreferred(points),
        MapRouteService.tricyclePreferred(points),
      ]);
      final first = concurrent.first;
      expect(identical(first, concurrent.last), isTrue);
      final second = await MapRouteService.tricyclePreferred(points);
      expect(identical(first, second), isTrue);
      expect(adapter.calls, 1);
      await expectLater(
        MapRouteService.tricyclePreferred(
          List.generate(26, (i) => Position(120.9, 14.95)),
        ),
        throwsArgumentError,
      );
      expect(adapter.calls, 1);
    },
  );
  test(
    'Directions chooses the fastest route without a restriction violation',
    () async {
      final adapter = FakeDirectionsAdapter(alternatives: true);
      MapRouteService.configureForTesting(Dio()..httpClientAdapter = adapter);
      final plan = await MapRouteService.tricyclePreferred([
        Position(120.9, 14.95),
        Position(121.0, 14.95),
      ]);
      expect(plan.restrictionViolation, isFalse);
      expect(plan.durationSeconds, 240);
    },
  );
  test('slow directions are cancelled at the total request deadline', () async {
    final adapter = FakeDirectionsAdapter(hang: true);
    final dio = Dio()..httpClientAdapter = adapter;
    MapRouteService.configureForTesting(
      dio,
      deadline: const Duration(milliseconds: 40),
    );
    await expectLater(
      MapRouteService.tricyclePreferred([
        Position(120.9, 14.95),
        Position(121.0, 14.95),
      ]),
      throwsA(isA<ClientOperationException>()),
    );
    expect(adapter.calls, 1);
    await adapter.cancelled.future.timeout(const Duration(seconds: 1));
  });
  test('Poppins weights load with runtime fetching disabled', () async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await GoogleFonts.pendingFonts([
      for (final weight in [
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
        FontWeight.w700,
        FontWeight.w800,
      ])
        GoogleFonts.poppins(fontWeight: weight),
    ]);
  });
  testWidgets('announcement preview can be cancelled without sending', (
    tester,
  ) async {
    var sent = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SendAnnouncementScreen(
          send: (title, body, audience, requestId) async {
            sent++;
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'Service update');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Service will open tomorrow.',
    );
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(find.text('Preview announcement'), findsOneWidget);
    expect(find.text('Audience: all'), findsOneWidget);
    expect(sent, 0);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(sent, 0);
  });
  testWidgets(
    'announcement failure stays visible and does not report success',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SendAnnouncementScreen(
            send: (title, body, audience, requestId) async {
              throw StateError('private provider detail');
            },
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Service update',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Service will open tomorrow.',
      );
      await tester.ensureVisible(find.byType(AppButton));
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm and send'));
      await tester.pumpAndSettle();
      expect(find.text('Announcement sent successfully'), findsNothing);
      expect(find.textContaining('private provider detail'), findsNothing);
      expect(find.textContaining('could not be completed'), findsOneWidget);
    },
  );
}
