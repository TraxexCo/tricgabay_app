import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/backend_repository.dart';

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
    text: PrototypeSession.currentUserName.value,
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
      if (mounted) AppSnackbar.showError(context, '$error');
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
          throw StateError('Server setup is incomplete.');
        }
        await BackendRepository.updateOwnProfile(
          fullName: _nameCtrl.text,
          phone: _phoneCtrl.text,
          avatarBytes: _pickedImage,
        );
        PrototypeSession.updateUserName(_nameCtrl.text.trim());
        if (!mounted) return;
        AppSnackbar.showSuccess(context, 'Profile updated successfully!');
        context.pop();
      } catch (error) {
        if (mounted) AppSnackbar.showError(context, '$error');
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
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
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Full Name',
                controller: _nameCtrl,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone Number',
                controller: _phoneCtrl,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                controller: _emailCtrl,
                readOnly: true,
              ),
              const SizedBox(height: 40),
              AppButton(
                label: 'Save Changes',
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
