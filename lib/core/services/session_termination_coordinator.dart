typedef SessionCleanup = Future<void> Function();

/// Clears all protected local state before attempting remote sign-out. A
/// provider outage must never leave the previous account visible or reusable.
class SessionTerminationCoordinator {
  final SessionCleanup clearLocal;
  final SessionCleanup remoteSignOut;
  final SessionCleanup? disconnect;

  const SessionTerminationCoordinator({
    required this.clearLocal,
    required this.remoteSignOut,
    this.disconnect,
  });

  Future<void> terminate() async {
    try {
      await clearLocal();
    } catch (_) {
      // A local cache erasure failure must not skip provider revocation.
      // The caller removes in-memory access before awaiting cache I/O.
    }
    // Start both while the departing session still owns its registrations.
    // Neither cleanup can stop the UI from clearing or prevent the other call.
    Future<void> attempt(SessionCleanup action) async {
      try {
        await action();
      } catch (_) {
        // Protected local state has already been removed.
      }
    }

    await Future.wait([
      if (disconnect != null) attempt(disconnect!),
      attempt(remoteSignOut),
    ]);
  }
}
