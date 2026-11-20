import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'privacy_service.dart';
import 'image_upload_validator.dart';
import '../config/auth_link_config.dart';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/backend_config.dart';
import 'auth_session_policy.dart';
import '../utils/validators.dart';

enum AppRole { tourist, driver, admin }

enum DriverRegistrationOutcome { awaitingEmailConfirmation, submitted }

class SignedInProfile {
  final String id;
  final String name;
  final String email;
  final AppRole role;
  final String status;
  final String? plateNumber;
  final bool applicationPending;

  const SignedInProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.plateNumber,
    this.applicationPending = false,
  });
}

class AuthService {
  AuthService._();

  static SupabaseClient get _client => BackendConfig.client;

  static Future<SignedInProfile?> restoreSession() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final profile = await _client
        .from('profiles')
        .select('id,full_name,role,status')
        .eq('id', user.id)
        .single()
        .timeout(const Duration(seconds: 8));
    if (_client.auth.currentUser?.id != user.id) return null;
    final roleName = profile['role'] as String;
    final role = AppRole.values
        .where((value) => value.name == roleName)
        .firstOrNull;
    final status = profile['status'] as String;
    String? plate;
    String? driverApproval;
    if (roleName == AppRole.driver.name) {
      final driver = await _client
          .from('driver_profiles')
          .select('plate_number,approval_status')
          .eq('profile_id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));
      if (_client.auth.currentUser?.id != user.id) return null;
      driverApproval = driver?['approval_status'] as String?;
      plate = driver?['plate_number'] as String?;
    }
    final decision = evaluateAuthAccess(
      role: roleName,
      status: status,
      driverApproval: driverApproval,
    );
    if (!decision.allowed || role == null) {
      await _client.auth.signOut();
      return null;
    }
    return SignedInProfile(
      id: user.id,
      name: profile['full_name'],
      email: user.email ?? '',
      role: role,
      status: status,
      plateNumber: plate,
      applicationPending: decision.applicationPending,
    );
  }

  static Future<SignedInProfile> signIn({
    required String email,
    required String password,
    required AppRole expectedRole,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException(MessageCode.signInDidNotComplete);
    }
    try {
      final profile = await _client
          .from('profiles')
          .select('id, full_name, role, status')
          .eq('id', user.id)
          .single();
      final roleName = profile['role'] as String;
      final role = AppRole.values
          .where((value) => value.name == roleName)
          .firstOrNull;
      final status = profile['status'] as String;
      String? plateNumber;
      String? driverApproval;
      if (roleName == AppRole.driver.name) {
        final driver = await _client
            .from('driver_profiles')
            .select('plate_number, approval_status')
            .eq('profile_id', user.id)
            .maybeSingle();
        driverApproval = driver?['approval_status'] as String?;
        plateNumber = driver?['plate_number'] as String?;
      }
      final decision = evaluateAuthAccess(
        role: roleName,
        status: status,
        expectedRole: expectedRole.name,
        driverApproval: driverApproval,
      );
      if (!decision.allowed || role == null) {
        await _client.auth.signOut();
        throw AuthException(
          decision.message ?? MessageCode.thisAccountCannotSignIn,
        );
      }
      return SignedInProfile(
        id: user.id,
        name: profile['full_name'] as String,
        email: user.email ?? email.trim(),
        role: role,
        status: status,
        plateNumber: plateNumber,
        applicationPending: decision.applicationPending,
      );
    } catch (_) {
      if (_client.auth.currentUser != null) await _client.auth.signOut();
      rethrow;
    }
  }

