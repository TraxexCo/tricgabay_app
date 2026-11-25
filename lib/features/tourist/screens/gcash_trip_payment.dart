import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/session/app_session.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/services/gcash_launcher.dart';
import '../../../core/services/gcash_repository.dart';
import '../../../core/services/realtime_refresh_policy.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/gcash_payment.dart';
import '../../../core/widgets/swipe_to_confirm.dart';
import '../../../models/booking_model.dart';
import '../../payment/gcash_dispute_panel.dart';

Future<void> _refreshBookings() =>
    AppSession.syncRemoteState(sections: {RemoteSection.bookings});

Future<void> _updatePayment(
  String rpc,
  String id, [
  Map<String, dynamic> extra = const {},
]) async {
  await BackendRepository.rpc(rpc, {'p_booking_id': id, ...extra});
  await _refreshBookings();
}

/// Picks a receipt screenshot, re-encoded as JPEG to stay under the 5 MB limit.
Future<Uint8List?> pickGcashImage() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 2000,
  );
  return file?.readAsBytes();
}

Future<void> showGcashImage(
  BuildContext context,
  String bucket,
  String path,
) async {
  final url = await GcashRepository.signedUrl(bucket, path);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
    ),
  );
}

class GcashTripPayment extends StatefulWidget {
  const GcashTripPayment({
    super.key,
    required this.booking,
    required this.driver,
  });

  final BookingModel booking;
  final bool driver;

  @override
  State<GcashTripPayment> createState() => _GcashTripPaymentState();
}

class _GcashTripPaymentState extends State<GcashTripPayment> {
  Future<GcashPayee?>? _payee;
  Future<String?>? _reference;
  Future<GcashDisputeDetail>? _detail;
  bool _busy = false;
  final _note = TextEditingController();
  PaymentStatus? _lastStatus;
  String? _lastBookingId;

