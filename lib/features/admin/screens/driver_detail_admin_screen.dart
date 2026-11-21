import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/session/app_session.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/l10n/record_labels.dart';

class DriverDetailAdminScreen extends ConsumerStatefulWidget {
  final String driverId;
  const DriverDetailAdminScreen({super.key, required this.driverId});

  @override
  ConsumerState<DriverDetailAdminScreen> createState() =>
      _DriverDetailAdminScreenState();
}

class _DriverDetailAdminScreenState
    extends ConsumerState<DriverDetailAdminScreen> {
  final _area = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _radius = TextEditingController();
  final _reviewNote = TextEditingController();
  DateTime? _licenseExpiry;
  DateTime? _franchiseExpiry;
  DateTime? _inspectionExpiry;
  String? _hydratedDriverId;
  bool _saving = false;
  bool _loadingGcash = false;

  Future<void> _showGcashDetails() async {
    if (_loadingGcash) return;
    setState(() => _loadingGcash = true);
    try {
      final details = await BackendRepository.driverGcashDetails(
        widget.driverId,
      );
      if (!mounted) return;
      final l10n = context.l10n;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.gcashDetails),
          content: details == null
              ? Text(l10n.gcashNotConfigured)
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.gcashAccountName),
                      SelectableText(details['gcash_account_name'] as String),
                      Text(l10n.gcashNumber),
                      SelectableText(details['gcash_number'] as String),
                      Text(
                        details['is_active'] == true
                            ? l10n.gcashActive
                            : l10n.gcashInactive,
                      ),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.gcashActionFailed)));
      }
    } finally {
      if (mounted) setState(() => _loadingGcash = false);
    }
  }

  @override
  void dispose() {
    _area.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _radius.dispose();
    _reviewNote.dispose();
    super.dispose();
  }

  DateTime? _date(dynamic value) => value == null || value.toString().isEmpty
      ? null
      : DateTime.tryParse(value.toString());

  void _hydrate(Map<String, dynamic> driver) {
    if (_hydratedDriverId == driver['id']) return;
    _hydratedDriverId = driver['id'] as String;
    _licenseExpiry = _date(driver['licenseExpiresOn']);
    _franchiseExpiry = _date(driver['franchiseExpiresOn']);
    _inspectionExpiry = _date(driver['vehicleInspectionExpiresOn']);
    _area.text = driver['serviceAreaName']?.toString() ?? 'Bustos, Bulacan';
    _latitude.text = '${driver['serviceAreaLatitude'] ?? 14.9571}';
    _longitude.text = '${driver['serviceAreaLongitude'] ?? 120.9188}';
    _radius.text = '${driver['serviceAreaRadiusKm'] ?? 15}';
    _reviewNote.text = driver['matchingBlockedReason']?.toString() ?? '';
  }

  Future<void> _pickDate(String field) async {
    final now = DateTime.now();
    final current = switch (field) {
      'license' => _licenseExpiry,
      'franchise' => _franchiseExpiry,
      _ => _inspectionExpiry,
    };
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (field == 'license') _licenseExpiry = picked;
      if (field == 'franchise') _franchiseExpiry = picked;
      if (field == 'inspection') _inspectionExpiry = picked;
    });
  }

  List<String> _issues(Map<String, dynamic> driver) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final issues = <String>[];
    if ((driver['licensePath'] ?? '').toString().isEmpty) {
      issues.add(MessageCode.driverLicenseDocumentIsMissing);
    }
    if ((driver['vehicleDocumentPath'] ?? '').toString().isEmpty) {
      issues.add(MessageCode.franchiseOrCrDocumentIsMissing);
    }
    for (final item in [
      (MessageCode.driverLicense, _licenseExpiry),
      (MessageCode.franchise, _franchiseExpiry),
      (MessageCode.vehicleInspection, _inspectionExpiry),
    ]) {
      if (item.$2 == null) {
        issues.add(MessageCode.expiryIsNotVerifiedValue((item.$1).toString()));
      } else if (item.$2!.isBefore(start)) {
        issues.add(MessageCode.isExpiredValue((item.$1).toString()));
      }
    }
    final completed = driver['completedTripCount'] as int? ?? 0;
    final cancelled = driver['driverCancelledTripCount'] as int? ?? 0;
    if (completed + cancelled >= 5 &&
        cancelled * 100 / (completed + cancelled) > 30) {
      issues.add(MessageCode.driverCancellationRateExceedsThe30MatchingLimit);
    }
    final blockedUntil = _date(driver['matchingBlockedUntil']);
    if (blockedUntil != null && blockedUntil.isAfter(DateTime.now())) {
      issues.add(
        driver['matchingBlockedReason']?.toString().trim().isNotEmpty == true
            ? driver['matchingBlockedReason'].toString()
            : MessageCode.matchingIsTemporarilyBlocked,
      );
    }
    return issues;
  }

  Future<void> _saveReview({required bool approve}) async {
    if (_saving) return;
    if (_reviewNote.text.trim().length < 5) {
      _message(
        MessageCode
            .enterTheReasonForApprovingOrRestoringServiceAtLeastFiveCharacters,
      );
      return;
    }
    final latitude = double.tryParse(_latitude.text.trim());
    final longitude = double.tryParse(_longitude.text.trim());
    final radius = double.tryParse(_radius.text.trim());
    if (_licenseExpiry == null ||
        _franchiseExpiry == null ||
        _inspectionExpiry == null ||
        latitude == null ||
        longitude == null ||
        radius == null ||
        _area.text.trim().length < 2) {
      _message(MessageCode.completeAllDocumentAndServiceAreaFields);
      return;
    }
    setState(() => _saving = true);
    try {
      await BackendRepository.reviewDriverCompliance(
        driverId: widget.driverId,
        licenseExpiresOn: _licenseExpiry!,
        franchiseExpiresOn: _franchiseExpiry!,
        vehicleInspectionExpiresOn: _inspectionExpiry!,
        serviceAreaName: _area.text.trim(),
        serviceAreaLatitude: latitude,
        serviceAreaLongitude: longitude,
        serviceAreaRadiusKm: radius,
        approve: approve,
        reviewNote: _reviewNote.text.trim(),
      );
      await AppSession.syncRemoteState();
      if (!mounted) return;
      _message(
        approve
            ? MessageCode.driverApprovedAndMatchingEnabled
            : MessageCode.complianceReviewSaved,
      );
      if (approve) context.pop();
    } catch (error) {
      if (mounted) _message(ErrorMessages.forError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setStatus(String status) async {
    final reason = await _reasonDialog(status);
    if (reason == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await BackendRepository.setDriverApproval(
        widget.driverId,
        status,
        reason: reason,
        blockedUntil: status == 'suspended'
            ? DateTime.now().add(const Duration(days: 30))
            : null,
      );
      await AppSession.syncRemoteState();
      if (!mounted) return;
      _message(
        status == 'rejected'
            ? MessageCode.applicationRejected
            : MessageCode.driverSuspendedFor30Days,
      );
      context.pop();
    } catch (error) {
      if (mounted) _message(ErrorMessages.forError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _reasonDialog(String status) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.message(
            status == 'rejected'
                ? MessageCode.rejectApplication
                : MessageCode.suspendDriver,
          ),
        ),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: context.l10n.reason,
            hintText: context.l10n.explainTheDecisionClearly,
          ),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          scrollPadding: const EdgeInsets.all(96),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.length >= 5) Navigator.pop(context, value);
            },
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.message(text)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: AppSession.adminDrivers,
      builder: (context, drivers, _) {
        final index = drivers.indexWhere((d) => d['id'] == widget.driverId);
        if (index == -1) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.driverCompliance)),
            body: Center(child: Text(context.l10n.driverNotFound)),
          );
        }
        final driver = drivers[index];
        _hydrate(driver);
        final issues = _issues(driver);
        final status = driver['status']?.toString() ?? 'pending';
        final reliability =
            (driver['reliabilityScore'] as num?)?.toDouble() ?? 100;
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.driverCompliance)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.message('${driver['name']}'),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          context.message(
                            '${driver['email'] ?? ''}\n${driver['phone'] ?? ''}',
                          ),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(status),
                ],
              ),
              const SizedBox(height: 20),
              if (BackendConfig.isConfigured)
                OutlinedButton(
                  onPressed: _loadingGcash ? null : _showGcashDetails,
                  child: Text(context.l10n.gcashDetails),
                ),
              _section(MessageCode.vehicleAndReliability, [
                _info(MessageCode.plateNumber, '${driver['plate'] ?? ''}'),
                _info(
                  MessageCode.franchiseNumber,
                  '${driver['franchise'] ?? ''}',
                ),
                _info(
                  MessageCode.safeCapacity,
                  MessageCode.passengersValue(
                    (driver['passengerCapacity'] ?? 3).toString(),
                  ),
                ),
                _info(
                  MessageCode.reliability,
                  '${reliability.toStringAsFixed(0)}%',
                ),
                _info(
                  MessageCode.completedTrips,
                  '${driver['completedTripCount'] ?? 0}',
                ),
                _info(
                  MessageCode.driverCancellations,
                  '${driver['driverCancelledTripCount'] ?? 0}',
                ),
              ]),
              const SizedBox(height: 16),
              _section(MessageCode.submittedDocuments, [
                Row(
                  children: [
                    Expanded(
                      child: _document(
                        MessageCode.driverLicense,
                        driver['licensePath'],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _document(
                        MessageCode.franchiseOrCr,
                        driver['vehicleDocumentPath'],
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              _section(MessageCode.expiryVerification, [
                _dateTile(
                  MessageCode.driverLicense,
                  _licenseExpiry,
                  () => _pickDate('license'),
                ),
                _dateTile(
                  MessageCode.franchiseOrCr,
                  _franchiseExpiry,
                  () => _pickDate('franchise'),
                ),
                _dateTile(
                  MessageCode.vehicleInspection,
                  _inspectionExpiry,
                  () => _pickDate('inspection'),
                ),
              ]),
              const SizedBox(height: 16),
              _section(MessageCode.approvedServiceArea, [
                AppTextField(
                  controller: _area,
                  label: context.l10n.areaName,
                  hint: context.l10n.bustosBulacan,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _latitude,
                        label: context.l10n.centerLatitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppTextField(
                        controller: _longitude,
                        label: context.l10n.centerLongitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _radius,
                  label: context.l10n.radius130Km,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _reviewNote,
                  label: context.l10n.reviewNote,
                  hint: context.l10n.explainAnythingTheDriverMustCorrect,
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: issues.isEmpty
                      ? AppColors.success.withValues(alpha: .09)
                      : AppColors.warning.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.message(
                        issues.isEmpty
                            ? MessageCode.readyForApproval
                            : MessageCode.matchingBlockers,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    if (issues.isEmpty)
                      Text(
                        context
                            .l10n
                            .documentsDatesServiceAreaAndReliabilityMeetTheMatchingRules,
                      )
                    else
                      ...issues.map(
                        (issue) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            context.l10n.bulletItem(
                              context.message((issue).toString()),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: context.l10n.approveAndEnableMatching,
                isLoading: _saving,
                onPressed: issues.isEmpty
                    ? () => _saveReview(approve: true)
                    : null,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: context.l10n.saveReviewWithoutApproval,
                type: AppButtonType.outline,
                onPressed: _saving ? null : () => _saveReview(approve: false),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _setStatus('rejected'),
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text(context.l10n.reject),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _setStatus('suspended'),
                      icon: const Icon(Icons.block_outlined),
                      label: Text(context.l10n.suspend),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 14),
      ],
    ),
    child: Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.message(title),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            context.message(label),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Flexible(
          child: Text(
            context.message(value),
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _statusChip(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: status == 'active'
          ? AppColors.success.withValues(alpha: .12)
          : AppColors.warning.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      accountStatusLabel(context, status),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: status == 'active' ? AppColors.success : AppColors.warning,
      ),
    ),
  );

  Widget _dateTile(
    String label,
    DateTime? date,
    VoidCallback onTap,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    onTap: onTap,
    leading: Icon(
      date == null ? Icons.event_busy_outlined : Icons.event_available_outlined,
      color: date == null ? AppColors.warning : AppColors.primary,
    ),
    title: Text(context.message(label)),
    subtitle: Text(
      context.message(
        date == null ? MessageCode.notVerified : AppFormatters.dateShort(date),
      ),
    ),
    trailing: const Icon(Icons.edit_calendar_outlined),
  );

  Widget _document(String label, String? path) => InkWell(
    onTap: path == null || path.isEmpty
        ? null
        : () async {
            final url = await BackendRepository.createDriverDocumentUrl(path);
            if (!await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ) &&
                mounted) {
              _message(MessageCode.couldNotOpenThisDocument);
            }
          },
    borderRadius: BorderRadius.circular(14),
    child: Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            path == null || path.isEmpty
                ? Icons.file_upload_outlined
                : Icons.verified_user_outlined,
            color: path == null || path.isEmpty
                ? AppColors.warning
                : AppColors.success,
          ),
          const SizedBox(height: 8),
          Text(
            context.message(
              path == null || path.isEmpty
                  ? MessageCode.missingValue((label).toString())
                  : MessageCode.viewValue((label).toString()),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}
