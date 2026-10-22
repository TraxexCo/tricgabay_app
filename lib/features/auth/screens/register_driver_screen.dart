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
        const SnackBar(content: Text('Attach both required driver documents.')),
      );
      return;
    }
    if (!BackendConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server setup is incomplete.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await AuthService.registerDriver(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted for administrator review.'),
        ),
      );
      context.go('/login');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
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
      helpText: license ? 'License expiry date' : 'Franchise expiry date',
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
      ? 'Select expiry date'
      : '${value.month}/${value.day}/${value.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Driver Registration',
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
                      label: _currentStep == 2 ? 'Submit application' : 'Next',
                      isLoading: _submitting,
                      onPressed: details.onStepContinue,
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        label: 'Back',
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
              title: const Text('Personal Info'),
              content: Column(
                children: [
                  AppTextField(
                    controller: _name,
                    label: 'Full Name',
                    hint: 'Juan Dela Cruz',
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.trim().length < 2
                        ? 'Full Name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _email,
                    label: 'Email',
                    hint: 'juan@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _phone,
                    label: 'Phone Number',
                    hint: '+63 912 345 6789',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    validator: (v) =>
                        v == null || v.replaceAll(RegExp(r'\D'), '').length < 10
                        ? 'Enter a valid phone number'
                        : null,
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Vehicle Info'),
              content: Column(
                children: [
                  AppTextField(
                    controller: _plate,
                    label: 'Plate Number',
                    hint: 'ABC 1234',
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Plate Number is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _franchise,
                    label: 'Franchise Number',
                    hint: 'F-123456',
                    textInputAction: TextInputAction.done,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Franchise Number is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _expiryTile(
                    title: 'Driver license expiry',
                    value: _licenseExpiresOn,
                    onTap: () => _pickExpiry(true),
                  ),
                  const SizedBox(height: 12),
                  _expiryTile(
                    title: 'Franchise / OR-CR expiry',
                    value: _franchiseExpiresOn,
                    onTap: () => _pickExpiry(false),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _passengerCapacity,
                    decoration: const InputDecoration(
                      labelText: 'Safe passenger capacity',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 passenger')),
                      DropdownMenuItem(value: 2, child: Text('2 passengers')),
                      DropdownMenuItem(value: 3, child: Text('3 passengers')),
                    ],
                    onChanged: (value) =>
                        setState(() => _passengerCapacity = value ?? 3),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _acceptsAccessibilityRequests,
                    onChanged: (value) =>
                        setState(() => _acceptsAccessibilityRequests = value),
                    title: const Text('Accept assistance requests'),
                    subtitle: const Text(
                      'Match with tourists who describe mobility or boarding needs.',
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Documents & Password'),
              content: Column(
                children: [
                  _buildUploadBtn('license', 'Driver\'s license'),
                  const SizedBox(height: 16),
                  _buildUploadBtn('vehicle', 'Franchise OR/CR'),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _password,
                    label: 'Password',
                    hint: 'Min. 8 chars',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) => v == null || v.length < 8
                        ? 'Password must be at least 8 characters'
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
              uploaded ? '$title attached' : 'Upload $title',
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
      title: Text(title),
      subtitle: Text(_dateLabel(value)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
