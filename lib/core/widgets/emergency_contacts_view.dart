import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              context.l10n
                  .forImmediateDangerCall911AppDoesNotReplaceEmergencyServices(
                    AppBrand.name,
                  ),
            ),
            if (snapshot.hasError)
              Text(
                context
                    .l10n
                    .contactUpdatesAreUnavailableOnlyTheNationalFallbackIsShown,
              ),
            const SizedBox(height: 16),
            for (final row in rows)
              Card(
                child: ListTile(
                  title: Text(
                    context.message(
                      row[language == 'fil' ? 'name_fil' : 'name_en'] as String,
                    ),
                  ),
                  subtitle: row['is_placeholder'] == true
                      ? Text(
                          context
                              .l10n
                              .placeholderTheOwnerMustVerifyAndEnterANumber,
                        )
                      : Text(context.message(row['phone'] as String)),
                  trailing: IconButton(
                    tooltip: context.l10n.openDialer,
                    icon: const Icon(Icons.call_outlined),
                    onPressed: row['is_placeholder'] == true
                        ? null
                        : () => _call(row),
                  ),
                ),
              ),
            TextButton(
              onPressed: () => setState(_reload),
              child: Text(context.l10n.refresh),
            ),
          ],
        );
      },
    ),
  );
}
