import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/backend_config.dart';
import 'image_upload_validator.dart';

/// Driver payee details shown to the tourist when a GCash fare is due.
class GcashPayee {
  const GcashPayee({
    required this.accountName,
    required this.number,
    required this.fareCents,
    this.qrPath,
  });

  final String accountName;
  final String number;
  final int fareCents;
  final String? qrPath;

  factory GcashPayee.fromRow(Map<String, dynamic> row) => GcashPayee(
    accountName: row['gcash_account_name'] as String,
    number: row['gcash_number'] as String,
    fareCents: (row['fare_centavos'] as num).toInt(),
    qrPath: row['qr_object_path'] as String?,
  );
}

enum GcashRuling { paid, notPaid, waived }

GcashRuling? parseGcashRuling(Object? value) => switch (value) {
  'paid' => GcashRuling.paid,
  'not_paid' => GcashRuling.notPaid,
  'waived' => GcashRuling.waived,
  _ => null,
};

/// One row of the admin dispute queue.
class GcashDispute {
  const GcashDispute({
    required this.bookingId,
    required this.referenceLabel,
    required this.touristName,
    required this.driverName,
    required this.fareCents,
    required this.disputedAt,
    required this.escalatedAt,
    required this.hasProof,
    required this.ruling,
  });

  final String bookingId;
  final String referenceLabel;
  final String touristName;
  final String driverName;
  final int fareCents;
  final DateTime? disputedAt;
  final DateTime? escalatedAt;
  final bool hasProof;
  final GcashRuling? ruling;

  bool get escalated => escalatedAt != null;
  bool get unsettledNotPaid => ruling == GcashRuling.notPaid;

  factory GcashDispute.fromRow(Map<String, dynamic> row) => GcashDispute(
    bookingId: row['booking_id'] as String,
    referenceLabel: (row['reference_label'] as String?) ?? '',
    touristName: (row['tourist_name'] as String?) ?? '',
    driverName: (row['driver_name'] as String?) ?? '',
    fareCents: (row['fare_centavos'] as num?)?.toInt() ?? 0,
    disputedAt: _time(row['disputed_at']),
    escalatedAt: _time(row['escalated_at']),
    hasProof: row['has_proof'] == true,
    ruling: parseGcashRuling(row['ruling']),
  );
}

/// Everything participants and admins may see about a disputed GCash fare.
class GcashDisputeDetail {
  const GcashDisputeDetail({
    required this.fareCents,
    this.referenceNo,
    this.receiptPath,
    this.disputedAt,
    this.disputeNote,
    this.proofSubmittedAt,
    this.escalatedAt,
    this.escalatedByRole,
    this.escalationNote,
    this.switchedToCashAt,
    this.ruling,
    this.rulingReason,
    this.settledAt,
  });

  final int fareCents;
  final String? referenceNo;
  final String? receiptPath;
  final DateTime? disputedAt;
  final String? disputeNote;
  final DateTime? proofSubmittedAt;
  final DateTime? escalatedAt;
  final String? escalatedByRole;
  final String? escalationNote;
  final DateTime? switchedToCashAt;
  final GcashRuling? ruling;
  final String? rulingReason;
  final DateTime? settledAt;

  bool get hasProof => receiptPath != null;
  bool get escalated => escalatedAt != null;

  factory GcashDisputeDetail.fromJson(Map<String, dynamic> json) =>
      GcashDisputeDetail(
        fareCents: (json['fare_centavos'] as num?)?.toInt() ?? 0,
        referenceNo: json['reference_no'] as String?,
        receiptPath: json['receipt_path'] as String?,
        disputedAt: _time(json['disputed_at']),
        disputeNote: json['dispute_note'] as String?,
        proofSubmittedAt: _time(json['proof_submitted_at']),
        escalatedAt: _time(json['escalated_at']),
        escalatedByRole: json['escalated_by_role'] as String?,
        escalationNote: json['escalation_note'] as String?,
        switchedToCashAt: _time(json['switched_to_cash_at']),
        ruling: parseGcashRuling(json['ruling']),
        rulingReason: json['ruling_reason'] as String?,
        settledAt: _time(json['settled_at']),
      );
}

