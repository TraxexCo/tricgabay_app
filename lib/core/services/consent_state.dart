import 'dart:async';

import 'package:flutter/foundation.dart';

/// True while the privacy notice is covering the app. Screens underneath stay
/// mounted, so anything that would show a system permission prompt waits here
/// until the notice has been accepted.
class ConsentState {
  ConsentState._();

  static final blocked = ValueNotifier<bool>(false);

  /// Completes immediately when no notice is showing, otherwise as soon as it
  /// has been accepted (or the account signed out of the gate).
  static Future<void> whenClear() {
    if (!blocked.value) return Future.value();
    final done = Completer<void>();
    void listener() {
      if (!blocked.value && !done.isCompleted) {
        blocked.removeListener(listener);
        done.complete();
      }
    }

    blocked.addListener(listener);
    return done.future;
  }
}
