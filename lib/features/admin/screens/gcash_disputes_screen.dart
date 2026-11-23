import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/backend_config.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import '../../../core/services/gcash_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/widgets/list_skeleton.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../widgets/admin_ui.dart';
import '../../payment/note_dialog.dart';
import '../../tourist/screens/gcash_trip_payment.dart' show showGcashImage;

/// Queue of disputed GCash fares, escalated ones first.
class GcashDisputesScreen extends StatefulWidget {
  const GcashDisputesScreen({super.key, this.loader});

  final Future<List<GcashDispute>> Function()? loader;

  /// Loads the queue in the background so the screen opens with data.
  static Future<void> prefetch() async {
    if (!BackendConfig.isConfigured) return;
    try {
      _disputeCache = await GcashRepository.listDisputes();
    } catch (_) {
      // The screen loads again and shows any error.
    }
  }

  @override
  State<GcashDisputesScreen> createState() => _GcashDisputesScreenState();
}

/// Last queue seen, shown at once on the next visit while it refreshes.
List<GcashDispute>? _disputeCache;

class _GcashDisputesScreenState extends State<GcashDisputesScreen> {
  late List<GcashDispute>? _disputes = widget.loader == null
      ? _disputeCache
      : null;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final rows = await (widget.loader ?? GcashRepository.listDisputes)();
      if (widget.loader == null) _disputeCache = rows;
      if (mounted) {
        setState(() {
          _disputes = rows;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final disputes = _disputes;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminGcashDisputes)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: () {
          if (disputes == null && _error != null) {
            return ScrollableEmptyState(
              icon: Icons.cloud_off_rounded,
              title: context.message(ErrorMessages.forError(_error!)),
              subtitle: l10n.pullDownToTryAgain,
            );
          }
          if (disputes == null) return const ListSkeleton();
          if (disputes.isEmpty) {
            return ScrollableEmptyState(
              icon: Icons.verified_rounded,
              title: l10n.adminGcashDisputesEmpty,
              subtitle: l10n.adminGcashDisputesEmptyBody,
            );
          }
          final urgent = disputes
              .where((d) => d.escalated || d.unsettledNotPaid)
              .length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  l10n.disputesSummaryValue(
                    disputes.length.toString(),
                    urgent.toString(),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final (index, d) in disputes.indexed)
                FadeSlideIn.staggered(index: index, child: _card(context, d)),
            ],
          );
        }(),
      ),
    );
  }

  Widget _card(BuildContext context, GcashDispute d) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final status = d.unsettledNotPaid
        ? l10n.adminDisputeUnsettled
        : d.escalated
        ? l10n.adminDisputeEscalated
        : l10n.adminDisputeWaiting;
    final urgent = d.escalated || d.unsettledNotPaid;
    final tone = urgent ? AppColors.danger : AppColors.warning;
    final since = d.escalatedAt ?? d.disputedAt;
    return AdminPanel(
      borderColor: urgent ? tone.withValues(alpha: .4) : AppColors.border,
      onTap: () async {
        await context.push('/admin/gcash-disputes/${d.bookingId}');
        if (mounted) await _refresh();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                urgent
                    ? Icons.priority_high_rounded
                    : Icons.hourglass_top_rounded,
                tone,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.touristName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.disputeDriverValue(d.driverName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppFormatters.currency(d.fareCents / 100),
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            d.referenceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(
                label: status,
                color: tone.withValues(alpha: .12),
                textColor: tone,
              ),
              if (d.hasProof)
                StatusBadge(
                  label: l10n.disputeReceiptAttached,
                  color: AppColors.primary.withValues(alpha: .1),
                  textColor: AppColors.primary,
                ),
              if (since != null)
                Text(
                  AppFormatters.dateTime(since),
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
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
    String done,
    Future<void> Function(String reason) action,
  ) async {
    final reason = await _reason(title);
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await action(reason);
      if (!mounted) return;
      showAdminToast(context, done);
      setState(() => _detail = _load());
    } catch (error) {
      if (mounted) {
        showAdminToast(context, ErrorMessages.forError(error), error: true);
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
    return FutureBuilder<GcashDisputeDetail>(
      future: _detail,
      builder: (context, snapshot) {
        final d = snapshot.data;
        if (d == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.disputeDetailTitle)),
            body: snapshot.hasError
                ? EmptyStateWidget(
                    icon: Icons.cloud_off_rounded,
                    title: context.message(
                      ErrorMessages.forError(snapshot.error!),
                    ),
                  )
                : const ListSkeleton(),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.disputeDetailTitle)),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _actions(context, d, rule, waive),
              ),
            ),
          ),
          body: Builder(
            builder: (context) {
              final text = Theme.of(context).textTheme;
              String time(DateTime? t) =>
                  t == null ? '—' : AppFormatters.dateTime(t);
              final receipt = d.receiptPath;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  FadeSlideIn(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.disputedFare,
                            style: text.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            AppFormatters.currency(d.fareCents / 100),
                            style: text.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d.ruling == null
                                ? (d.escalated
                                      ? l10n.adminDisputeEscalated
                                      : l10n.adminDisputeWaiting)
                                : _rulingLabel(context, d.ruling!),
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (receipt == null)
                    AdminPanel(
                      child: Row(
                        children: [
                          const IconTile(
                            Icons.receipt_long_outlined,
                            AppColors.textSecondary,
                            size: 38,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(l10n.adminNoReceipt)),
                        ],
                      ),
                    )
                  else
                    AdminPanel(
                      onTap: () => showGcashImage(
                        context,
                        GcashRepository.receiptsBucket,
                        receipt,
                      ),
                      child: Row(
                        children: [
                          const IconTile(
                            Icons.receipt_long_outlined,
                            AppColors.primary,
                            size: 38,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.gcashViewReceipt,
                              style: text.titleSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.open_in_full_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  AdminPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminSectionTitle(l10n.disputeWhatWeKnow),
                        _Fact(l10n.gcashReferenceLabel, d.referenceNo ?? '—'),
                        _Fact(l10n.adminDriverNote, d.disputeNote ?? '—'),
                        _Fact(
                          l10n.adminEscalationNote,
                          d.escalationNote ?? '—',
                        ),
                        _Fact(l10n.adminEscalatedOn, time(d.escalatedAt)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () =>
                        context.push('/admin/booking/${widget.bookingId}'),
                    icon: const Icon(Icons.receipt_outlined),
                    label: Text(l10n.openBookingDetails),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _actions(
    BuildContext context,
    GcashDisputeDetail d,
    Future<void> Function(String, GcashRuling, String) rule,
    Future<void> Function(String, String) waive,
  ) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return [
      if (d.ruling == null) ...[
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: _busy
              ? null
              : () => _act(
                  l10n.adminRulePaid,
                  l10n.disputeRuledPaidToast,
                  (reason) => rule(widget.bookingId, GcashRuling.paid, reason),
                ),
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: Text(l10n.adminRulePaid),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: _busy
              ? null
              : () => _act(
                  l10n.adminRuleNotPaid,
                  l10n.disputeRuledNotPaidToast,
                  (reason) =>
                      rule(widget.bookingId, GcashRuling.notPaid, reason),
                ),
          icon: const Icon(Icons.cancel_outlined),
          label: Text(l10n.adminRuleNotPaid),
        ),
      ] else ...[
        AdminPanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(Icons.gavel_rounded, AppColors.primary, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _rulingLabel(context, d.ruling!),
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (d.rulingReason != null) Text(d.rulingReason!),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (d.ruling == GcashRuling.notPaid && d.settledAt == null)
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _busy
                ? null
                : () => _act(
                    l10n.adminWaiveFare,
                    l10n.disputeWaivedToast,
                    (reason) => waive(widget.bookingId, reason),
                  ),
            child: Text(l10n.adminWaiveFare),
          ),
      ],
    ];
  }

  String _rulingLabel(BuildContext context, GcashRuling ruling) =>
      switch (ruling) {
        GcashRuling.paid => context.l10n.gcashRulingPaid,
        GcashRuling.notPaid => context.l10n.gcashRulingNotPaid,
        GcashRuling.waived => context.l10n.gcashRulingWaived,
      };
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
