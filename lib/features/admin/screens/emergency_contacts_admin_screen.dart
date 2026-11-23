import 'package:flutter/material.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

import '../../../core/config/backend_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/error_messages.dart';
import '../../../core/widgets/list_skeleton.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../widgets/admin_ui.dart';

/// Local emergency numbers shown to tourists and drivers. A number only goes
/// live after the admin confirms they checked it with the agency.
class EmergencyContactsAdminScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function()? loader;
  const EmergencyContactsAdminScreen({super.key, this.loader});

  static List<Map<String, dynamic>>? _cache;

  static Future<List<Map<String, dynamic>>> _fetch() async =>
      _cache = List<Map<String, dynamic>>.from(
        await BackendConfig.client
            .from('emergency_contacts')
            .select()
            .order('priority'),
      );

  /// Loads the list in the background so the screen opens instantly.
  static Future<void> prefetch() async {
    if (!BackendConfig.isConfigured) return;
    try {
      await _fetch();
    } catch (_) {
      // The screen loads again and shows any error.
    }
  }

  @override
  State<EmergencyContactsAdminScreen> createState() =>
      _EmergencyContactsAdminScreenState();
}

class _EmergencyContactsAdminScreenState
    extends State<EmergencyContactsAdminScreen> {
  List<Map<String, dynamic>>? _rows;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.loader == null) _rows = EmergencyContactsAdminScreen._cache;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final rows = widget.loader != null
          ? await widget.loader!()
          : await EmergencyContactsAdminScreen._fetch();
      if (mounted) {
        setState(() {
          _rows = rows;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  String _name(Map<String, dynamic> row) => context.message(
    row[Localizations.localeOf(context).languageCode == 'fil'
                ? 'name_fil'
                : 'name_en']
            as String? ??
        '',
  );

  Future<void> _edit(Map<String, dynamic> row) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContactForm(row: row),
    );
    if (saved == true && mounted) {
      showAdminToast(context, context.l10n.emergencyContactSavedToast);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rows = _rows;
    return Scaffold(
      appBar: AppBar(title: Text(l.emergencyContactsSettings)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: () {
          if (rows == null && _error != null) {
            return ScrollableEmptyState(
              icon: Icons.cloud_off_rounded,
              title: context.message(ErrorMessages.forError(_error!)),
              subtitle: l.pullDownToTryAgain,
            );
          }
          if (rows == null) return const ListSkeleton();
          if (rows.isEmpty) {
            return ScrollableEmptyState(
              icon: Icons.local_hospital_outlined,
              title: l.emergencyContactsEmpty,
            );
          }
          final missing = rows.where((r) => r['is_placeholder'] == true).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              AdminPanel(
                color: missing > 0
                    ? AppColors.warningLight
                    : AppColors.successLight.withValues(alpha: .6),
                borderColor: missing > 0
                    ? AppColors.warning.withValues(alpha: .3)
                    : AppColors.successLight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      missing > 0
                          ? Icons.warning_amber_rounded
                          : Icons.verified_rounded,
                      color: missing > 0
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        missing > 0
                            ? l.emergencyNumbersMissingValue(missing.toString())
                            : l.emergencyNumbersAllSet,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              for (final row in rows) _card(context, row),
            ],
          );
        }(),
      ),
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> row) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final placeholder = row['is_placeholder'] == true;
    final active = row['is_active'] != false;
    final tone = placeholder ? AppColors.warning : AppColors.success;
    return AdminPanel(
      onTap: () => _edit(row),
      child: Row(
        children: [
          IconTile(
            placeholder
                ? Icons.phone_disabled_outlined
                : Icons.phone_in_talk_outlined,
            tone,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name(row),
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  placeholder
                      ? l.emergencyNumberNotSet
                      : context.message(row['phone'] as String? ?? ''),
                  style: placeholder
                      ? text.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        )
                      : text.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .3,
                        ),
                ),
                if (!active)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: StatusBadge(
                      label: l.hidden,
                      color: AppColors.textSecondary.withValues(alpha: .12),
                      textColor: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: l.edit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => _edit(row),
          ),
        ],
      ),
    );
  }
}

class _ContactForm extends StatefulWidget {
  const _ContactForm({required this.row});
  final Map<String, dynamic> row;

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  late final _phone = TextEditingController(
    text: widget.row['phone'] as String? ?? '',
  );
  late final _english = TextEditingController(
    text: widget.row['name_en'] as String? ?? '',
  );
  late final _filipino = TextEditingController(
    text: widget.row['name_fil'] as String? ?? '',
  );
  bool _verified = false, _busy = false, _tried = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _english.dispose();
    _filipino.dispose();
    super.dispose();
  }

  bool get _needsCheck => _phone.text.trim().isNotEmpty && !_verified;
  bool get _namesMissing =>
      _english.text.trim().isEmpty || _filipino.text.trim().isEmpty;

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_needsCheck || _namesMissing) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (BackendConfig.isConfigured) {
        await BackendConfig.client.rpc(
          'update_emergency_contact',
          params: {
            'p_id': widget.row['id'],
            'p_phone': _phone.text,
            'p_name_en': _english.text,
            'p_name_fil': _filipino.text,
          },
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = context.message(ErrorMessages.forError(error));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    InputDecoration field(String label, IconData icon, {String? error}) =>
        InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          errorText: error,
        );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminSectionTitle(l.emergencyContact),
            TextField(
              controller: _english,
              enabled: !_busy,
              onChanged: (_) => setState(() {}),
              decoration: field(
                l.englishName,
                Icons.translate_rounded,
                error: _tried && _english.text.trim().isEmpty
                    ? l.fieldRequired
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _filipino,
              enabled: !_busy,
              onChanged: (_) => setState(() {}),
              decoration: field(
                l.filipinoName,
                Icons.translate_rounded,
                error: _tried && _filipino.text.trim().isEmpty
                    ? l.fieldRequired
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              enabled: !_busy,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: field(l.phoneNumber, Icons.call_outlined).copyWith(
                helperText:
                    l.leaveTheNumberEmptyToKeepAClearlyMarkedPlaceholder,
                helperMaxLines: 3,
              ),
            ),
            if (_phone.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Material(
                color: _tried && _needsCheck
                    ? AppColors.dangerLight
                    : AppColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: CheckboxListTile(
                  value: _verified,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _verified = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l.iVerifiedThisNumberWithTheAgency),
                  subtitle: _tried && _needsCheck
                      ? Text(
                          l.emergencyConfirmFirst,
                          style: const TextStyle(color: AppColors.danger),
                        )
                      : null,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _busy ? null : _save,
              child: Text(_busy ? l.saving : l.saveChanges),
            ),
          ],
        ),
      ),
    );
  }
}
