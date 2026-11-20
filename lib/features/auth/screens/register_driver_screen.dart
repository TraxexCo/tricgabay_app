import 'package:tricgabay_app/core/utils/formatters.dart';
import '../../../core/prototype/prototype_session.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/widgets/registration_privacy.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class RegisterDriverScreen extends ConsumerStatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  ConsumerState<RegisterDriverScreen> createState() =>
      _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends ConsumerState<RegisterDriverScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final Map<String, XFile> _documents = {};
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _plate = TextEditingController();
  final _franchise = TextEditingController();
  final _password = TextEditingController();
  int _passengerCapacity = 3;
  bool _acceptsAccessibilityRequests = true;
  DateTime? _licenseExpiresOn;
  DateTime? _franchiseExpiresOn;
  bool _submitting = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _plate,
      _franchise,
      _password,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _continue() async {
    if (_currentStep < 2) {
      final valid = _currentStep == 0
          ? _name.text.trim().length >= 2 &&
                _email.text.contains('@') &&
                _phone.text.replaceAll(RegExp(r'\D'), '').length >= 10
          : _plate.text.trim().isNotEmpty &&
                _franchise.text.trim().isNotEmpty &&
                _licenseExpiresOn != null &&
                _franchiseExpiresOn != null;
      if (!valid) {
        _formKey.currentState!.validate();
        return;
      }
      setState(() => _currentStep++);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_documents.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.attachBothRequiredDriverDocuments)),
      );
      return;
    }
    if (!BackendConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.serverSetupIsIncomplete)),
      );
      return;
    }
    final consent = await requestRegistrationConsent(context);
    if (consent == null || !mounted) return;
    setState(() => _submitting = true);
    try {
      final outcome = await AuthService.registerDriver(
        privacyVersion: consent.version,
        privacyLanguage: consent.shownLanguage!,
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        plateNumber: _plate.text,
        franchiseNumber: _franchise.text,
        licenseExpiresOn: _licenseExpiresOn!,
        franchiseExpiresOn: _franchiseExpiresOn!,
        passengerCapacity: _passengerCapacity,
        acceptsAccessibilityRequests: _acceptsAccessibilityRequests,
        licenseBytes: await _documents['license']!.readAsBytes(),
        vehicleRegistrationBytes: await _documents['vehicle']!.readAsBytes(),
      );
      if (!mounted) return;
      if (outcome == DriverRegistrationOutcome.awaitingEmailConfirmation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context
                  .l10n
                  .confirmYourEmailThenSignInAsADriverToFinishUploadingYour,
            ),
          ),
        );
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.applicationSubmittedForAdministratorReview,
            ),
          ),
        );
        final profile = await AuthService.restoreSession();
        if (profile != null) {
          PrototypeSession.setAuthenticatedUser(
            id: profile.id,
            name: profile.name,
            role: profile.applicationPending
                ? 'driver_pending'
                : profile.role.name,
            email: profile.email,
            plateNumber: profile.plateNumber,
          );
        }
        if (mounted) context.go('/driver/application-pending');
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDocument(String key) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2200,
    );
    if (picked != null && mounted) {
      setState(() => _documents[key] = picked);
    }
  }

  Future<void> _pickExpiry(bool license) async {
    final current = license ? _licenseExpiresOn : _franchiseExpiresOn;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10, 12, 31),
      helpText: license
          ? MessageCode.licenseExpiryDate
          : MessageCode.franchiseExpiryDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (license) {
        _licenseExpiresOn = picked;
      } else {
        _franchiseExpiresOn = picked;
      }
    });
  }

  String _dateLabel(DateTime? value) => value == null
      ? MessageCode.selectExpiryDate
      : AppFormatters.dateShort(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.l10n.driverRegistration,
          style: GoogleFonts.poppins(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 1,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _submitting ? null : _continue,
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: _currentStep == 2
                          ? MessageCode.submitApplication
                          : MessageCode.next,
                      isLoading: _submitting,
                      onPressed: details.onStepContinue,
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        label: context.l10n.back,
                        type: AppButtonType.outline,
                        onPressed: details.onStepCancel,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: Text(context.l10n.personalInfo),
              content: Column(
                children: [
                  AppTextField(
                    controller: _name,
                    label: context.l10n.fullName,
                    hint: context.l10n.juanDelaCruz,
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.trim().length < 2
                        ? MessageCode.fullNameIsRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _email,
                    label: context.l10n.email,
                    hint: context.l10n.juanExampleCom,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || !v.contains('@')
                        ? MessageCode.enterAValidEmail
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _phone,
                    label: context.l10n.phoneNumber,
                    hint: '+63 912 345 6789',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    validator: (v) =>
                        v == null || v.replaceAll(RegExp(r'\D'), '').length < 10
                        ? MessageCode.enterAValidPhoneNumber
                        : null,
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: Text(context.l10n.vehicleInfo),
              content: Column(
                children: [
                  AppTextField(
                    controller: _plate,
                    label: context.l10n.plateNumber,
                    hint: context.l10n.abc1234,
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? MessageCode.plateNumberIsRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _franchise,
                    label: context.l10n.franchiseNumber,
                    hint: context.l10n.f123456,
                    textInputAction: TextInputAction.done,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? MessageCode.franchiseNumberIsRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _expiryTile(
                    title: MessageCode.driverLicenseExpiry,
                    value: _licenseExpiresOn,
                    onTap: () => _pickExpiry(true),
                  ),
                  const SizedBox(height: 12),
                  _expiryTile(
                    title: MessageCode.franchiseOrCrExpiry,
                    value: _franchiseExpiresOn,
                    onTap: () => _pickExpiry(false),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _passengerCapacity,
                    decoration: InputDecoration(
                      labelText: context.l10n.safePassengerCapacity,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 1,
                        child: Text(context.l10n.onePassenger),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(context.l10n.twoPassengers),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(context.l10n.threePassengers),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _passengerCapacity = value ?? 3),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _acceptsAccessibilityRequests,
                    onChanged: (value) =>
                        setState(() => _acceptsAccessibilityRequests = value),
                    title: Text(context.l10n.acceptAssistanceRequests),
                    subtitle: Text(
                      context
                          .l10n
                          .matchWithTouristsWhoDescribeMobilityOrBoardingNeeds,
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: Text(context.l10n.documentsPassword),
              content: Column(
                children: [
                  _buildUploadBtn('license', 'Driver\'s license'),
                  Text(
                    context.l10n.driverDocumentsMustBeJpegImages5MbMaximumEach,
                  ),
                  const SizedBox(height: 16),
                  _buildUploadBtn('vehicle', MessageCode.franchiseOrCrLabel),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _password,
                    label: context.l10n.password,
                    hint: context.l10n.min8Chars,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) => v == null || v.length < 8
                        ? MessageCode.passwordMustBeAtLeast8Characters
                        : null,
                  ),
                ],
              ),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadBtn(String key, String title) {
    final uploaded = _documents.containsKey(key);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pickDocument(key),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: Column(
          children: [
            Icon(
              uploaded ? Icons.check_circle : Icons.upload_file,
              color: uploaded ? AppColors.success : AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              context.message(
                uploaded
                    ? MessageCode.attachedValue((title).toString())
                    : MessageCode.uploadValue((title).toString()),
              ),
              style: GoogleFonts.poppins(
                color: uploaded ? AppColors.success : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expiryTile({
    required String title,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: value == null ? AppColors.danger : AppColors.primary,
        ),
      ),
      leading: const Icon(Icons.event_available_outlined),
      title: Text(context.message(title)),
      subtitle: Text(context.message(_dateLabel(value))),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
