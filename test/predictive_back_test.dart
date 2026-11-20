import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tricgabay_app/core/navigation/back_handling.dart';
import 'package:tricgabay_app/features/tourist/screens/tourist_shell_screen.dart';

// On Android with predictive back (enableOnBackInvokedCallback="true") the OS
// only sends Back to Flutter while Flutter reports that it handles Back. These
// tests watch what the app reports, which handlePopRoute-based tests skip.

GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          TouristShellScreen(navigationShell: shell),
      branches: [
        for (final (path, label) in [
          ('/home', 'root page'),
          ('/second', 'second tab'),
          ('/third', 'third tab'),
          ('/fourth', 'fourth tab'),
        ])
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: path,
                builder: (_, _) => Center(child: Text(label)),
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

List<bool> _watchReports(WidgetTester tester) {
  final reports = <bool>[];
  // A real phone is resumed; Flutter skips these reports while detached.
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
        reports.add(call.arguments as bool);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return reports;
}

Future<void> _openSecondTab(
  WidgetTester tester,
  GoRouter router, {
  NotificationListenerCallback<NavigationNotification>? onNotification,
}) async {
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      onNavigationNotification: onNotification,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Discover'));
  await tester.pumpAndSettle();
  expect(find.text('second tab'), findsOneWidget);
}

void main() {
  testWidgets('root cause: a tab navigator tells Android Back is unhandled', (
    tester,
  ) async {
    final reports = _watchReports(tester);
    final router = _router();
    addTearDown(router.dispose);
    await _openSecondTab(tester, router);
    // Back on the Discover tab should return to Explore, but the newly built
    // tab navigator's report wins, so Android would close the app.
    expect(reports.last, isFalse);
  });

  testWidgets('the app always keeps Back inside Flutter', (tester) async {
    final reports = _watchReports(tester);
    final router = _router();
    addTearDown(router.dispose);
    await _openSecondTab(tester, router, onNotification: keepBackInFlutter);
    router.push('/detail');
    await tester.pumpAndSettle();
    expect(reports, isNotEmpty);
    expect(reports, everyElement(isTrue));

    // Back still walks the app's own history.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('second tab'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('root page'), findsOneWidget);
  });

  testWidgets('Back on the home tab with nothing to pop exits the app', (
    tester,
  ) async {
    var exited = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exited = true;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        onNavigationNotification: keepBackInFlutter,
      ),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exited, isTrue);
  });
}
