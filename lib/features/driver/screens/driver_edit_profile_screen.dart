import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/session/app_session.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/utils/validators.dart';

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
      text: AppSession.currentDriverName.value,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (!BackendConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.serverSetupIsIncomplete)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final accountId = BackendConfig.client.auth.currentUser?.id;
      final savedName = _nameController.text.trim();
      final passengerCapacity = _passengerCapacity;
      final acceptsAccessibilityRequests = _acceptsAccessibilityRequests;
      await BackendRepository.updateOwnProfile(
        fullName: savedName,
        phone: _phoneController.text,
        avatarBytes: _imageBytes,
        plateNumber: _plateController.text,
        franchiseNumber: _franchiseController.text,
      );
      if (!mounted ||
          accountId == null ||
          BackendConfig.client.auth.currentUser?.id != accountId) {
        return;
      }
      AppSession.updateAccountName(savedName);
      await BackendRepository.updateDriverServiceProfile(
        passengerCapacity: passengerCapacity,
        acceptsAccessibilityRequests: acceptsAccessibilityRequests,
      );
      await AppSession.syncRemoteState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileUpdatedSuccessfully),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.editProfile)),
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
                          tooltip: context.l10n.changePhoto,
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
                label: context.l10n.fullName,
                hint: context.l10n.juanDelaCruz,
                prefixIcon: Icons.person,
                controller: _nameController,
                maxLength: Validators.fullNameMaxLength,
                validator: Validators.fullName,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _passengerCapacity,
                decoration: InputDecoration(
                  labelText: context.l10n.safePassengerCapacity,
                  prefixIcon: Icon(Icons.groups_2_outlined),
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
                title: Text(context.l10n.acceptAssistanceRequests),
                subtitle: Text(
                  context
                      .l10n
                      .allowMatchingForTouristsWithMobilityOrBoardingNeeds,
                ),
              ),
              Text(
                context
                    .l10n
                    .changingServiceCapacityRequiresAdministratorApprovalBeforeYouCanGoOnlineAgain,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildComplianceCard(),
              const SizedBox(height: 16),
              AppTextField(
                label: context.l10n.emailReadOnly,
                controller: _emailController,
                prefixIcon: Icons.email,
                enabled: false,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: context.l10n.phoneNumber,
                hint: '09123456789',
                prefixIcon: Icons.phone,
                controller: _phoneController,
                maxLength: 11,
                keyboardType: TextInputType.phone,
                validator: Validators.phoneNumber,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: context.l10n.plateNumber,
                hint: context.l10n.abc1234,
                prefixIcon: Icons.directions_car,
                controller: _plateController,
                maxLength: Validators.plateNumberMaxLength,
                validator: Validators.plateNumber,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: context.l10n.franchiseNumber,
                hint: context.l10n.fr12345,
                prefixIcon: Icons.document_scanner,
                controller: _franchiseController,
                maxLength: Validators.franchiseNumberMaxLength,
                validator: Validators.franchiseNumber,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: context.l10n.saveChanges,
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
          ? MessageCode.notVerified
          : AppFormatters.dateShort(date);
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
                  context.message(
                    status == 'approved'
                        ? MessageCode.complianceApproved
                        : MessageCode.complianceReviewRequired,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Flexible(
                child: Text(
                  context.l10n.reliableValue(
                    context.message(
                      (reliability.toStringAsFixed(0)).toString(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.licenseValue(
              context.message((dateLabel('license_expires_on')).toString()),
            ),
          ),
          Text(
            context.l10n.franchiseValue(
              context.message((dateLabel('franchise_expires_on')).toString()),
            ),
          ),
          Text(
            context.l10n.vehicleInspectionValue(
              context.message(
                (dateLabel('vehicle_inspection_expires_on')).toString(),
              ),
            ),
          ),
          Text(
            context.l10n.complianceServiceArea(
              context.message(
                (_compliance['service_area_name'] ?? MessageCode.notVerified)
                    .toString(),
              ),
              context.message(
                (_compliance['service_area_radius_km'] ?? 0).toString(),
              ),
            ),
          ),
          if (blockedReason != null && blockedReason.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              context.message(blockedReason),
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
