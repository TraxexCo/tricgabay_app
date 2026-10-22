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
  String _selectedCategory = 'Suggestion';
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
    final categories = [
      'Bug Report',
      'Suggestion',
      'Driver Concern',
      'Tourist Spot Issue',
      'Other',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Submit Feedback',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
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
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) =>
                        setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Text(
                'Message',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Message',
                controller: _msgCtrl,
                hint: 'Please describe your concern or suggestion in detail...',
                maxLines: 6,
                validator: (val) {
                  if (val == null || val.trim().length < 20) {
                    return 'Please enter at least 20 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              AppButton(
                label: 'Submit',
                isLoading: _isLoading,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (!_isLoading) setState(() => _isLoading = true);
                    try {
                      if (!BackendConfig.isConfigured) {
                        throw StateError(
                          'Server setup is incomplete. Feedback was not sent.',
                        );
                      }
                      await BackendRepository.submitFeedback(
                        category: _selectedCategory,
                        message: _msgCtrl.text,
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('$error')));
                      return;
                    }

                    if (!context.mounted) return;
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback submitted! Thank you 🙏'),
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
