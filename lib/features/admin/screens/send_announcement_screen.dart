import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/error_messages.dart';
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
  final Future<void> Function(String, String, String, String)? send;
  const SendAnnouncementScreen({super.key, this.send});

  @override
  State<SendAnnouncementScreen> createState() => _SendAnnouncementScreenState();
}

class _SendAnnouncementScreenState extends State<SendAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  bool _sending = false;
  String _audience = 'all';
  String? _requestId;
  bool _previewing = false;

  Future<void> _sendAnnouncement() async {
    if (_previewing || !_formKey.currentState!.validate() || _sending) return;
    if (!BackendConfig.isConfigured && widget.send == null) {
      AppSnackbar.showError(
        context,
        MessageCode.serverSetupIsIncompleteNothingWasSent,
      );
      return;
    }
    _previewing = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.previewAnnouncement),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.audienceValue(
                  context.message((_audience).toString()),
                ),
              ),
              const SizedBox(height: 12),
              Text(context.message(_titleController.text.trim())),
              const SizedBox(height: 8),
              Text(context.message(_messageController.text.trim())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.edit),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.confirmAndSend),
          ),
        ],
      ),
    );
    _previewing = false;
    if (confirmed != true || !mounted) return;
    _requestId ??= const Uuid().v4();
    setState(() => _sending = true);
    try {
      if (widget.send != null) {
        await widget.send!(
          _titleController.text,
          _messageController.text,
          _audience,
          _requestId!,
        );
      } else {
        await BackendRepository.sendAnnouncement(
          _titleController.text,
          _messageController.text,
          audience: _audience,
          requestId: _requestId!,
        );
      }
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        MessageCode.announcementSentSuccessfully,
      );
      context.pop();
    } catch (error) {
      if (mounted) {
        AppSnackbar.showError(context, ErrorMessages.forError(error));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_draftChanged);
    _messageController.addListener(_draftChanged);
  }

  void _draftChanged() {
    if (!_sending) _requestId = null;
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
          context.l10n.sendAnnouncement,
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
                context.l10n.broadcastAMessage,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context
                    .l10n
                    .chooseWhoShouldReceiveThisAnnouncementThenReviewBeforeSending,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _audience,
                decoration: InputDecoration(labelText: context.l10n.audience),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text(context.l10n.touristsAndDrivers),
                  ),
                  DropdownMenuItem(
                    value: 'tourists',
                    child: Text(context.l10n.tourists),
                  ),
                  DropdownMenuItem(
                    value: 'drivers',
                    child: Text(context.l10n.drivers),
                  ),
                ],
                onChanged: _sending
                    ? null
                    : (value) => setState(() {
                        _audience = value!;
                        _requestId = null;
                      }),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _titleController,
                label: context.l10n.title,
                hint: context.l10n.eGSystemMaintenance,
                prefixIcon: Icons.title,
                validator: (value) =>
                    Validators.required(value, fieldName: MessageCode.title),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _messageController,
                label: context.l10n.message,
                hint: context.l10n.enterYourAnnouncementDetailsHere,
                prefixIcon: Icons.message,
                maxLines: 5,
                validator: (value) =>
                    Validators.required(value, fieldName: MessageCode.message),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: context.l10n.sendAnnouncement,
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
