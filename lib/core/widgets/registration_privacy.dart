import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import '../services/privacy_service.dart';
import '../services/error_messages.dart';
import '../services/telemetry_service.dart';
export '../services/privacy_service.dart' show PrivacyNotice;

Future<PrivacyNotice?> requestRegistrationConsent(
  BuildContext context, {
  Future<PrivacyNotice> Function()? loader,
}) async {
  late final PrivacyNotice notice;
  try {
    notice = await (loader ?? PrivacyService.notice)();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.message(ErrorMessages.forError(error)))),
      );
    }
    return null;
  }
  if (!context.mounted) return null;
  var accepted = false, telemetry = false;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(context.l10n.privacyAndDataUse),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.message(
                    notice.text(Localizations.localeOf(ctx).languageCode),
                  ),
                ),
                CheckboxListTile(
                  value: accepted,
                  onChanged: (value) =>
                      setState(() => accepted = value ?? false),
                  title: Text(
                    context.l10n.iHaveReadTheNoticeAndAgreeToTheDataUseNeededTo,
                  ),
                ),
                CheckboxListTile(
                  value: telemetry,
                  onChanged: (value) =>
                      setState(() => telemetry = value ?? false),
                  title: Text(context.l10n.allowOptionalCrashDiagnostics),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: accepted ? () => Navigator.pop(ctx, true) : null,
            child: Text(context.l10n.agreeAndContinue),
          ),
        ],
      ),
    ),
  );
  if (result != true) return null;
  if (!context.mounted) return null;
  final shownLanguage = Localizations.localeOf(context).languageCode;
  await TelemetryService.setConsent(telemetry);
  return notice.inLanguage(shownLanguage);
}
