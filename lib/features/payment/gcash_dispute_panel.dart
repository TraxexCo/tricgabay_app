import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/services/error_messages.dart';
import '../../core/services/gcash_repository.dart';
import '../../core/utils/gcash_payment.dart';
import 'note_dialog.dart';

typedef ReceiptPicker = Future<Uint8List?> Function();

/// Shown to the tourist and driver once a GCash fare is disputed: proof,
/// escalation status, any admin ruling, and the "ask admin" action.
class GcashDisputePanel extends StatelessWidget {
  const GcashDisputePanel({
    super.key,
    required this.detail,
    required this.driver,
    required this.onSubmitProof,
    required this.onAskAdmin,
    required this.pickReceipt,
    this.onViewReceipt,
  });

  final GcashDisputeDetail detail;
  final bool driver;
  final Future<void> Function(String reference, Uint8List receipt)
  onSubmitProof;
  final Future<void> Function(String? note) onAskAdmin;
  final ReceiptPicker pickReceipt;
  final VoidCallback? onViewReceipt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ruling = detail.ruling;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ruling != null)
          _Banner(
            icon: Icons.gavel_rounded,
            text: switch (ruling) {
              GcashRuling.paid => l10n.gcashRulingPaid,
              GcashRuling.notPaid => l10n.gcashRulingNotPaid,
              GcashRuling.waived => l10n.gcashRulingWaived,
            },
            detail: detail.rulingReason,
          )
        else if (detail.escalated)
          _Banner(
            icon: Icons.support_agent_rounded,
            text: l10n.gcashEscalatedNotice,
          ),
        if (driver && (detail.disputeNote?.isNotEmpty ?? false))
          Text('${l10n.adminDriverNote}: ${detail.disputeNote}'),
        if (detail.hasProof) ...[
          if (detail.referenceNo != null)
            SelectableText(
              '${l10n.gcashReferenceLabel}: ${detail.referenceNo}',
            ),
          if (onViewReceipt != null)
            OutlinedButton.icon(
              onPressed: onViewReceipt,
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(l10n.gcashViewReceipt),
            ),
        ] else if (!driver && ruling == null)
          GcashProofForm(onSubmit: onSubmitProof, pickReceipt: pickReceipt),
        if (!detail.escalated && ruling == null)
          TextButton.icon(
            onPressed: () => _askAdmin(context),
            icon: const Icon(Icons.support_agent_rounded),
            label: Text(l10n.gcashAskAdmin),
          ),
      ],
    );
  }

  Future<void> _askAdmin(BuildContext context) async {
    final l10n = context.l10n;
    final text = await showNoteDialog(
      context,
      title: l10n.gcashAskAdmin,
      body: l10n.gcashAskAdminBody,
      label: l10n.gcashAdminNote,
      confirmLabel: l10n.gcashAskAdmin,
    );
    if (text == null || !context.mounted) return;
    try {
      await onAskAdmin(text.isEmpty ? null : text);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.gcashSentToAdmin)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    }
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, this.detail});

  final IconData icon;
  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(text),
      subtitle: detail == null ? null : Text(detail!),
    ),
  );
}

/// Receipt screenshot plus the GCash reference number, both required.
class GcashProofForm extends StatefulWidget {
  const GcashProofForm({
    super.key,
    required this.onSubmit,
    required this.pickReceipt,
  });

  final Future<void> Function(String reference, Uint8List receipt) onSubmit;
  final ReceiptPicker pickReceipt;

  @override
  State<GcashProofForm> createState() => _GcashProofFormState();
}

class _GcashProofFormState extends State<GcashProofForm> {
  final _form = GlobalKey<FormState>();
  final _reference = TextEditingController();
  Uint8List? _receipt;
  bool _busy = false;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    final bytes = await widget.pickReceipt();
    if (bytes != null && mounted) setState(() => _receipt = bytes);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _receipt == null) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(_reference.text.trim(), _receipt!);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.gcashProofSent)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.gcashProofTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(l10n.gcashProofBody),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _choose,
            icon: Icon(
              _receipt == null
                  ? Icons.add_photo_alternate_outlined
                  : Icons.check_circle_outline,
            ),
            label: Text(
              _receipt == null
                  ? l10n.gcashChooseReceipt
                  : l10n.gcashReceiptChosen,
            ),
          ),
          TextFormField(
            key: const Key('gcash-proof-reference'),
            controller: _reference,
            enabled: !_busy,
            decoration: InputDecoration(labelText: l10n.gcashReferenceRequired),
            validator: (value) {
              final text = value?.trim() ?? '';
              return text.isNotEmpty && isValidGcashReference(text)
                  ? null
                  : l10n.gcashInvalidReference;
            },
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy || _receipt == null ? null : _submit,
            child: Text(l10n.gcashSubmitProof),
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