  bool get _disputed => widget.booking.paymentStatus == PaymentStatus.disputed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(GcashTripPayment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking != widget.booking ||
        oldWidget.driver != widget.driver) {
      _load();
    }
  }

  void _load() {
    final booking = widget.booking;
    // Dispute details change without a status change (proof, escalation),
    // so they refresh on every booking update.
    _detail = _disputed ? GcashRepository.detail(booking.id) : null;
    final changed =
        booking.paymentStatus != _lastStatus || booking.id != _lastBookingId;
    if (!changed && (_payee != null || _reference != null)) return;
    _lastStatus = booking.paymentStatus;
    _lastBookingId = booking.id;
    if (widget.driver) {
      _reference =
          booking.paymentStatus == PaymentStatus.gcashAwaitingConfirmation
          ? BackendRepository.bookingGcashReference(booking.id)
          : null;
    } else {
      _payee = GcashRepository.payee(booking.id);
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _run(
    String rpc, [
    Map<String, dynamic> params = const {},
  ]) async {
    if (_busy) throw StateError(context.l10n.gcashActionFailed);
    setState(() => _busy = true);
    try {
      await _updatePayment(rpc, widget.booking.id, params);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dispute() async {
    if (_busy) return;
    _note.clear();
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.gcashNotReceived),
        content: TextField(
          controller: _note,
          maxLength: 200,
          decoration: InputDecoration(labelText: l10n.gcashDisputeNote),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.gcashNotReceived),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _run('driver_flag_gcash_not_received', {'p_note': _note.text});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.gcashActionFailed)));
      }
    }
  }

  Widget _disputePanel() => FutureBuilder<GcashDisputeDetail>(
    future: _detail,
    builder: (context, snapshot) {
      final detail = snapshot.data;
      if (detail == null) {
        return snapshot.hasError
            ? Text(context.l10n.gcashActionFailed)
            : const LinearProgressIndicator();
      }
      final receipt = detail.receiptPath;
      return GcashDisputePanel(
        detail: detail,
        driver: widget.driver,
        pickReceipt: pickGcashImage,
        onSubmitProof: (reference, bytes) async {
          await GcashRepository.submitProof(
            widget.booking.id,
            reference,
            bytes,
          );
          await _refreshBookings();
        },
        onAskAdmin: (note) async {
          await GcashRepository.requestAdminReview(
            widget.booking.id,
            note: note,
          );
          if (mounted) {
            setState(() => _detail = GcashRepository.detail(widget.booking.id));
          }
        },
        onViewReceipt: receipt == null
            ? null
            : () => showGcashImage(
                context,
                GcashRepository.receiptsBucket,
                receipt,
              ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.driver) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.booking.paymentStatus ==
              PaymentStatus.gcashAwaitingConfirmation)
            Text(l10n.gcashAwaitingYour),
          if (_reference != null)
            FutureBuilder<String?>(
              future: _reference,
              builder: (context, snapshot) => switch (snapshot) {
                AsyncSnapshot(hasError: true) => Text(l10n.gcashActionFailed),
                AsyncSnapshot(
                  connectionState: ConnectionState.done,
                  data: final String reference,
                ) =>
                  Text('${l10n.gcashReference}\n$reference'),
                _ => const SizedBox.shrink(),
              },
            ),
          if (_disputed) _disputePanel(),
          Text(l10n.gcashCheckWallet),
          const SizedBox(height: 8),
          SwipeToConfirm(
            text: l10n.gcashSlide,
            accessibilityLabel: l10n.gcashDriverConfirm,
            errorText: l10n.gcashActionFailed,
            enabled: !_busy,
            onConfirmAsync: () => _run('driver_confirm_gcash_received'),
          ),
          if (!_disputed) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _dispute,
              child: Text(l10n.gcashNotReceived),
            ),
          ],
        ],
      );
    }
    return FutureBuilder<GcashPayee?>(
      future: _payee,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return OutlinedButton(
            onPressed: () => setState(
              () => _payee = GcashRepository.payee(widget.booking.id),
            ),
            child: Text(l10n.gcashActionFailed),
          );
        }
        final payee = snapshot.data;
        final qrPath = payee?.qrPath;
        return GcashTouristPayment(
          accountName: payee?.accountName,
          number: payee?.number,
          fareCents: payee?.fareCents,
          status: widget.booking.paymentStatus,
          qr: qrPath == null ? null : GcashQrView(path: qrPath),
          disputePanel: _disputed ? _disputePanel() : null,
          openGcash: const GcashLauncher().openGcash,
          onSent: (reference) =>
              _run('tourist_mark_gcash_sent', {'p_reference_no': reference}),
          onCash: () => _run('tourist_switch_gcash_to_cash'),
        );
      },
    );
  }
}

/// The driver's GCash QR with a share/save action. GCash can scan a QR
/// image from the gallery via Scan QR → Upload QR.
class GcashQrView extends StatefulWidget {
  const GcashQrView({super.key, required this.path});

  final String path;

  @override
  State<GcashQrView> createState() => _GcashQrViewState();
}

class _GcashQrViewState extends State<GcashQrView> {
  late final Future<Uint8List> _bytes = GcashRepository.download(
    GcashRepository.qrBucket,
    widget.path,
  );

  Future<void> _share(Uint8List bytes) async {
    final png = widget.path.endsWith('.png');
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: png ? 'image/png' : 'image/jpeg'),
        ],
        fileNameOverrides: [png ? 'gcash-qr.png' : 'gcash-qr.jpg'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return snapshot.hasError
              ? Text(l10n.gcashQrMissing)
              : const LinearProgressIndicator();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.gcashQrTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 240,
                  maxHeight: 240,
                ),
                child: Image.memory(bytes, semanticLabel: l10n.gcashQrTitle),
              ),
            ),
            Text(
              l10n.gcashQrHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            OutlinedButton.icon(
              onPressed: () => _share(bytes),
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(l10n.gcashSaveQr),
            ),
          ],
        );
      },
    );
  }
}

