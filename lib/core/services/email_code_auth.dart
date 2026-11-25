import 'auth_service.dart';

/// The emailed-code steps the sign-up and password-reset screens need.
///
/// Screens take this instead of calling [AuthService] directly so tests can
/// supply a fake. The default talks to Supabase Auth.
abstract class EmailCodeAuth {
  const EmailCodeAuth();

  /// Confirms a new account with the 6-digit [code]. Signs the user in.
  Future<void> verifySignUpCode(String email, String code);

  /// Emails a fresh sign-up code.
  Future<void> resendSignUpCode(String email);

  /// Emails a password-reset code. Succeeds whether or not the email has an
  /// account, so the caller cannot learn which emails are registered.
  Future<void> requestPasswordResetCode(String email);

  /// Checks the reset [code]. On success the app holds a short recovery session.
  Future<void> verifyRecoveryCode(String email, String code);

  /// Sets the new password in the recovery session, then signs out.
  Future<void> updateRecoveredPassword(String password);
}

/// [EmailCodeAuth] backed by [AuthService].
class AuthServiceEmailCodes extends EmailCodeAuth {
  const AuthServiceEmailCodes();

  @override
  Future<void> verifySignUpCode(String email, String code) =>
      AuthService.verifySignUpCode(email: email, code: code);

  @override
  Future<void> resendSignUpCode(String email) =>
      AuthService.resendSignUpCode(email);

  @override
  Future<void> requestPasswordResetCode(String email) =>
      AuthService.requestPasswordResetCode(email);

  @override
  Future<void> verifyRecoveryCode(String email, String code) =>
      AuthService.verifyRecoveryCode(email: email, code: code);

  @override
  Future<void> updateRecoveredPassword(String password) =>
      AuthService.updateRecoveredPassword(password);
}
