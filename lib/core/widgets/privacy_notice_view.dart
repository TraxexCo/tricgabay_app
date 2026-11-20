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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l.privacyNoticeTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: Icon(
                      Icons.verified_user_outlined,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                available
                    ? l.privacyWelcomeTitle
                    : l.unableToLoadThePrivacyNotice,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                available
                    ? l.privacyWelcomeBody(AppBrand.name)
                    : l.connectToTheInternetAndRetry,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              if (available) ...[
                _summary(
                  context,
                  Icons.badge_outlined,
                  l.privacyAccountTitle,
                  l.privacyAccountBody,
                ),
                _summary(
                  context,
                  Icons.location_on_outlined,
                  l.privacyLocationTitle,
                  l.privacyLocationBody,
                ),
                _summary(
                  context,
                  Icons.tune_rounded,
                  l.privacyChoiceTitle,
                  l.privacyChoiceBody,
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.privacyFullNotice,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.privacyVersionLabel(notice!.version),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Divider(height: 28),
                        Text(
                          notice!.text(
                            Localizations.localeOf(context).languageCode,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                height: 1.7,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  semanticContainer: false,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.allowOptionalCrashDiagnostics,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                        const SizedBox(height: 8),
                        Text(
                          l.privacyDiagnosticsHelp,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: checked,
                  onChanged: saving
                      ? null
                      : (value) => onChecked(value ?? false),
                  title: Text(l.iHaveReadAndAcceptThisNotice),
                ),
                const SizedBox(height: 8),
                Text(
                  l.privacyRequiredHelp,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
                TextButton(
                  onPressed: saving ? null : onRetry,
                  child: Text(l.retry),
                ),
              ],
              const SizedBox(height: 24),
              if (available)
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onPressed: checked && !saving ? onAccept : null,
                  child: Text(
                    saving ? l.saving : l.acceptAndContinue,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                FilledButton(onPressed: onRetry, child: Text(l.retry)),
              if (onSignOut != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: saving ? null : onSignOut,
                  child: Text(l.signOut),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(
    BuildContext context,
    IconData icon,
    String title,
    String body,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 14),
          child: Icon(icon, size: 24, color: AppColors.primary),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
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
