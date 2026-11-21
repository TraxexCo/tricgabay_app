import 'package:flutter/material.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/services/error_messages.dart';
import '../../../core/services/gcash_repository.dart';
import '../../../core/utils/gcash_payment.dart';
import '../../tourist/screens/gcash_trip_payment.dart'
    show GcashQrView, pickGcashImage;

class DriverGcashSettingsScreen extends StatefulWidget {
  const DriverGcashSettingsScreen({
    super.key,
    required this.driverId,
    this.loader,
  });

  final String driverId;
  final Future<Map<String, dynamic>?> Function(String driverId)? loader;

  @override
  State<DriverGcashSettingsScreen> createState() => _DriverGcashSettingsState();
}

class _DriverGcashSettingsState extends State<DriverGcashSettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _repeat = TextEditingController();
  final _name = TextEditingController();
  bool _active = false;
  bool _saving = false;
  bool _loading = true;
  bool _loadFailed = false;
  bool _hasSavedDetails = false;
  String? _qrPath;

  Future<void> _uploadQr() async {
    final bytes = await pickGcashImage();
    if (bytes == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await GcashRepository.uploadDriverQr(bytes);
      final path = await GcashRepository.driverQrPath();
      if (!mounted) return;
      setState(() => _qrPath = path);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.gcashQrSaved)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final details =
          await (widget.loader ?? BackendRepository.driverGcashDetails)(
            widget.driverId,
          );
      if (!mounted) return;
      _number.text = details?['gcash_number'] as String? ?? '';
      _name.text = details?['gcash_account_name'] as String? ?? '';
      _active = details?['is_active'] == true;
      _hasSavedDetails = details != null;
      _qrPath = details?['qr_object_path'] as String?;
    } catch (_) {
      _loadFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await BackendRepository.saveDriverGcashDetails(
        number: normalizeGcashNumber(_number.text)!,
        name: _name.text.trim(),
        active: _active,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.gcashSettingsSaved)));
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.gcashActionFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _number.dispose();
    _repeat.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gcashDetails)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
          ? Center(
              child: OutlinedButton(
                onPressed: _load,
                child: Text(l10n.gcashActionFailed),
              ),
            )
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(l10n.gcashVisibility),
                  const SizedBox(height: 16),
                  TextFormField(
                    enabled: !_saving,
                    controller: _number,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: l10n.gcashNumber),
                    validator: (value) =>
                        normalizeGcashNumber(value ?? '') == null
                        ? l10n.gcashInvalidNumber
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: !_saving,
                    controller: _repeat,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.gcashConfirmNumber,
                    ),
                    validator: (value) {
                      final number = normalizeGcashNumber(value ?? '');
                      if (number == null) return l10n.gcashInvalidNumber;
                      return number == normalizeGcashNumber(_number.text)
                          ? null
                          : l10n.gcashNumberMismatch;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: !_saving,
                    controller: _name,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: l10n.gcashAccountName,
                    ),
                    validator: (value) => (value ?? '').trim().length < 2
                        ? l10n.gcashInvalidName
                        : null,
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.gcashActive),
                    value: _active,
                    onChanged: _saving
                        ? null
                        : (active) => setState(() => _active = active),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.saveChanges),
                  ),
                  // The QR needs saved details: the server attaches it to them.
                  if (_hasSavedDetails) ...[
                    const Divider(height: 40),
                    Text(
                      l10n.gcashQrTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.gcashQrDescription),
                    const SizedBox(height: 12),
                    if (_qrPath != null)
                      GcashQrView(key: ValueKey(_qrPath), path: _qrPath!),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _uploadQr,
                      icon: const Icon(Icons.qr_code_2_rounded),
                      label: Text(
                        _qrPath == null
                            ? l10n.gcashUploadQr
                            : l10n.gcashReplaceQr,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
