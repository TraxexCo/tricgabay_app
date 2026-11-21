import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/error_messages.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

class EmergencyContactsAdminScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function()? loader;
  const EmergencyContactsAdminScreen({super.key, this.loader});
  @override
  State<EmergencyContactsAdminScreen> createState() =>
      _EmergencyContactsAdminScreenState();
}

class _EmergencyContactsAdminScreenState
    extends State<EmergencyContactsAdminScreen> {
  late Future<List<Map<String, dynamic>>> _rows;
  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.loader != null) return widget.loader!();
    return List<Map<String, dynamic>>.from(
      await BackendConfig.client
          .from('emergency_contacts')
          .select()
          .order('priority'),
    );
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final phone = TextEditingController(text: row['phone'] as String? ?? '');
    final english = TextEditingController(text: row['name_en'] as String);
    final filipino = TextEditingController(text: row['name_fil'] as String);
    var verified = false, busy = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(context.l10n.emergencyContact),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: english,
                  decoration: InputDecoration(labelText: ctx.l10n.englishName),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  scrollPadding: const EdgeInsets.all(96),
                ),
                TextField(
                  controller: filipino,
                  decoration: InputDecoration(labelText: ctx.l10n.filipinoName),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  scrollPadding: const EdgeInsets.all(96),
                ),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: ctx.l10n.phoneNumber),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  scrollPadding: const EdgeInsets.all(96),
                ),
                Text(
                  context
                      .l10n
                      .leaveTheNumberEmptyToKeepAClearlyMarkedPlaceholder,
                ),
                CheckboxListTile(
                  value: verified,
                  onChanged: busy
                      ? null
                      : (value) => setDialog(() => verified = value ?? false),
                  title: Text(context.l10n.iVerifiedThisNumberWithTheAgency),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (phone.text.trim().isNotEmpty && !verified) return;
                      setDialog(() => busy = true);
                      try {
                        await BackendConfig.client.rpc(
                          'update_emergency_contact',
                          params: {
                            'p_id': row['id'],
                            'p_phone': phone.text,
                            'p_name_en': english.text,
                            'p_name_fil': filipino.text,
                          },
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) setState(() => _rows = _load());
                      } catch (error) {
                        if (ctx.mounted) {
                          setDialog(() => busy = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                ctx.message(ErrorMessages.forError(error)),
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: Text(context.l10n.saveChanges),
            ),
          ],
        ),
      ),
    );
    phone.dispose();
    english.dispose();
    filipino.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.emergencyContactsSettings)),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _rows,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              context.message(ErrorMessages.forError(snapshot.error!)),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context
                  .l10n
                  .theOwnerMustVerifyLocalAgencyNumbersBeforeEnablingCalls,
            ),
            const SizedBox(height: 12),
            for (final row in snapshot.data!)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    row['is_placeholder'] == true
                        ? Icons.warning_amber_rounded
                        : Icons.phone_in_talk_outlined,
                    color: row['is_placeholder'] == true
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  title: Text(
                    context.message(
                      row[Localizations.localeOf(context).languageCode == 'fil'
                              ? 'name_fil'
                              : 'name_en']
                          as String,
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
                    tooltip: context.l10n.edit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(row),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