  static Future<void> registerTourist({
    required String privacyVersion,
    required String privacyLanguage,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (privacyVersion.trim().isEmpty) {
      throw const AuthException(MessageCode.privacyNoticeAcceptanceIsRequired);
    }
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': name.trim(),
        'phone': Validators.normalizePhone(phone),
        'privacy_notice_version': privacyVersion,
        'privacy_notice_language': privacyLanguage,
        'requested_role': AppRole.tourist.name,
      },
    );
  }

  static Future<DriverRegistrationOutcome> registerDriver({
    required String privacyVersion,
    required String privacyLanguage,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String plateNumber,
    required String franchiseNumber,
    required DateTime licenseExpiresOn,
    required DateTime franchiseExpiresOn,
    required int passengerCapacity,
    required bool acceptsAccessibilityRequests,
    required Uint8List licenseBytes,
    required Uint8List vehicleRegistrationBytes,
  }) async {
    if (privacyVersion.trim().isEmpty) {
      throw const AuthException(MessageCode.privacyNoticeAcceptanceIsRequired);
    }
    const maxDocumentBytes = 5 * 1024 * 1024;
    if (licenseBytes.isEmpty || vehicleRegistrationBytes.isEmpty) {
      throw const AuthException(MessageCode.bothDriverDocumentsAreRequired);
    }
    if (licenseBytes.length > maxDocumentBytes ||
        vehicleRegistrationBytes.length > maxDocumentBytes) {
      throw const AuthException(
        MessageCode.eachDriverDocumentMustBe5MbOrSmaller,
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    AuthResponse? response;
    final existing = _client.auth.currentUser;
    if (existing != null && existing.email?.toLowerCase() != normalizedEmail) {
      throw const AuthException(
        MessageCode
            .anotherAccountIsAlreadySignedInSignOutBeforeRegisteringADriver,
      );
    }
    if (existing == null) {
      try {
        // A correct password resumes an application interrupted after account
        // creation or during either document upload.
        response = await _client.auth.signInWithPassword(
          email: normalizedEmail,
          password: password,
        );
      } on AuthException catch (error) {
        if (error.code == 'email_not_confirmed') {
          return DriverRegistrationOutcome.awaitingEmailConfirmation;
        }
        response = await _client.auth.signUp(
          email: normalizedEmail,
          password: password,
          data: {
            'full_name': name.trim(),
            'phone': Validators.normalizePhone(phone),
            'requested_role': AppRole.driver.name,
            'privacy_notice_version': privacyVersion,
            'privacy_notice_language': privacyLanguage,
          },
        );
      }
    }
    final user = response?.user;
    final authenticatedUser = user ?? existing;
    if (authenticatedUser == null) {
      throw const AuthException(MessageCode.registrationDidNotComplete);
    }
    if (_client.auth.currentSession == null) {
      return DriverRegistrationOutcome.awaitingEmailConfirmation;
    }
    final consent = await PrivacyService.status();
    if (!consent.accepted) {
      await PrivacyService.accept(privacyVersion, language: privacyLanguage);
    }
    await submitPendingApplication(
      privacyVersion: privacyVersion,
      plateNumber: plateNumber,
      franchiseNumber: franchiseNumber,
      licenseExpiresOn: licenseExpiresOn,
      franchiseExpiresOn: franchiseExpiresOn,
      passengerCapacity: passengerCapacity,
      acceptsAccessibilityRequests: acceptsAccessibilityRequests,
      licenseBytes: licenseBytes,
      vehicleRegistrationBytes: vehicleRegistrationBytes,
    );
    return DriverRegistrationOutcome.submitted;
  }

  static Future<void> submitPendingApplication({
    required String privacyVersion,
    required String plateNumber,
    required String franchiseNumber,
    required DateTime licenseExpiresOn,
    required DateTime franchiseExpiresOn,
    required int passengerCapacity,
    required bool acceptsAccessibilityRequests,
    required Uint8List licenseBytes,
    required Uint8List vehicleRegistrationBytes,
  }) async {
    final authenticatedUser = _client.auth.currentUser;
    if (authenticatedUser == null) {
      throw const AuthException(MessageCode.signInAfterConfirmingYourEmail);
    }
    if (licenseBytes.isEmpty ||
        vehicleRegistrationBytes.isEmpty ||
        licenseBytes.length > 5 * 1024 * 1024 ||
        vehicleRegistrationBytes.length > 5 * 1024 * 1024) {
      throw const AuthException(
        MessageCode.bothDriverDocumentsMustBeValidImagesUnder5Mb,
      );
    }
    final profile = await _client
        .from('profiles')
        .select('role,status')
        .eq('id', authenticatedUser.id)
        .single();
    if (profile['role'] != AppRole.driver.name ||
        profile['status'] != 'pending') {
      await _client.auth.signOut();
      throw const AuthException(
        MessageCode.onlyAPendingDriverApplicationCanBeResumedFromThisForm,
      );
    }

    final consent = await PrivacyService.status();
    if (!consent.accepted || consent.notice.version != privacyVersion) {
      throw const AuthException(
        MessageCode.acceptTheCurrentPrivacyNoticeBeforeSubmitting,
      );
    }
    ImageUploadValidator.validateForObject(
      licenseBytes,
      path: 'license.jpg',
      contentType: 'image/jpeg',
      jpegOnly: true,
    );
    ImageUploadValidator.validateForObject(
      vehicleRegistrationBytes,
      path: 'vehicle-registration.jpg',
      contentType: 'image/jpeg',
      jpegOnly: true,
    );
    final prefix = authenticatedUser.id;
    final licensePath = '$prefix/license.jpg';
    final registrationPath = '$prefix/vehicle-registration.jpg';
    await _client.storage
        .from('driver-documents')
        .uploadBinary(
          licensePath,
          licenseBytes,
          fileOptions: const FileOptions(
            upsert: true,
            cacheControl: '0',
            contentType: 'image/jpeg',
          ),
        );
    await _client.storage
        .from('driver-documents')
        .uploadBinary(
          registrationPath,
          vehicleRegistrationBytes,
          fileOptions: const FileOptions(
            upsert: true,
            cacheControl: '0',
            contentType: 'image/jpeg',
          ),
        );
    await _client.rpc(
      'submit_driver_application',
      params: {
        'p_plate_number': plateNumber.trim(),
        'p_franchise_number': franchiseNumber.trim(),
        'p_license_expires_on': _dateOnly(licenseExpiresOn),
        'p_franchise_expires_on': _dateOnly(franchiseExpiresOn),
        'p_passenger_capacity': passengerCapacity,
        'p_accepts_accessibility_requests': acceptsAccessibilityRequests,
        'p_license_document_path': licensePath,
        'p_vehicle_document_path': registrationPath,
      },
    );
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AuthLinkConfig.resetUri().toString(),
      );

  static Future<void> updateRecoveredPassword(String password) async {
    final decision = evaluatePasswordRecoverySession(
      _client.auth.currentSession != null,
    );
    if (!decision.allowed) {
      throw AuthException(decision.message!);
    }
    await _client.auth.updateUser(UserAttributes(password: password));
    await _client.auth.signOut();
  }

  static Future<void> signOut() => _client.auth.signOut();
}
