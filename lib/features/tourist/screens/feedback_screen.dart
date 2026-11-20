import 'package:tricgabay_app/core/l10n/feedback_category.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/config/backend_config.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  FeedbackCategory _selectedCategory = FeedbackCategory.suggestion;
  final _msgCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = FeedbackCategory.values;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.submitFeedback)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.category,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat.label(context)),
                    selected: isSelected,
                    onSelected: (val) =>
                        setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Text(
                context.l10n.message,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: context.l10n.message,
                controller: _msgCtrl,
                hint:
                    context.l10n.pleaseDescribeYourConcernOrSuggestionInDetail,
                maxLines: 6,
                validator: (val) {
                  if (val == null || val.trim().length < 20) {
                    return MessageCode.pleaseEnterAtLeast20Characters;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              AppButton(
                label: context.l10n.submit,
                isLoading: _isLoading,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (!_isLoading) setState(() => _isLoading = true);
                    try {
                      if (!BackendConfig.isConfigured) {
                        throw StateError(
                          MessageCode.serverSetupIsIncompleteFeedbackWasNotSent,
                        );
                      }
                      await BackendRepository.submitFeedback(
                        category: _selectedCategory.wireValue,
                        message: _msgCtrl.text,
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.message(ErrorMessages.forError(error)),
                          ),
                        ),
                      );
                      return;
                    }

                    if (!context.mounted) return;
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.feedbackSubmittedThankYou),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
