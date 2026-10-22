import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/backend_config.dart';

enum AppRole { tourist, driver, admin }

class SignedInProfile {
  final String id;
  final String name;
  final String email;
  final AppRole role;
  final String status;
  final String? plateNumber;

  const SignedInProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.plateNumber,
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
        .single();
    final role = AppRole.values.byName(profile['role'] as String);
    String? plate;
    if (role == AppRole.driver) {
      final driver = await _client
          .from('driver_profiles')
          .select('plate_number')
          .eq('profile_id', user.id)
          .maybeSingle();
      plate = driver?['plate_number'] as String?;
    }
    return SignedInProfile(
      id: user.id,
      name: profile['full_name'],
      email: user.email ?? '',
      role: role,
      status: profile['status'],
      plateNumber: plate,
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
    if (user == null) throw const AuthException('Sign-in did not complete.');
    try {
      final profile = await _client
          .from('profiles')
          .select('id, full_name, role, status')
          .eq('id', user.id)
          .single();
      final role = AppRole.values.byName(profile['role'] as String);
      if (role != expectedRole) {
        await _client.auth.signOut();
        throw AuthException('This account belongs to the ${role.name} portal.');
      }
      final status = profile['status'] as String;
      if (status != 'active') {
        await _client.auth.signOut();
        throw AuthException(
          status == 'pending'
              ? 'This account is still awaiting administrator approval.'
              : 'This account is not currently allowed to sign in.',
        );
      }
      String? plateNumber;
      if (role == AppRole.driver) {
        final driver = await _client
            .from('driver_profiles')
            .select('plate_number, approval_status')
            .eq('profile_id', user.id)
            .single();
        if (driver['approval_status'] != 'approved') {
          await _client.auth.signOut();
          throw const AuthException(
            'This driver account is still awaiting administrator approval.',
          );
        }
        plateNumber = driver['plate_number'] as String?;
      }
      return SignedInProfile(
        id: user.id,
        name: profile['full_name'] as String,
        email: user.email ?? email.trim(),
        role: role,
        status: status,
        plateNumber: plateNumber,
      );
    } catch (_) {
      if (_client.auth.currentUser != null) await _client.auth.signOut();
      rethrow;
    }
  }

  static Future<void> registerTourist({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': name.trim(),
        'phone': phone.trim(),
        'requested_role': AppRole.tourist.name,
      },
    );
  }

  static Future<void> registerDriver({
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
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': name.trim(),
        'phone': phone.trim(),
        'requested_role': AppRole.driver.name,
      },
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Registration did not complete.');
    }
    if (response.session == null) {
      throw const AuthException(
        'Driver document upload needs an authenticated registration session. '
        'For this closed test environment, disable mandatory email confirmation '
        'in Supabase Auth, remove this incomplete test account, and register again.',
      );
    }

    final prefix = user.id;
    final licensePath =
        '$prefix/license-${DateTime.now().microsecondsSinceEpoch}.jpg';
    final registrationPath =
        '$prefix/vehicle-${DateTime.now().microsecondsSinceEpoch}.jpg';
    await _client.storage
        .from('driver-documents')
        .uploadBinary(
          licensePath,
          licenseBytes,
          fileOptions: const FileOptions(upsert: false),
        );
    await _client.storage
        .from('driver-documents')
        .uploadBinary(
          registrationPath,
          vehicleRegistrationBytes,
          fileOptions: const FileOptions(upsert: false),
        );
    await _client.from('driver_profiles').upsert({
      'profile_id': user.id,
      'plate_number': plateNumber.trim().toUpperCase(),
      'franchise_number': franchiseNumber.trim(),
      'license_expires_on': _dateOnly(licenseExpiresOn),
      'franchise_expires_on': _dateOnly(franchiseExpiresOn),
      'passenger_capacity': passengerCapacity,
      'accepts_accessibility_requests': acceptsAccessibilityRequests,
      'license_document_path': licensePath,
      'vehicle_document_path': registrationPath,
      'approval_status': 'pending',
    });
    await _client.auth.signOut();
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());

  static Future<void> signOut() => _client.auth.signOut();
}
