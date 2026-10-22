import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/backend_repository.dart';

class DriverEditProfileScreen extends ConsumerStatefulWidget {
  const DriverEditProfileScreen({super.key});

  @override
  ConsumerState<DriverEditProfileScreen> createState() =>
      _DriverEditProfileScreenState();
}

class _DriverEditProfileScreenState
    extends ConsumerState<DriverEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _plateController;
  late TextEditingController _franchiseController;

  Uint8List? _imageBytes;
  bool _saving = false;
  late TextEditingController _emailController;
  int _passengerCapacity = 3;
  bool _acceptsAccessibilityRequests = true;
  Map<String, dynamic> _compliance = const {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: PrototypeSession.currentDriverName.value,
    );
    _phoneController = TextEditingController();
    _plateController = TextEditingController();
    _franchiseController = TextEditingController();
    _emailController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    _franchiseController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _loadProfile() async {
    if (!BackendConfig.isConfigured) return;
    try {
      final profile = await BackendRepository.loadOwnProfile();
      if (!mounted) return;
      _nameController.text = profile['full_name'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _emailController.text = profile['email'] ?? '';
      _plateController.text = profile['plate_number'] ?? '';
      _franchiseController.text = profile['franchise_number'] ?? '';
      _passengerCapacity = profile['passenger_capacity'] as int? ?? 3;
      _acceptsAccessibilityRequests =
          profile['accepts_accessibility_requests'] as bool? ?? true;
      _compliance = profile;
      setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (!BackendConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server setup is incomplete.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await BackendRepository.updateOwnProfile(
        fullName: _nameController.text,
        phone: _phoneController.text,
        avatarBytes: _imageBytes,
        plateNumber: _plateController.text,
        franchiseNumber: _franchiseController.text,
      );
      await BackendRepository.updateDriverServiceProfile(
        passengerCapacity: _passengerCapacity,
        acceptsAccessibilityRequests: _acceptsAccessibilityRequests,
      );
      PrototypeSession.currentDriverName.value = _nameController.text.trim();
      await PrototypeSession.syncRemoteState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : null,
                      child: _imageBytes == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Full Name',
                hint: 'Juan Dela Cruz',
                prefixIcon: Icons.person,
                controller: _nameController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _passengerCapacity,
                decoration: const InputDecoration(
                  labelText: 'Safe passenger capacity',
                  prefixIcon: Icon(Icons.groups_2_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 passenger')),
                  DropdownMenuItem(value: 2, child: Text('2 passengers')),
                  DropdownMenuItem(value: 3, child: Text('3 passengers')),
                ],
                onChanged: _saving
                    ? null
                    : (value) =>
                          setState(() => _passengerCapacity = value ?? 3),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _acceptsAccessibilityRequests,
                onChanged: _saving
                    ? null
                    : (value) =>
                          setState(() => _acceptsAccessibilityRequests = value),
                title: const Text('Accept assistance requests'),
                subtitle: const Text(
                  'Allow matching for tourists with mobility or boarding needs.',
                ),
              ),
              const Text(
                'Changing service capacity requires administrator approval before you can go online again.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildComplianceCard(),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email (Read-only)',
                controller: _emailController,
                prefixIcon: Icons.email,
                enabled: false,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone Number',
                hint: '09123456789',
                prefixIcon: Icons.phone,
                controller: _phoneController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Plate Number',
                hint: 'ABC 1234',
                prefixIcon: Icons.directions_car,
                controller: _plateController,
                validator: (val) => val == null || val.isEmpty
                    ? 'Plate number is required'
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Franchise Number',
                hint: 'FR-12345',
                prefixIcon: Icons.document_scanner,
                controller: _franchiseController,
                validator: (val) => val == null || val.isEmpty
                    ? 'Franchise number is required'
                    : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Save Changes',
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplianceCard() {
    final status = _compliance['approval_status']?.toString() ?? 'pending';
    final reliability =
        (_compliance['reliability_score'] as num?)?.toDouble() ?? 100;
    final blockedReason = _compliance['matching_blocked_reason']?.toString();
    String dateLabel(String key) {
      final date = DateTime.tryParse(_compliance[key]?.toString() ?? '');
      return date == null
          ? 'Not verified'
          : '${date.month}/${date.day}/${date.year}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status == 'approved'
            ? AppColors.success.withValues(alpha: .08)
            : AppColors.warning.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == 'approved'
                    ? Icons.verified_user_outlined
                    : Icons.pending_actions_outlined,
                color: status == 'approved'
                    ? AppColors.success
                    : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status == 'approved'
                      ? 'Compliance approved'
                      : 'Compliance review required',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text('${reliability.toStringAsFixed(0)}% reliable'),
            ],
          ),
          const SizedBox(height: 10),
          Text('License: ${dateLabel('license_expires_on')}'),
          Text('Franchise: ${dateLabel('franchise_expires_on')}'),
          Text(
            'Vehicle inspection: ${dateLabel('vehicle_inspection_expires_on')}',
          ),
          Text(
            'Service area: ${_compliance['service_area_name'] ?? 'Not verified'} '
            '(${_compliance['service_area_radius_km'] ?? 0} km)',
          ),
          if (blockedReason != null && blockedReason.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              blockedReason,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
