import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/session/app_session.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/utils/validators.dart';

class TouristEditProfileScreen extends StatefulWidget {
  const TouristEditProfileScreen({super.key});

  @override
  State<TouristEditProfileScreen> createState() =>
      _TouristEditProfileScreenState();
}

class _TouristEditProfileScreenState extends State<TouristEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final _nameCtrl = TextEditingController(
    text: AppSession.currentUserName.value,
  );
  late final _phoneCtrl = TextEditingController(text: '');
  late final _emailCtrl = TextEditingController();
  Uint8List? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!BackendConfig.isConfigured) return;
    try {
      final profile = await BackendRepository.loadOwnProfile();
      if (!mounted) return;
      _nameCtrl.text = profile['full_name'] ?? '';
      _phoneCtrl.text = profile['phone'] ?? '';
      _emailCtrl.text = profile['email'] ?? '';
      setState(() {});
    } catch (error) {
      if (mounted) {
        AppSnackbar.showError(context, ErrorMessages.forError(error));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (!BackendConfig.isConfigured) {
          throw StateError(MessageCode.serverSetupIsIncomplete);
        }
        final accountId = BackendConfig.client.auth.currentUser?.id;
        final savedName = _nameCtrl.text.trim();
        await BackendRepository.updateOwnProfile(
          fullName: savedName,
          phone: _phoneCtrl.text,
          avatarBytes: _pickedImage,
        );
        if (!mounted ||
            accountId == null ||
            BackendConfig.client.auth.currentUser?.id != accountId) {
          return;
        }
        AppSession.updateAccountName(savedName);
        AppSnackbar.showSuccess(
          context,
          MessageCode.profileUpdatedSuccessfullyLabel,
        );
        context.pop();
      } catch (error) {
        if (mounted) {
          AppSnackbar.showError(context, ErrorMessages.forError(error));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      if (mounted) setState(() => _pickedImage = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.editProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  _pickedImage != null
                      ? CircleAvatar(
                          radius: 60,
                          backgroundImage: MemoryImage(_pickedImage!),
                        )
                      : const CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      tooltip: context.l10n.changePhoto,
                      onPressed: _pickImage,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.camera_alt),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: context.l10n.fullName,
                controller: _nameCtrl,
                maxLength: Validators.fullNameMaxLength,
                validator: Validators.fullName,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: context.l10n.phoneNumber,
                controller: _phoneCtrl,
                maxLength: 11,
                keyboardType: TextInputType.phone,
                validator: Validators.phoneNumber,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: context.l10n.email,
                controller: _emailCtrl,
                readOnly: true,
              ),
              const SizedBox(height: 40),
              AppButton(
                label: context.l10n.saveChanges,
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
