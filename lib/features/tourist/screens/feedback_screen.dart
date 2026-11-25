import 'package:tricgabay_app/core/l10n/feedback_category.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/config/backend_config.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, this.forDriver = false});

  /// Drivers' emergency shortcut goes to the driver SOS screen.
  final bool forDriver;

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

  IconData _icon(FeedbackCategory category) => switch (category) {
    FeedbackCategory.bug => Icons.bug_report_outlined,
    FeedbackCategory.suggestion => Icons.lightbulb_outline_rounded,
    FeedbackCategory.driver => Icons.badge_outlined,
    FeedbackCategory.spot => Icons.place_outlined,
    FeedbackCategory.other => Icons.chat_bubble_outline_rounded,
  };

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _categoryTile(FeedbackCategory category) {
    final selected = _selectedCategory == category;
    return Semantics(
      key: ValueKey(category),
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.surfaceVariant : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _icon(category),
                  size: 22,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.label(context),
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  // White check on a solid blue dot, so it stays visible.
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = FeedbackCategory.values;
    final isDriver = GoRouterState.of(context).uri.path.startsWith('/driver');
    final emergencyRoute = isDriver
        ? AppRoutes.driverEmergency
        : AppRoutes.emergency;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.helpSupport)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF102A43), Color(0xFF1B6CA8)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.howCanWeHelp,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.helpIntroBody(AppBrand.name),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: .88),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push(emergencyRoute),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sos_rounded,
                          color: AppColors.danger,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.needHelpRightNow,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                              Text(
                                context.l10n.localContactsAndSos,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              _sectionTitle(context.l10n.whatIsItAbout),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns =
                      constraints.maxWidth >= 320 &&
                      MediaQuery.textScalerOf(context).scale(1) < 1.4;
                  final width = twoColumns
                      ? (constraints.maxWidth - 10) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final category in categories)
                        SizedBox(width: width, child: _categoryTile(category)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 26),
              _sectionTitle(context.l10n.message),
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
              const SizedBox(height: 28),
              AppButton(
                label: context.l10n.sendSupportMessage,
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
                        backgroundColor: AppColors.success,
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
