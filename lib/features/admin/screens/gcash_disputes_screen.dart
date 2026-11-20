import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import '../../../core/services/gcash_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../payment/note_dialog.dart';
import '../../tourist/screens/gcash_trip_payment.dart' show showGcashImage;

/// Queue of disputed GCash fares, escalated ones first.
class GcashDisputesScreen extends StatefulWidget {
  const GcashDisputesScreen({super.key, this.loader});

  final Future<List<GcashDispute>> Function()? loader;

  @override
  State<GcashDisputesScreen> createState() => _GcashDisputesScreenState();
}

class _GcashDisputesScreenState extends State<GcashDisputesScreen> {
  late Future<List<GcashDispute>> _disputes = _load();

  Future<List<GcashDispute>> _load() =>
      (widget.loader ?? GcashRepository.listDisputes)();

  Future<void> _refresh() async {
    setState(() => _disputes = _load());
    await _disputes;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminGcashDisputes)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<GcashDispute>>(
          future: _disputes,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                children: [
                  ListTile(
                    title: Text(
                      context.message(ErrorMessages.forError(snapshot.error!)),
                    ),
                  ),
                ],
              );
            }
            final disputes = snapshot.data;
            if (disputes == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (disputes.isEmpty) {
              return ListView(
                children: [ListTile(title: Text(l10n.adminGcashDisputesEmpty))],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: disputes.length,
              itemBuilder: (context, index) {
                final d = disputes[index];
                final status = d.unsettledNotPaid
                    ? l10n.adminDisputeUnsettled
                    : d.escalated
                    ? l10n.adminDisputeEscalated
                    : l10n.adminDisputeWaiting;
                final urgent = d.escalated || d.unsettledNotPaid;
                final tone = urgent ? AppColors.danger : AppColors.warning;
                final text = Theme.of(context).textTheme;
                return FadeSlideIn.staggered(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PressableScale(
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            await context.push(
                              '/admin/gcash-disputes/${d.bookingId}',
                            );
                            if (mounted) await _refresh();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: tone.withValues(alpha: .12),
                                  child: Icon(
                                    urgent
                                        ? Icons.priority_high_rounded
                                        : Icons.hourglass_top_rounded,
                                    color: tone,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.touristName,
                                        style: text.titleMedium,
                                      ),
                                      Text(
                                        '${d.driverName} · ${d.referenceLabel}',
                                        style: text.bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      StatusBadge(
                                        label: status,
                                        color: tone.withValues(alpha: .12),
                                        textColor: tone,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.currency(d.fareCents / 100),
                                      style: text.titleMedium,
                                    ),
                                    if (d.hasProof)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 6),
                                        child: Icon(
                                          Icons.receipt_long_outlined,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Evidence and ruling actions for one disputed GCash fare.
class GcashDisputeDetailScreen extends StatefulWidget {
  const GcashDisputeDetailScreen({
    super.key,
    required this.bookingId,
    this.loader,
    this.onRule,
    this.onWaive,
  });

  final String bookingId;
  final Future<GcashDisputeDetail> Function(String bookingId)? loader;
  final Future<void> Function(
    String bookingId,
    GcashRuling ruling,
    String reason,
  )?
  onRule;
  final Future<void> Function(String bookingId, String reason)? onWaive;

  @override
  State<GcashDisputeDetailScreen> createState() =>
      _GcashDisputeDetailScreenState();
}

class _GcashDisputeDetailScreenState extends State<GcashDisputeDetailScreen> {
  late Future<GcashDisputeDetail> _detail = _load();
  bool _busy = false;

  Future<GcashDisputeDetail> _load() =>
      (widget.loader ?? GcashRepository.detail)(widget.bookingId);

  Future<String?> _reason(String title) => showNoteDialog(
    context,
    title: title,
    label: context.l10n.adminRulingReason,
    confirmLabel: title,
    maxLength: 500,
    minLength: 5,
  );

  Future<void> _act(
    String title,
    Future<void> Function(String reason) action,
  ) async {
    final reason = await _reason(title);
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await action(reason);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.adminDecisionSaved)));
      setState(() => _detail = _load());
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
    final rule = widget.onRule ?? GcashRepository.rule;
    final waive = widget.onWaive ?? GcashRepository.waive;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminGcashDisputes)),
      body: FutureBuilder<GcashDisputeDetail>(
        future: _detail,
        builder: (context, snapshot) {
          final d = snapshot.data;
          if (d == null) {
            return Center(
              child: snapshot.hasError
                  ? Text(
                      context.message(ErrorMessages.forError(snapshot.error!)),
                    )
                  : const CircularProgressIndicator(),
            );
          }
          String time(DateTime? t) =>
              t == null ? '—' : AppFormatters.dateTime(t);
          final receipt = d.receiptPath;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              FadeSlideIn(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppFormatters.currency(d.fareCents / 100),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Divider(height: 24),
                        _Fact(l10n.gcashReferenceLabel, d.referenceNo ?? '—'),
                        _Fact(l10n.adminDriverNote, d.disputeNote ?? '—'),
                        _Fact(
                          l10n.adminEscalationNote,
                          d.escalationNote ?? '—',
                        ),
                        _Fact(l10n.adminDisputeEscalated, time(d.escalatedAt)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (receipt == null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(l10n.adminNoReceipt),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => showGcashImage(
                    context,
                    GcashRepository.receiptsBucket,
                    receipt,
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(l10n.gcashViewReceipt),
                ),
              const SizedBox(height: 20),
              if (d.ruling == null) ...[
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _act(
                          l10n.adminRulePaid,
                          (reason) =>
                              rule(widget.bookingId, GcashRuling.paid, reason),
                        ),
                  child: Text(l10n.adminRulePaid),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _act(
                          l10n.adminRuleNotPaid,
                          (reason) => rule(
                            widget.bookingId,
                            GcashRuling.notPaid,
                            reason,
                          ),
                        ),
                  child: Text(l10n.adminRuleNotPaid),
                ),
              ] else ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.gavel_rounded),
                    title: Text(switch (d.ruling!) {
                      GcashRuling.paid => l10n.gcashRulingPaid,
                      GcashRuling.notPaid => l10n.gcashRulingNotPaid,
                      GcashRuling.waived => l10n.gcashRulingWaived,
                    }),
                    subtitle: d.rulingReason == null
                        ? null
                        : Text(d.rulingReason!),
                  ),
                ),
                if (d.ruling == GcashRuling.notPaid && d.settledAt == null)
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                            l10n.adminWaiveFare,
                            (reason) => waive(widget.bookingId, reason),
                          ),
                    child: Text(l10n.adminWaiveFare),
                  ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    context.push('/admin/booking/${widget.bookingId}'),
                child: Text(l10n.booking),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        SelectableText(value),
      ],
    ),
  );
}
