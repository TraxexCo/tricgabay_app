import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tricgabay_app/core/prototype/prototype_session.dart';
import 'package:tricgabay_app/core/services/auth_service.dart';
import 'package:tricgabay_app/core/services/realtime_refresh_policy.dart';
import 'package:tricgabay_app/core/widgets/list_skeleton.dart';
import 'package:tricgabay_app/features/auth/screens/splash_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/tourist_bookings_screen.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'startup can render while sign-in state is loading and opens as soon as it resolves',
    (tester) async {
      final profile = Completer<SignedInProfile?>();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                SplashScreen(restoreProfile: () => profile.future),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const Scaffold(body: Text('Ready')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Ready'), findsNothing);
      profile.complete(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Ready'), findsOneWidget);
    },
  );

  testWidgets(
    'bookings show a skeleton during the first fetch and an empty state when it finishes',
    (tester) async {
      PrototypeSession.bookings.value = [];
      PrototypeSession.loadingSections.value = {RemoteSection.bookings};
      addTearDown(() => PrototypeSession.loadingSections.value = const {});
      await tester.pumpWidget(const MaterialApp(home: TouristBookingsScreen()));
      expect(find.byType(ListSkeleton), findsOneWidget);
      PrototypeSession.loadingSections.value = const {};
      await tester.pump();
      expect(find.byType(ListSkeleton), findsNothing);
      expect(find.text('No active trips'), findsOneWidget);
    },
  );
}
