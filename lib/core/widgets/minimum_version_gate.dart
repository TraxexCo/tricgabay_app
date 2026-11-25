import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'brand_logo_hero.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/backend_config.dart';
import '../services/server_clock.dart';
import '../services/error_messages.dart';
import 'retained_gate.dart';

class VersionPolicy {
  final int minimumBuild;
  final String updateUrl;
  const VersionPolicy(this.minimumBuild, this.updateUrl);
  bool blocks(int currentBuild) => currentBuild < minimumBuild;
  Uri? get storeUri {
    final uri = Uri.tryParse(updateUrl);
    return uri?.scheme == 'https' &&
            uri?.host == 'play.google.com' &&
            uri!.path == '/store/apps/details' &&
            uri.queryParameters['id']?.isNotEmpty == true
        ? uri
        : null;
  }
}

class MinimumVersionGate extends StatefulWidget {
  final Widget child;
  final Future<({VersionPolicy policy, int build})> Function()? loader;
  const MinimumVersionGate({super.key, required this.child, this.loader});
  @override
  State<MinimumVersionGate> createState() => _MinimumVersionGateState();
}

class _MinimumVersionGateState extends State<MinimumVersionGate>
    with WidgetsBindingObserver {
  Future<({VersionPolicy policy, int build})>? _future;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// True once the first check has finished. Later checks (on returning to
  /// the app) run quietly behind the screen instead of covering it with
  /// the launch logo.
  bool _loadedOnce = false;
  DateTime? _lastCheck;

  void _refresh() {
    _lastCheck = DateTime.now();
    _future = (widget.loader ?? _load)().whenComplete(() => _loadedOnce = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pulling down the notification shade or switching apps briefly must
    // not re-check every time: at most every 10 minutes.
    final last = _lastCheck;
    if (state == AppLifecycleState.resumed &&
        mounted &&
        (last == null ||
            DateTime.now().difference(last) > const Duration(minutes: 10))) {
      setState(_refresh);
    }
  }

  Future<({VersionPolicy policy, int build})> _load() async {
    if (!BackendConfig.isConfigured ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return (policy: const VersionPolicy(1, ''), build: 1);
    }
    final info = await PackageInfo.fromPlatform();
    final build = int.tryParse(info.buildNumber);
    if (build == null) throw StateError(MessageCode.invalidAppBuild);
    final prefs = await SharedPreferences.getInstance();
    try {
      final timer = Stopwatch()..start();
      final result = await BackendConfig.client
          .rpc('get_client_configuration')
          .timeout(const Duration(seconds: 10));
      ServerClock.synchronize(
        DateTime.parse(result['server_time'] as String),
        roundTrip: timer.elapsed,
      );
      final minimum = (result['minimum_android_build'] as num).toInt();
      final url = result['update_url'] as String;
      await prefs.setInt('minimum_android_build', minimum);
      await prefs.setString('minimum_update_url', url);
      return (policy: VersionPolicy(minimum, url), build: build);
    } catch (error) {
      ErrorMessages.forError(error);
      final minimum = prefs.getInt('minimum_android_build');
      if (minimum == null) rethrow;
      return (
        policy: VersionPolicy(
          minimum,
          prefs.getString('minimum_update_url') ?? '',
        ),
        build: build,
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<({VersionPolicy policy, int build})>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done && !_loadedOnce) {
        return RetainedGate(
          barrier: const LaunchBarrier(),
          child: widget.child,
        );
      }
      final result = snapshot.data;
      if (result != null && !result.policy.blocks(result.build)) {
        return RetainedGate(child: widget.child);
      }
      final uri = result?.policy.storeUri;
      return RetainedGate(
        barrier: Material(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.message(
                        result == null
                            ? MessageCode.unableToCheckAppRequirements
                            : MessageCode.updateRequired,
                      ),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.message(
                        result == null
                            ? MessageCode.connectToTheInternetAndRetry
                            : MessageCode
                                  .updateAppBeforeContinuingToUseBookingAndPaymentServices,
                      ),
                    ),
                    if (uri != null)
                      FilledButton(
                        onPressed: () async {
                          try {
                            if (!await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            )) {
                              throw StateError(MessageCode.storeUnavailable);
                            }
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.message(
                                      ErrorMessages.forError(error),
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(context.l10n.openAppStore),
                      ),
                    TextButton(
                      onPressed: () => setState(_refresh),
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        child: widget.child,
      );
    },
  );
}
