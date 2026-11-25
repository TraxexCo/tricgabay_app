import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../l10n/app_l10n.dart';
import '../services/privacy_service.dart';

/// Presentation only; the server remains authoritative for consent/version.
class PrivacyNoticeView extends StatelessWidget {
  final PrivacyNotice? notice;
  final bool checked, telemetry, saving;
  final String? error;
  final ValueChanged<bool> onChecked, onTelemetry;
  final VoidCallback onAccept, onRetry;
  final VoidCallback? onSignOut;
  const PrivacyNoticeView({
    super.key,
    required this.notice,
    required this.checked,
    required this.telemetry,
    required this.saving,
    required this.onChecked,
    required this.onTelemetry,
    required this.onAccept,
    required this.onRetry,
    this.error,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final available = notice != null;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        title: Text(l.privacyNoticeTitle),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: what this screen is, in one glance.
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        available
                            ? l.privacyWelcomeTitle
                            : l.unableToLoadThePrivacyNotice,
                        style: text.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      available
                          ? l.privacyWelcomeBody(AppBrand.name)
                          : l.connectToTheInternetAndRetry,
                      style: text.bodyMedium?.copyWith(
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (available) ...[
                const SizedBox(height: 18),
                _summary(
                  context,
                  Icons.badge_outlined,
                  AppColors.primary,
                  l.privacyAccountTitle,
                  l.privacyAccountBody,
                ),
                _summary(
                  context,
                  Icons.location_on_outlined,
                  AppColors.success,
                  l.privacyLocationTitle,
                  l.privacyLocationBody,
                ),
                _summary(
                  context,
                  Icons.tune_rounded,
                  AppColors.warning,
                  l.privacyChoiceTitle,
                  l.privacyChoiceBody,
                ),
                const SizedBox(height: 6),
                // The full legal text stays one tap away instead of filling
                // the screen.
                Material(
                  color: AppColors.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        l.privacyFullNotice,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        l.privacyVersionLabel(notice!.version),
                        style: text.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Text(
                          notice!.text(
                            Localizations.localeOf(context).languageCode,
                          ),
                          style: text.bodyMedium?.copyWith(
                            height: 1.65,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bug_report_outlined,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.allowOptionalCrashDiagnostics,
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l.privacyDiagnosticsHelp,
                              style: text.bodySmall?.copyWith(
                                height: 1.4,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        container: true,
                        label: l.allowOptionalCrashDiagnostics,
                        child: Switch(
                          value: telemetry,
                          onChanged: saving ? null : onTelemetry,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: checked
                      ? AppColors.primary.withValues(alpha: .06)
                      : AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: checked ? AppColors.primary : AppColors.border,
                      width: checked ? 1.6 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    value: checked,
                    // Stays readable while saving: only taps are ignored.
                    onChanged: (value) {
                      if (!saving) onChecked(value ?? false);
                    },
                    title: Text(
                      l.iHaveReadAndAcceptThisNotice,
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      l.privacyRequiredHelp,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: saving ? null : onRetry,
                  child: Text(l.retry),
                ),
              ],
              const SizedBox(height: 18),
              if (available)
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onPressed: checked && !saving ? onAccept : null,
                  child: saving
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hourglass_top_rounded, size: 18),
                            const SizedBox(width: 10),
                            Flexible(child: Text(l.saving)),
                          ],
                        )
                      : Text(l.acceptAndContinue, textAlign: TextAlign.center),
                )
              else
                FilledButton(onPressed: onRetry, child: Text(l.retry)),
              if (onSignOut != null) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: saving ? null : onSignOut,
                  child: Text(l.signOut),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    String body,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.45,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
