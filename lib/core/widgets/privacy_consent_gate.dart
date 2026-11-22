import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'brand_logo_hero.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/backend_config.dart';
import '../session/app_session.dart';
import '../services/privacy_service.dart';
import '../services/error_messages.dart';
import '../services/telemetry_service.dart';
import 'retained_gate.dart';
import 'privacy_notice_view.dart';

class PrivacyConsentGate extends StatefulWidget {
  final Widget child;
  final Future<PrivacyState?> Function()? loader;
  final Future<void> Function(String)? record;
  const PrivacyConsentGate({
    super.key,
    required this.child,
    this.loader,
    this.record,
  });
  @override
  State<PrivacyConsentGate> createState() => _PrivacyConsentGateState();
}

class _PrivacyConsentGateState extends State<PrivacyConsentGate>
    with WidgetsBindingObserver {
  late Future<PrivacyState?> _future;
  bool _checked = false, _telemetry = false, _saving = false;
  String? _checkedVersion;
  String? _error;
  int _accountEpoch = 0;
  String? _authUserId;
  StreamSubscription<AuthState>? _auth;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppSession.authRevision.addListener(_authChanged);
    _refresh();
    if (BackendConfig.isConfigured) {
      _authUserId = BackendConfig.client.auth.currentUser?.id;
      _auth = BackendConfig.client.auth.onAuthStateChange.listen((state) {
        final userId = state.session?.user.id;
        if (userId != _authUserId) {
          _authUserId = userId;
          _authChanged();
        } else if (mounted) {
          setState(_refresh);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppSession.authRevision.removeListener(_authChanged);
    _auth?.cancel();
    super.dispose();
  }

  void _authChanged() {
    // A different account must see its own privacy check, not the last one.
    _loadedOnce = false;
    _accountEpoch++;
    _checked = false;
    _checkedVersion = null;
    _telemetry = false;
    _saving = false;
    _error = null;
    if (mounted) setState(_refresh);
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

  Future<PrivacyState?> _load() async {
    if (!BackendConfig.isConfigured ||
        BackendConfig.client.auth.currentUser == null) {
      return null;
    }
    return PrivacyService.status();
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

  Future<void> _accept(PrivacyNotice notice) async {
    if (!_checked || _checkedVersion != notice.version || _saving) return;
    final language = Localizations.localeOf(context).languageCode;
    final epoch = _accountEpoch;
    final telemetry = _telemetry;
    setState(() => _saving = true);
    try {
      if (widget.record != null) {
        await widget.record!(notice.version);
      } else {
        await PrivacyService.accept(notice.version, language: language);
      }
      if (!mounted || epoch != _accountEpoch) return;
      await TelemetryService.setConsent(telemetry);
      if (!mounted || epoch != _accountEpoch) return;
      if (mounted && epoch == _accountEpoch) {
        setState(() {
          _error = null;
          _refresh();
        });
      }
    } catch (error) {
      if (mounted && epoch == _accountEpoch) {
        setState(() => _error = ErrorMessages.forError(error));
      }
    } finally {
      if (mounted && epoch == _accountEpoch) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PrivacyState?>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done && !_loadedOnce) {
        return RetainedGate(
          barrier: LaunchBarrier(
            semanticsLabel: context.l10n.privacyLoadingLabel,
          ),
          child: widget.child,
        );
      }
      if (!snapshot.hasError &&
          (snapshot.data == null || snapshot.data!.accepted)) {
        return RetainedGate(child: widget.child);
      }
      final notice = snapshot.data?.notice;
      final checked = _checked && _checkedVersion == notice?.version;
      return RetainedGate(
        barrier: PrivacyNoticeView(
          notice: notice,
          checked: checked,
          telemetry: _telemetry,
          saving: _saving,
          error: _error == null ? null : context.message(_error!),
          onChecked: (value) => setState(() {
            _checked = value;
            _checkedVersion = notice?.version;
          }),
          onTelemetry: (value) => setState(() => _telemetry = value),
          onAccept: () => _accept(notice!),
          onRetry: () => setState(() {
            _error = null;
            _refresh();
          }),
          onSignOut: BackendConfig.isConfigured ? AppSession.signOut : null,
        ),
        child: widget.child,
      );
    },
  );
}
