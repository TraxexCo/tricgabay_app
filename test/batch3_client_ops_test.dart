import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tricgabay_app/l10n/app_localizations.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:tricgabay_app/l10n/app_localizations_fil.dart';
import 'package:tricgabay_app/core/widgets/role_navigation_bar.dart';
import 'package:tricgabay_app/core/utils/validators.dart';
import 'package:tricgabay_app/core/services/error_messages.dart';
import 'package:tricgabay_app/core/services/connectivity_monitor.dart';
import 'package:tricgabay_app/core/widgets/offline_banner.dart';
import 'package:tricgabay_app/core/session/app_session.dart';
import 'package:tricgabay_app/features/tourist/screens/tourist_home_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_home_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_application_pending_screen.dart';

void main() {
  test('Filipino validators and safe errors use the selected locale', () {
    final previous = Intl.defaultLocale;
    Intl.defaultLocale = 'fil';
    addTearDown(() => Intl.defaultLocale = previous);
    expect(Validators.email(''), MessageCode.emailAddressIsRequired);
    expect(
      resolveMessage(
        AppLocalizationsFil(),
        Validators.maxLength('abcdef', 3, fieldName: MessageCode.title)!,
      ),
      'Hindi dapat lumampas sa 3 karakter ang Pamagat',
    );
    expect(
      resolveMessage(
        AppLocalizationsFil(),
        MessageCode.goodMorningValue('Maria'),
      ),
      'Magandang umaga, Maria',
    );
    expect(
      resolveMessage(AppLocalizationsFil(), MessageCode.openReviewsValue('2')),
      'Mga bukas na pagsusuri: 2',
    );
    expect(
      resolveMessage(
        AppLocalizationsFil(),
        ErrorMessages.forError(Exception('secret server response')),
      ),
      'Hindi makumpleto ang aksiyong ito. Nananatili ang iyong mga tala. I-refresh at subukan muli.',
    );
  });
  testWidgets('offline banner retries and reconnect catches up once', (
    tester,
  ) async {
    final events = StreamController<List<ConnectivityResult>>();
    var retries = 0, reconnects = 0;
    var current = [ConnectivityResult.none];
    final monitor = ConnectivityMonitor(
      check: () async => current,
      changes: events.stream,
      onReconnect: () async {
        reconnects++;
      },
    )..start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineBanner(
            monitor: monitor,
            retry: () async {
              retries++;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline'), findsOneWidget);
    await tester.tap(find.text('Retry connection'));
    await tester.pumpAndSettle();
    expect(retries, 1);
    current = [ConnectivityResult.wifi];
    events.add(current);
    await tester.pumpAndSettle();
    expect(reconnects, 1);
    expect(find.text('Retry connection'), findsNothing);
    events.add(current);
    await tester.pumpAndSettle();
    expect(reconnects, 1);
    monitor.dispose();
    unawaited(events.close());
    await tester.pump();
  });
  testWidgets(
    'pending driver screen offers documents without operational controls',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DriverApplicationPendingScreen(
            loader: () async => {
              'license_document_path': 'fixture',
              'vehicle_document_path': 'fixture',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Application pending'), findsOneWidget);
      expect(find.text('Update application'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(find.text('Go online'), findsNothing);
    },
  );
  for (final filipino in [false, true]) {
    for (final driver in [false, true]) {
      testWidgets(
        '${driver ? 'driver' : 'tourist'} ${filipino ? 'Filipino' : 'English'} home respects 1.5x text on a small screen',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final oldOnline = AppSession.isDriverOnline.value;
          AppSession.isDriverOnline.value = false;
          addTearDown(() => AppSession.isDriverOnline.value = oldOnline);
          final oldLanguage = AppSession.isFilipino.value;
          AppSession.isFilipino.value = filipino;
          addTearDown(() => AppSession.isFilipino.value = oldLanguage);
          final semantics = tester.ensureSemantics();

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                locale: Locale(filipino ? 'fil' : 'en'),
                supportedLocales: const [Locale('en'), Locale('fil')],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: child!,
                ),
                home: Scaffold(
                  body: Column(
                    children: [
                      Expanded(
                        child: driver
                            ? const DriverHomeScreen()
                            : const TouristHomeScreen.withMapPlaceholder(
                                map: ColoredBox(color: Colors.grey),
                              ),
                      ),
                      RoleNavigationBar(
                        currentIndex: 0,
                        onSelected: (_) {},
                        destinations: const [
                          RoleNavigationDestination(
                            icon: Icons.home,
                            selectedIcon: Icons.home,
                            label: 'Ride',
                          ),
                          RoleNavigationDestination(
                            icon: Icons.list,
                            selectedIcon: Icons.list,
                            label: 'Jobs',
                          ),
                          RoleNavigationDestination(
                            icon: Icons.money,
                            selectedIcon: Icons.money,
                            label: 'Earnings',
                          ),
                          RoleNavigationDestination(
                            icon: Icons.person,
                            selectedIcon: Icons.person,
                            label: 'Account',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
          expect(
            find.byTooltip(
              filipino ? AppLocalizationsFil().notifications : 'Notifications',
            ),
            findsOneWidget,
          );
          expect(
            find.bySemanticsLabel(
              RegExp(
                filipino
                    ? AppLocalizationsFil().notifications
                    : 'Notifications',
              ),
            ),
            findsWidgets,
          );
          semantics.dispose();
          final vertical = find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          );
          if (vertical.evaluate().isNotEmpty) {
            await tester.drag(vertical.first, const Offset(0, -600));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
      );
    }
  }
}
