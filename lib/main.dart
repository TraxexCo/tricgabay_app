import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/l10n/locale_controller.dart';
import 'core/widgets/responsive_app_frame.dart';
import 'core/services/connectivity_monitor.dart';
import 'core/widgets/offline_banner.dart';
import 'core/widgets/privacy_consent_gate.dart';
import 'l10n/app_localizations.dart';
import 'core/widgets/minimum_version_gate.dart';
import 'core/navigation/back_handling.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'core/widgets/brand_logo_hero.dart';
import 'core/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/mapbox_config.dart';
import 'core/config/backend_config.dart';
import 'core/config/build_environment.dart';
import 'core/config/firebase_config.dart';
import 'core/config/auth_link_config.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/session/app_session.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/telemetry_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  BuildEnvironment.validate(
    values: {
      'SUPABASE_URL': BackendConfig.supabaseUrl,
      'SUPABASE_PUBLISHABLE_KEY': BackendConfig.supabasePublishableKey,
      'MAPBOX_PUBLIC_TOKEN': MapboxConfig.publicToken,
      'FIREBASE_API_KEY': FirebaseConfig.apiKey,
      'FIREBASE_APP_ID': FirebaseConfig.appId,
      'FIREBASE_MESSAGING_SENDER_ID': FirebaseConfig.messagingSenderId,
      'FIREBASE_PROJECT_ID': FirebaseConfig.projectId,
      'AUTH_APP_LINK_HOST': AuthLinkConfig.host,
    },
  );
  // Each service is started on its own so one failure (a plugin that isn't
  // ready, no network) can't stop the app from drawing its first screen.
  // Android keeps showing the plain launch screen until that first frame.
  await Future.wait([
    _startService('dateFormats', () async {
      await initializeDateFormatting('en_PH');
      await initializeDateFormatting('fil_PH');
    }),
    _startService('backend', BackendConfig.initialize),
    _startService('notifications', PushNotificationService.initializeCore),
    _startService(
      'launchLogo',
      () => AppLogo.warmUp(BrandLogoHero.launchSize),
    ),
  ]);
  await Future.wait([
    _startService('session', AppSession.initialize),
    _startService('diagnostics', TelemetryService.initialize),
  ]);

  // The Mapbox native SDK initialization is not supported by Flutter web.
  // Calling it in a browser prevents runApp from ever rendering a first frame.
  if (!kIsWeb && MapboxConfig.publicToken.isNotEmpty) {
    MapboxOptions.setAccessToken(MapboxConfig.publicToken);
  }

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: TricGabayApp()));
}

Future<void> _startService(String name, Future<void> Function() start) async {
  try {
    await start();
  } catch (error, stack) {
    debugPrint('Startup: $name failed: $error');
    debugPrintStack(stackTrace: stack, maxFrames: 8);
  }
}

class TricGabayApp extends StatefulWidget {
  const TricGabayApp({super.key});

  @override
  State<TricGabayApp> createState() => _TricGabayAppState();
}

class _TricGabayAppState extends State<TricGabayApp>
    with WidgetsBindingObserver {
  bool _refreshing = false;
  late final ConnectivityMonitor _connectivity;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectivity = ConnectivityMonitor(onReconnect: AppSession.syncRemoteState)
      ..start();
    if (BackendConfig.isConfigured) {
      _authSubscription = BackendConfig.client.auth.onAuthStateChange.listen((
        state,
      ) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          appRouter.go(AppRoutes.resetPassword);
          return;
        }
        if (state.event == AuthChangeEvent.signedOut &&
            AppSession.authenticatedUserId != null) {
          unawaited(AppSession.handleSessionEnded());
        }
      });
    }
    // Notification details are children of the current signed-in context.
    // Pushing preserves a sensible Android Back destination instead of
    // replacing the entire navigation history.
    unawaited(PushNotificationService.activate(onOpenRoute: appRouter.push));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivity.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAfterResume();
    }
  }

  Future<void> _refreshAfterResume() async {
    if (_refreshing ||
        !BackendConfig.isConfigured ||
        AppSession.authenticatedUserId == null) {
      return;
    }
    _refreshing = true;
    try {
      await AppSession.syncRemoteState();
    } catch (_) {
      // syncRemoteState exposes a retryable, user-facing connectivity message.
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: LocaleController.revision,
      builder: (context, revision, _) {
        Intl.defaultLocale = LocaleController.effectiveLocale.toString();
        return MaterialApp.router(
          title: AppBrand.name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: LocaleController.overrideLocale,
          localeResolutionCallback: (device, supported) =>
              LocaleController.resolve(
                device ?? LocaleController.deviceLocale,
                choice: LocaleController.selection,
              ),
          supportedLocales: const [Locale('en'), Locale('fil')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: appRouter,
          onNavigationNotification: keepBackInFlutter,
          builder: (context, child) => ResponsiveAppFrame(
            child: ValueListenableBuilder<String?>(
              valueListenable: AppSession.storageError,
              builder: (context, error, _) => Column(
                children: [
                  OfflineBanner(
                    monitor: _connectivity,
                    retry: AppSession.syncRemoteState,
                  ),
                  if (error != null)
                    Material(
                      child: SafeArea(
                        bottom: false,
                        child: Semantics(
                          liveRegion: true,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Text(context.message(error)),
                                TextButton(
                                  onPressed: AppSession.initialize,
                                  child: Text(context.l10n.retryStorage),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: MinimumVersionGate(
                      child: PrivacyConsentGate(
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