class GcashTouristPayment extends StatefulWidget {
  const GcashTouristPayment({
    super.key,
    required this.accountName,
    required this.number,
    required this.fareCents,
    required this.status,
    required this.openGcash,
    required this.onSent,
    required this.onCash,
    this.qr,
    this.disputePanel,
  });

  final String? accountName;
  final String? number;
  final int? fareCents;
  final PaymentStatus status;
  final Future<bool> Function() openGcash;
  final Future<void> Function(String) onSent;
  final Future<void> Function() onCash;

  /// The driver's QR, when they uploaded one.
  final Widget? qr;

  /// Proof / escalation panel, shown instead of "I've paid" once disputed.
  final Widget? disputePanel;

  @override
  State<GcashTouristPayment> createState() => _GcashTouristPaymentState();
}

class _GcashTouristPaymentState extends State<GcashTouristPayment> {
  final _form = GlobalKey<FormState>();
  final _reference = TextEditingController();
  bool _busy = false;
  bool _launchFailed = false;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) _notice(context.l10n.gcashActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _copy(String value, String label) => _run(() async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) _notice(label);
  });

  Future<void> _chooseCash() => _run(() async {
    if (widget.status == PaymentStatus.disputed ||
        widget.status == PaymentStatus.gcashAwaitingConfirmation) {
      final l10n = context.l10n;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.gcashPayCash),
          content: Text(l10n.gcashCashWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.gcashPayCash),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await widget.onCash();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final number = widget.number;
    final cents = widget.fareCents;
    final disputed = widget.status == PaymentStatus.disputed;
    if (number == null || cents == null || widget.accountName == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (disputed) Text(l10n.gcashDisputeMessage),
          if (widget.disputePanel != null) widget.disputePanel!,
          Text(l10n.gcashNotSetUp),
          FilledButton(
            onPressed: _busy ? null : _chooseCash,
            child: Text(l10n.gcashPayCash),
          ),
        ],
      );
    }

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.gcashFareToPay),
          Text(
            AppFormatters.currency(cents / 100),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (widget.qr != null) ...[
            const SizedBox(height: 8),
            widget.qr!,
            const SizedBox(height: 8),
          ],
          Text(l10n.gcashAccountName),
          SelectableText(widget.accountName!),
          Text(l10n.gcashNumber),
          SelectableText(number),
          Text(l10n.gcashCheckName),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final opened = await widget.openGcash();
                    if (mounted) setState(() => _launchFailed = !opened);
                  }),
            child: Text(l10n.gcashOpen),
          ),
          if (_launchFailed)
            Semantics(liveRegion: true, child: Text(l10n.gcashLaunchFailed)),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _copy(number, l10n.gcashNumberCopied),
                child: Text(l10n.gcashCopyNumber),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _copy(
                        AppFormatters.decimalInput(cents / 100),
                        l10n.gcashAmountCopied,
                      ),
                child: Text(l10n.gcashCopyAmount),
              ),
            ],
          ),
          if (disputed) ...[
            Text(l10n.gcashDisputeMessage),
            if (widget.disputePanel != null) widget.disputePanel!,
          ] else ...[
            if (widget.status == PaymentStatus.gcashAwaitingConfirmation)
              Text(l10n.gcashAwaitingDriver),
            TextFormField(
              controller: _reference,
              enabled: !_busy,
              decoration: InputDecoration(labelText: l10n.gcashReference),
              validator: (value) => isValidGcashReference(value ?? '')
                  ? null
                  : l10n.gcashInvalidReference,
            ),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () {
                      if (_form.currentState!.validate()) {
                        _run(() => widget.onSent(_reference.text.trim()));
                      }
                    },
              child: Text(l10n.gcashSent),
            ),
          ],
          TextButton(
            onPressed: _busy ? null : _chooseCash,
            child: Text(l10n.gcashPayCash),
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
