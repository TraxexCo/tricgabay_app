import 'package:tricgabay_app/core/l10n/message_codes.g.dart';

class AuthAccessDecision {
  final bool allowed;
  final String? message;
  final bool applicationPending;

  const AuthAccessDecision._(
    this.allowed,
    this.message,
    this.applicationPending,
  );
  const AuthAccessDecision.allow() : this._(true, null, false);
  const AuthAccessDecision.pending() : this._(true, null, true);
  const AuthAccessDecision.deny(String message) : this._(false, message, false);
}

/// Pure authorization boundary shared by session restore and interactive
/// sign-in. The identity provider proves identity; this policy decides whether
/// that identity may enter the requested Tric-Gabay portal.
AuthAccessDecision evaluateAuthAccess({
  required String role,
  required String status,
  String? expectedRole,
  String? driverApproval,
}) {
  if (!const {'tourist', 'driver', 'admin'}.contains(role)) {
    return const AuthAccessDecision.deny(
      MessageCode.thisAccountHasAnInvalidRole,
    );
  }
  if (expectedRole != null && role != expectedRole) {
    return AuthAccessDecision.deny(
      MessageCode.thisAccountBelongsToThePortalValue(switch (role) {
        'tourist' => MessageCode.tourist,
        'driver' => MessageCode.driver,
        _ => MessageCode.administrator,
      }),
    );
  }
  if (role == 'driver' &&
      const {'active', 'pending'}.contains(status) &&
      (driverApproval == null ||
          driverApproval == 'pending' ||
          (status == 'pending' && driverApproval == 'approved'))) {
    return const AuthAccessDecision.pending();
  }
  if (status != 'active') {
    return AuthAccessDecision.deny(
      status == 'pending'
          ? MessageCode.thisAccountIsStillAwaitingAdministratorApproval
          : MessageCode.thisAccountIsNotCurrentlyAllowedToSignIn,
    );
  }
  if (role == 'driver' && driverApproval != 'approved') {
    return const AuthAccessDecision.deny(
      MessageCode.thisDriverAccountIsStillAwaitingAdministratorApproval,
    );
  }
  return const AuthAccessDecision.allow();
}

AuthAccessDecision evaluatePasswordRecoverySession(bool hasSession) =>
    hasSession
    ? const AuthAccessDecision.allow()
    : const AuthAccessDecision.deny(
        MessageCode.thisPasswordResetLinkIsInvalidOrExpiredRequestANewOne,
      );
