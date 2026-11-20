import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityMonitor extends ChangeNotifier {
  final Future<List<ConnectivityResult>> Function() check;
  final Stream<List<ConnectivityResult>> changes;
  final Future<void> Function()? onReconnect;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool? online;
  bool _disposed = false;
  ConnectivityMonitor({
    Future<List<ConnectivityResult>> Function()? check,
    Stream<List<ConnectivityResult>>? changes,
    this.onReconnect,
  }) : check = check ?? Connectivity().checkConnectivity,
       changes = changes ?? Connectivity().onConnectivityChanged;
  void start() {
    _subscription = changes.listen(_accept, onError: (Object _) {});
    unawaited(refresh());
  }

  Future<void> refresh() async {
    try {
      _accept(await check());
    } catch (_) {
      /* Interface state is unknown; server errors remain visible separately. */
    }
  }

  void _accept(List<ConnectivityResult> values) {
    if (_disposed) return;
    final previous = online;
    online = values.any((value) => value != ConnectivityResult.none);
    notifyListeners();
    if (previous == false && online == true && onReconnect != null) {
      unawaited(onReconnect!().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