DateTime? _time(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// Builds a storage path `{folder}/{uuid}.{jpg|png}` that matches the
/// server's path rules, after validating the image bytes.
({String path, String contentType}) gcashImageObject(
  String folder,
  Uint8List bytes, {
  String Function()? newId,
}) {
  final detected = ImageUploadValidator.validateProfileImage(bytes);
  final extension = detected == 'image/png' ? 'png' : 'jpg';
  final id = (newId ?? () => const Uuid().v4())();
  return (path: '$folder/$id.$extension', contentType: detected);
}

/// Wraps the GCash RPCs and private storage buckets.
class GcashRepository {
  GcashRepository._();

  static const receiptsBucket = 'gcash-receipts';
  static const qrBucket = 'driver-gcash-qr';

  static SupabaseClient get _client => BackendConfig.client;

  static Future<GcashPayee?> payee(String bookingId) async {
    final row = await _client
        .rpc('get_booking_gcash_payee', params: {'p_booking_id': bookingId})
        .maybeSingle();
    return row == null ? null : GcashPayee.fromRow(row);
  }

  static Future<String> signedUrl(String bucket, String path) =>
      _client.storage.from(bucket).createSignedUrl(path, 600);

  static Future<Uint8List> download(String bucket, String path) =>
      _client.storage.from(bucket).download(path);

  static Future<String> _upload(
    String bucket,
    String folder,
    Uint8List bytes,
  ) async {
    final object = gcashImageObject(folder, bytes);
    await _client.storage
        .from(bucket)
        .uploadBinary(
          object.path,
          bytes,
          fileOptions: FileOptions(
            contentType: object.contentType,
            upsert: false,
          ),
        );
    return object.path;
  }

  static Future<void> submitProof(
    String bookingId,
    String reference,
    Uint8List receipt,
  ) async {
    final path = await _upload(receiptsBucket, bookingId, receipt);
    await _client.rpc(
      'tourist_submit_gcash_proof',
      params: {
        'p_booking_id': bookingId,
        'p_reference_no': reference.trim(),
        'p_receipt_path': path,
      },
    );
  }

  static Future<void> requestAdminReview(String bookingId, {String? note}) =>
      _client.rpc(
        'request_gcash_admin_review',
        params: {'p_booking_id': bookingId, 'p_note': note},
      );

  static Future<void> rule(
    String bookingId,
    GcashRuling ruling,
    String reason,
  ) => _client.rpc(
    'admin_rule_gcash_dispute',
    params: {
      'p_booking_id': bookingId,
      'p_ruling': ruling == GcashRuling.paid ? 'paid' : 'not_paid',
      'p_reason': reason.trim(),
    },
  );

  static Future<void> waive(String bookingId, String reason) => _client.rpc(
    'admin_waive_unpaid_ruling',
    params: {'p_booking_id': bookingId, 'p_reason': reason.trim()},
  );

  static Future<List<GcashDispute>> listDisputes() async {
    final rows = await _client.rpc('list_gcash_disputes') as List<dynamic>;
    return rows
        .map((row) => GcashDispute.fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<GcashDisputeDetail> detail(String bookingId) async {
    final json = await _client.rpc(
      'get_gcash_dispute_detail',
      params: {'p_booking_id': bookingId},
    );
    return GcashDisputeDetail.fromJson(Map<String, dynamic>.from(json as Map));
  }

  static Future<String?> outstandingFareBookingId() async =>
      await _client.rpc('get_my_outstanding_fare') as String?;

  static Future<void> uploadDriverQr(Uint8List image) async {
    final userId = _client.auth.currentUser!.id;
    final path = await _upload(qrBucket, userId, image);
    await _client.rpc('set_driver_gcash_qr', params: {'p_object_path': path});
  }

  static Future<String?> driverQrPath() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('driver_gcash_details')
        .select('qr_object_path')
        .eq('driver_id', userId)
        .maybeSingle();
    return row?['qr_object_path'] as String?;
  }
}
