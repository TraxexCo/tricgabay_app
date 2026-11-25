import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tricgabay_app/core/session/app_session.dart';
import 'package:tricgabay_app/features/admin/screens/admin_shell_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_shell_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/tourist_shell_screen.dart';

typedef ShellBuilder = Widget Function(StatefulNavigationShell shell);

GoRouter _router(ShellBuilder shellBuilder) => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => shellBuilder(shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const Center(child: Text('root page')),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/second',
              builder: (_, _) => const Center(child: Text('second tab')),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/third',
              builder: (_, _) => const Center(child: Text('third tab')),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/fourth',
              builder: (_, _) => const Center(child: Text('fourth tab')),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/detail',
      builder: (_, _) => const Scaffold(body: Text('detail page')),
    ),
  ],
);

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('system Back pops a tourist child route before the shell', (
    tester,
  ) async {
    final router = _router(
      (shell) => TouristShellScreen(navigationShell: shell),
    );
    addTearDown(router.dispose);
    await _pumpRouter(tester, router);

    router.push('/detail');
    await tester.pumpAndSettle();
    expect(find.text('detail page'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('root page'), findsOneWidget);
  });

  testWidgets('system Back returns through tourist tab history', (
    tester,
  ) async {
    final router = _router(
      (shell) => TouristShellScreen(navigationShell: shell),
    );
    addTearDown(router.dispose);
    await _pumpRouter(tester, router);

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('second tab'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('root page'), findsOneWidget);
  });

  testWidgets('Back retains visits to a tab that was opened twice', (
    tester,
  ) async {
    final router = _router(
      (shell) => TouristShellScreen(navigationShell: shell),
    );
    addTearDown(router.dispose);
    await _pumpRouter(tester, router);

    for (final label in ['Discover', 'Trips', 'Discover']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('third tab'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('second tab'), findsOneWidget);
  });

  testWidgets('driver and administrator child routes retain a Back target', (
    tester,
  ) async {
    for (final shellBuilder in <ShellBuilder>[
      (shell) => DriverShellScreen(navigationShell: shell),
      (shell) => AdminShellScreen(navigationShell: shell),
    ]) {
      final router = _router(shellBuilder);
      await _pumpRouter(tester, router);
      router.push('/detail');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('root page'), findsOneWidget);
      router.dispose();
    }
  });

  testWidgets('Back dismisses a modal before its underlying page', (
    tester,
  ) async {
    final router = _router(
      (shell) => TouristShellScreen(navigationShell: shell),
    );
    addTearDown(router.dispose);
    await _pumpRouter(tester, router);

    final context = tester.element(find.text('root page'));
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(title: Text('modal content')),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('modal content'), findsNothing);
    expect(find.text('root page'), findsOneWidget);
  });

  testWidgets('leaving an active-trip page does not mutate active trip state', (
    tester,
  ) async {
    final router = _router(
      (shell) => DriverShellScreen(navigationShell: shell),
    );
    addTearDown(router.dispose);
    AppSession.activeDriverBookingId = 'active-booking';
    addTearDown(() => AppSession.activeDriverBookingId = null);
    await _pumpRouter(tester, router);

    router.push('/detail');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(AppSession.activeDriverBookingId, 'active-booking');
    expect(find.text('root page'), findsOneWidget);
  });
}
