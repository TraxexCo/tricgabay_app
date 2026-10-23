import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/mapbox_config.dart';
import 'core/config/backend_config.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/prototype/prototype_session.dart';
import 'core/services/auth_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/telemetry_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackendConfig.initialize();
  await PushNotificationService.initializeCore();
  await TelemetryService.initialize();
  await PrototypeSession.initialize();
  if (BackendConfig.isConfigured) {
    try {
      final profile = await AuthService.restoreSession();
      if (profile != null && profile.status == 'active') {
        PrototypeSession.setAuthenticatedUser(
          id: profile.id,
          name: profile.name,
          role: profile.role.name,
          email: profile.email,
          plateNumber: profile.plateNumber,
        );
        await PrototypeSession.syncRemoteState();
      }
    } catch (error) {
      PrototypeSession.storageError.value =
          'The server could not be reached. Saved authentication remains available; retry when connected. ($error)';
    }
  }

  // The Mapbox native SDK initialization is not supported by Flutter web.
  // Calling it in a browser prevents runApp from ever rendering a first frame.
  if (!kIsWeb) {
    MapboxOptions.setAccessToken(MapboxConfig.publicToken);
  }

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: TricGabayApp()));
}

class TricGabayApp extends StatefulWidget {
  const TricGabayApp({super.key});

  @override
  State<TricGabayApp> createState() => _TricGabayAppState();
}

class _TricGabayAppState extends State<TricGabayApp>
    with WidgetsBindingObserver {
  bool _refreshing = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (BackendConfig.isConfigured) {
      _authSubscription = BackendConfig.client.auth.onAuthStateChange.listen((
        state,
      ) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          appRouter.go(AppRoutes.resetPassword);
          return;
        }
        if (state.event == AuthChangeEvent.signedOut &&
            PrototypeSession.authenticatedUserId != null) {
          unawaited(PrototypeSession.handleSessionEnded());
        }
      });
    }
    unawaited(PushNotificationService.activate(onOpenRoute: appRouter.go));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        PrototypeSession.authenticatedUserId == null) {
      return;
    }
    _refreshing = true;
    try {
      await PrototypeSession.syncRemoteState();
    } catch (_) {
      // syncRemoteState exposes a retryable, user-facing connectivity message.
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PrototypeSession.isFilipino,
      builder: (context, isFilipino, _) => MaterialApp.router(
        title: 'Tric Gabay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: Locale(isFilipino ? 'fil' : 'en'),
        supportedLocales: const [Locale('en'), Locale('fil')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: appRouter,
        builder: (context, child) => ValueListenableBuilder<String?>(
          valueListenable: PrototypeSession.storageError,
          builder: (context, error, _) => Column(
            children: [
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
                            Text(error),
                            TextButton(
                              onPressed: PrototypeSession.initialize,
                              child: Text(
                                isFilipino
                                    ? 'Subukan muli ang storage'
                                    : 'Retry storage',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
