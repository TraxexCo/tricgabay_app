import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'list_skeleton.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/backend_config.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

class EmergencyContactsView extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function()? loader;
  final Future<bool> Function(Uri)? dialer;
  const EmergencyContactsView({super.key, this.loader, this.dialer});
  @override
  State<EmergencyContactsView> createState() => _EmergencyContactsViewState();
}

class _EmergencyContactsViewState extends State<EmergencyContactsView> {
  late Future<List<Map<String, dynamic>>> _contacts;
  static const fallback = <Map<String, dynamic>>[
    {
      'id': 'national',
      'name_en': MessageCode.nationalEmergencyHotline,
      'name_fil': MessageCode.nationalEmergencyHotline,
      'phone': '911',
      'is_placeholder': false,
    },
  ];
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _contacts = (widget.loader ?? _load)();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (!BackendConfig.isConfigured) return fallback;
    final rows = await BackendConfig.client
        .from('emergency_contacts')
        .select()
        .eq('is_active', true)
        .order('priority');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _call(Map<String, dynamic> contact) async {
    if (contact['is_placeholder'] == true || contact['phone'] == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.callEmergencyServices),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.message(contact['phone'] as String)),
            Text(
              context
                  .l10n
                  .thisOpensYourPhoneDialerConfirmTheNumberBeforeCalling,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.openDialer),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final uri = Uri(scheme: 'tel', path: contact['phone'] as String);
    final opened = await (widget.dialer ?? (uri) => launchUrl(uri))(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context
                .l10n
                .couldNotOpenThePhoneDialerCallTheDisplayedNumberManually,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.emergencyContacts)),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _contacts,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ListSkeleton();
        }
        final rows = snapshot.data ?? fallback;
        final language = Localizations.localeOf(context).languageCode;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: .25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.sos_rounded,
                        color: AppColors.danger,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.l10n
                              .forImmediateDangerCall911AppDoesNotReplaceEmergencyServices(
                                AppBrand.name,
                              ),
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () => _call(fallback.first),
                    icon: const Icon(Icons.call_rounded),
                    label: Text(context.l10n.call911Now),
                  ),
                ],
              ),
            ),
            if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  context
                      .l10n
                      .contactUpdatesAreUnavailableOnlyTheNationalFallbackIsShown,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.warning,
                  ),
                ),
              ),
            const SizedBox(height: 22),
            Text(
              context.l10n.localContacts,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final row in rows) _contactCard(row, language),
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(_reload),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.refresh),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _contactCard(Map<String, dynamic> row, String language) {
    final placeholder = row['is_placeholder'] == true;
    final name = row[language == 'fil' ? 'name_fil' : 'name_en'] as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (placeholder ? AppColors.textHint : AppColors.primary)
                  .withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.local_phone_rounded,
              color: placeholder ? AppColors.textHint : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.message(name),
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  placeholder
                      ? context
                            .l10n
                            .placeholderTheOwnerMustVerifyAndEnterANumber
                      : context.message(row['phone'] as String),
                  style: GoogleFonts.poppins(
                    fontSize: placeholder ? 12.5 : 15,
                    fontWeight: placeholder ? FontWeight.w400 : FontWeight.w700,
                    color: placeholder
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: context.l10n.openDialer,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.success,
              disabledBackgroundColor: AppColors.surfaceVariant,
            ),
            icon: const Icon(Icons.call_rounded, color: Colors.white),
            onPressed: placeholder ? null : () => _call(row),
          ),
        ],
      ),
    );
  }
}
