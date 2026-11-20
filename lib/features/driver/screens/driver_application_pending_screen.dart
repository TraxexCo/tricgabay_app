import '../../../core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/privacy_service.dart';
import '../../../core/services/error_messages.dart';
import '../../../core/services/trip_rules.dart';
import '../../../core/services/image_upload_validator.dart';
import '../../../core/utils/validators.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/session/app_session.dart';

class DriverApplicationPendingScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> Function()? loader;
  const DriverApplicationPendingScreen({super.key, this.loader});
  @override
  State<DriverApplicationPendingScreen> createState() =>
      _DriverApplicationPendingScreenState();
}

class _DriverApplicationPendingScreenState
    extends State<DriverApplicationPendingScreen> {
  final _form = GlobalKey<FormState>();
  final _plate = TextEditingController(), _franchise = TextEditingController();
  final _picker = ImagePicker();
  Map<String, dynamic>? _application;
  XFile? _license, _vehicle;
  DateTime? _licenseExpiry, _franchiseExpiry;
  bool _busy = false, _editing = false, _accessible = true;
  int _capacity = 3;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _plate.dispose();
    _franchise.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      if (widget.loader != null) {
        final data = await widget.loader!();
        if (mounted) setState(() => _application = data);
        return;
      }
      final profile = await AuthService.restoreSession();
      if (profile == null) {
        await AppSession.handleSessionEnded();
        return;
      }
      final desiredRole = profile.applicationPending
          ? 'driver_pending'
          : profile.role.name;
      if (AppSession.authenticatedRole != desiredRole ||
          AppSession.authenticatedUserId != profile.id) {
        AppSession.setAuthenticatedUser(
          id: profile.id,
          name: profile.name,
          role: profile.applicationPending
              ? 'driver_pending'
              : profile.role.name,
          email: profile.email,
          plateNumber: profile.plateNumber,
        );
      }
      if (!profile.applicationPending) {
        if (mounted) context.go('/driver/home');
        return;
      }
      final row = await BackendConfig.client
          .from('driver_profiles')
          .select(
            'plate_number,franchise_number,license_document_path,vehicle_document_path,approval_status',
          )
          .eq('profile_id', profile.id)
          .maybeSingle();
      if (mounted) {
        setState(() => _application = Map<String, dynamic>.from(row ?? {}));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    }
  }

  Future<void> _date(bool license) async {
    final today = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 365)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
    );
    if (value != null && mounted) {
      setState(() {
        if (license) {
          _licenseExpiry = value;
        } else {
          _franchiseExpiry = value;
        }
      });
    }
  }

  Future<void> _pick(bool license) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2200,
    );
    if (file != null && mounted) {
      setState(() {
        if (license) {
          _license = file;
        } else {
          _vehicle = file;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_license == null ||
        _vehicle == null ||
        _licenseExpiry == null ||
        _franchiseExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chooseBothDocumentsAndExpiryDates)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final consent = await PrivacyService.status();
      if (!consent.accepted) {
        AppSession.authRevision.value++;
        throw const TripRuleException(
          MessageCode.acceptTheCurrentPrivacyNoticeBeforeSubmitting,
        );
      }
      final license = await _license!.readAsBytes(),
          vehicle = await _vehicle!.readAsBytes();
      if (ImageUploadValidator.validateProfileImage(license) != 'image/jpeg' ||
          ImageUploadValidator.validateProfileImage(vehicle) != 'image/jpeg') {
        throw const TripRuleException(MessageCode.chooseJpegDocumentImages);
      }
      await AuthService.submitPendingApplication(
        privacyVersion: consent.notice.version,
        plateNumber: _plate.text,
        franchiseNumber: _franchise.text,
        licenseExpiresOn: _licenseExpiry!,
        franchiseExpiresOn: _franchiseExpiry!,
        passengerCapacity: _capacity,
        acceptsAccessibilityRequests: _accessible,
        licenseBytes: license,
        vehicleRegistrationBytes: vehicle,
      );
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.applicationSubmittedForAdministratorReview,
            ),
          ),
        );
        await _refresh();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitted =
        _application?['license_document_path'] != null &&
        _application?['vehicle_document_path'] != null;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.driverApplication)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Semantics(
              header: true,
              child: Text(
                context.l10n.applicationPending,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              context
                  .l10n
                  .yourAccountCanUploadApplicationDocumentsAndCheckApprovalGoingOnlineAndAccepting,
            ),
            if (submitted && !_editing) ...[
              Text(context.l10n.yourDocumentsAreUnderReview),
              OutlinedButton(
                onPressed: () => setState(() => _editing = true),
                child: Text(context.l10n.updateApplication),
              ),
            ] else
              Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _plate,
                      validator: localizeValidator(
                        context,
                        Validators.plateNumber,
                      ),
                      decoration: InputDecoration(
                        labelText: context.l10n.plateNumber,
                      ),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      scrollPadding: const EdgeInsets.all(96),
                    ),
                    TextFormField(
                      controller: _franchise,
                      validator: localizeValidator(
                        context,
                        Validators.franchiseNumber,
                      ),
                      decoration: InputDecoration(
                        labelText: context.l10n.franchiseNumber,
                      ),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      scrollPadding: const EdgeInsets.all(96),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _date(true),
                      child: Text(
                        context.message(
                          _licenseExpiry == null
                              ? MessageCode.chooseLicenseExpiry
                              : AppFormatters.dateShort(_licenseExpiry!),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _date(false),
                      child: Text(
                        context.message(
                          _franchiseExpiry == null
                              ? MessageCode.chooseFranchiseExpiry
                              : AppFormatters.dateShort(_franchiseExpiry!),
                        ),
                      ),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: _capacity,
                      decoration: InputDecoration(
                        labelText: context.l10n.passengerCapacity,
                      ),
                      items: [
                        for (final n in [1, 2, 3])
                          DropdownMenuItem(
                            value: n,
                            child: Text(context.message('$n')),
                          ),
                      ],
                      onChanged: (value) => setState(() => _capacity = value!),
                    ),
                    CheckboxListTile(
                      value: _accessible,
                      onChanged: (value) =>
                          setState(() => _accessible = value ?? false),
                      title: Text(context.l10n.acceptAssistanceRequests),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pick(true),
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        context.message(
                          _license == null
                              ? MessageCode.chooseLicenseImage
                              : MessageCode.licenseImageSelected,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pick(false),
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        context.message(
                          _vehicle == null
                              ? MessageCode.chooseVehicleRegistrationImage
                              : MessageCode.vehicleImageSelected,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(
                        context.message(
                          _busy
                              ? MessageCode.uploading
                              : MessageCode.submitApplication,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            TextButton(
              onPressed: () => context.push('/driver/data-rights'),
              child: Text(context.l10n.myData),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _refresh,
              child: Text(context.l10n.checkApproval),
            ),
            TextButton(
              onPressed: _busy ? null : AppSession.signOut,
              child: Text(context.l10n.signOut),
            ),
          ],
        ),
      ),
    );
  }
}
