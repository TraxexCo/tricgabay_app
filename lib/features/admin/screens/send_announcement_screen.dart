import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shared_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/validators.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/config/backend_config.dart';

class SendAnnouncementScreen extends StatefulWidget {
  const SendAnnouncementScreen({super.key});

  @override
  State<SendAnnouncementScreen> createState() => _SendAnnouncementScreenState();
}

class _SendAnnouncementScreenState extends State<SendAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  bool _sending = false;

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate() || _sending) return;
    if (!BackendConfig.isConfigured) {
      AppSnackbar.showError(
        context,
        'Server setup is incomplete. Nothing was sent.',
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await BackendRepository.sendAnnouncement(
        _titleController.text,
        _messageController.text,
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Announcement sent successfully');
      context.pop();
    } catch (error) {
      if (mounted) AppSnackbar.showError(context, '$error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Send Announcement',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Broadcast a Message',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will send a notification to all users in the system.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'e.g. System Maintenance',
                prefixIcon: Icons.title,
                validator: (value) =>
                    Validators.required(value, fieldName: 'Title'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _messageController,
                label: 'Message',
                hint: 'Enter your announcement details here...',
                prefixIcon: Icons.message,
                maxLines: 5,
                validator: (value) =>
                    Validators.required(value, fieldName: 'Message'),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Send Announcement',
                isLoading: _sending,
                onPressed: _sendAnnouncement,
                prefixIcon: Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
