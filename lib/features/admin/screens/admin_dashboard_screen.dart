import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:tricgabay_app/core/utils/formatters.dart';

import '../../../core/config/backend_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/record_labels.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/services/error_messages.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/account_widgets.dart';
import '../../../core/widgets/language_selection.dart';
import '../../../models/booking_model.dart';
import '../widgets/admin_ui.dart';
import 'emergency_contacts_admin_screen.dart';
import 'gcash_disputes_screen.dart';

/// Admin home: what needs a decision first, then today's numbers, then
/// shortcuts to every admin tool.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  /// Kept between visits so the badge shows at once when coming back.
  static int _pendingDataRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadDataRequestCount();
    // Warm the slower admin lists so they open with data.
    if (AppSession.hasAdminCapability('operations')) {
      EmergencyContactsAdminScreen.prefetch();
    }
    if (AppSession.hasAdminCapability('finance') ||
        AppSession.hasAdminCapability('operations')) {
      GcashDisputesScreen.prefetch();
    }
  }

  Future<void> _loadDataRequestCount() async {
    if (!BackendConfig.isConfigured ||
        !AppSession.hasAdminCapability('support')) {
      return;
    }
    try {
      final count = await BackendRepository.pendingDataRequestCount();
      if (mounted) setState(() => _pendingDataRequests = count);
    } catch (_) {
      // Only a badge; the screen itself shows any error.
    }
  }

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) _loadDataRequestCount();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ValueListenableBuilder<List<BookingModel>>(
        valueListenable: AppSession.bookings,
        builder: (context, bookings, _) =>
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: AppSession.adminDrivers,
              builder: (context, drivers, _) =>
                  ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: AppSession.operationalAlerts,
                    builder: (context, alerts, _) =>
                        _body(context, bookings, drivers, alerts),
                  ),
            ),
      ),
    ),
  );

  Widget _body(
    BuildContext context,
    List<BookingModel> bookings,
    List<Map<String, dynamic>> drivers,
    List<Map<String, dynamic>> alerts,
  ) {
    final l = context.l10n;
    final can = AppSession.hasAdminCapability;
    final money = can('finance') || can('operations');

    final disputes = bookings.where(isOpenGcashDispute).length;
    final reviews = bookings
        .where((b) => needsPaymentReview(b) && !isOpenGcashDispute(b))
        .length;
    final pendingDrivers = drivers
        .where((d) => d['status'] == 'pending')
        .length;
    final activeDrivers = drivers.where((d) => d['status'] == 'active').length;
    final onTrip = bookings
        .where((b) => b.status == BookingStatus.ongoing)
        .length;
    final today = DateTime.now().subtract(const Duration(days: 1));
    final todayBookings = bookings
        .where((b) => b.createdAt.isAfter(today))
        .length;
    final settled = bookings.where(
      (b) => !b.isActive && !b.trip.reviewRequired && b.refundDueCents == 0,
    );
    final revenue = settled.fold<double>(
      0,
      (sum, b) => sum + b.trip.receivedCents / 100,
    );
    final accounts = drivers.length + AppSession.adminTourists.value.length;
    final showAlerts = can('operations') && alerts.isNotEmpty;

    final attention = <_AttentionItem>[
      if (showAlerts)
        _AttentionItem(
          icon: Icons.notification_important_outlined,
          color: AppColors.danger,
          title: l.dashSystemAlerts,
          body: l.operationalAlertSNeedReviewValue(alerts.length.toString()),
          count: alerts.length,
          onTap: () => _openAlerts(alerts),
        ),
      if (money && disputes > 0)
        _AttentionItem(
          icon: Icons.gavel_rounded,
          color: AppColors.danger,
          title: l.adminGcashDisputes,
          body: l.dashWaitingForDecisionValue(disputes.toString()),
          count: disputes,
          onTap: () => _open('/admin/gcash-disputes'),
        ),
      if (money && reviews > 0)
        _AttentionItem(
          icon: Icons.fact_check_outlined,
          color: AppColors.warning,
          title: l.dashPaymentReviews,
          body: l.dashBookingsToCheckValue(reviews.toString()),
          count: reviews,
          onTap: () => _open('/admin/bookings'),
        ),
      if (can('driver_compliance') && pendingDrivers > 0)
        _AttentionItem(
          icon: Icons.badge_outlined,
          color: AppColors.warning,
          title: l.reviewPendingDrivers,
          body: l.documentsAreWaitingForVerificationValue(
            pendingDrivers.toString(),
          ),
          count: pendingDrivers,
          onTap: () => context.go('/admin/drivers'),
        ),
      if (can('support') && _pendingDataRequests > 0)
        _AttentionItem(
          icon: Icons.download_outlined,
          color: AppColors.primary,
          title: l.dataExportRequests,
          body: l.dashExportsToPrepareValue(_pendingDataRequests.toString()),
          count: _pendingDataRequests,
          onTap: () => _open('/admin/data-requests'),
        ),
    ];

    final tools = <_Tool>[
      if (money)
        _Tool(
          Icons.fact_check_outlined,
          l.dashPaymentReviews,
          AppColors.primary,
          '/admin/bookings',
          reviews,
        ),
      if (money)
        _Tool(
          Icons.gavel_rounded,
          l.adminGcashDisputes,
          AppColors.danger,
          '/admin/gcash-disputes',
          disputes,
        ),
      if (can('content'))
        _Tool(
          Icons.tour_outlined,
          l.tourPackages,
          AppColors.primary,
          '/admin/packages',
          0,
        ),
      if (can('operations'))
        _Tool(
          Icons.map_outlined,
          l.dashLiveMap,
          AppColors.success,
          '/admin/live-map',
          0,
        ),
      if (can('support')) ...[
        _Tool(
          Icons.people_outline_rounded,
          l.dashTourists,
          AppColors.success,
          '/admin/tourists',
          0,
        ),
        _Tool(
          Icons.campaign_outlined,
          l.dashAnnouncements,
          AppColors.warning,
          '/admin/announcements',
          0,
        ),
        _Tool(
          Icons.forum_outlined,
          l.ratingsFeedback,
          AppColors.secondaryDark,
          '/admin/ratings',
          0,
        ),
        _Tool(
          Icons.download_outlined,
          l.dashDataRequests,
          AppColors.primary,
          '/admin/data-requests',
          _pendingDataRequests,
        ),
      ],
      if (can('operations'))
        _Tool(
          Icons.local_hospital_outlined,
          l.dashEmergencyNumbers,
          AppColors.danger,
          '/admin/emergency-contacts',
          0,
        ),
      if (can('finance'))
        _Tool(
          Icons.payments_outlined,
          l.dashFares,
          AppColors.success,
          '/admin/fare-settings',
          0,
        ),
    ];

    final recent = bookings.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          AppSession.syncRemoteState(),
          _loadDataRequestCount(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          _header(context),
          const SizedBox(height: 14),
          AccountIdentityCard(roleLabel: l.administrator),
          const SizedBox(height: 24),
          AdminSectionTitle(l.dashNeedsAttention),
          if (attention.isEmpty)
            AdminPanel(
              color: AppColors.successLight.withValues(alpha: .5),
              borderColor: AppColors.successLight,
              child: Row(
                children: [
                  const IconTile(
                    Icons.task_alt_rounded,
                    AppColors.success,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.dashAllClear,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          l.dashAllClearBody,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            for (final item in attention) _attentionRow(item),
          const SizedBox(height: 14),
          _liveCard(context, activeDrivers, onTrip),
          const SizedBox(height: 24),
          AdminSectionTitle(l.dashAtAGlance),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _stat(
                    todayBookings.toString(),
                    l.bookingsToday,
                    Icons.receipt_long_outlined,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _stat(
                    AppFormatters.currencyShort(revenue),
                    l.dashReceived,
                    Icons.payments_outlined,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _stat(
                    NumberFormat.compact(
                      locale: AppFormatters.resolvedLocale(null),
                    ).format(accounts),
                    l.dashAccounts,
                    Icons.people_outline_rounded,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (tools.isNotEmpty) ...[
            AdminSectionTitle(l.dashTools),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 560 ? 4 : 3;
                final width =
                    (constraints.maxWidth - 10 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final tool in tools)
                      SizedBox(width: width, child: _toolTile(tool)),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          AdminSectionTitle(
            l.recentBookings,
            trailing: money
                ? TextButton(
                    onPressed: () => _open('/admin/bookings'),
                    child: Text(l.viewAll),
                  )
                : null,
          ),
          if (recent.isEmpty)
            AdminPanel(
              child: Row(
                children: [
                  const IconTile(
                    Icons.inbox_outlined,
                    AppColors.textSecondary,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.noRecentBookings,
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final b in recent.take(4)) _bookingRow(context, b, money),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.operationsCentre,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              context.message(AppFormatters.weekdayDate(DateTime.now())),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: context.l10n.language,
        icon: const Icon(Icons.language),
        onPressed: () => showModalBottomSheet(
          context: context,
          builder: (_) => const LanguageSelection(),
        ),
      ),
      IconButton(
        tooltip: context.l10n.logOut,
        onPressed: () async {
          await AppSession.signOut();
          if (context.mounted) context.go('/login');
        },
        icon: const Icon(Icons.logout_rounded),
      ),
    ],
  );

  Widget _attentionRow(_AttentionItem item) => AdminPanel(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
    borderColor: item.color.withValues(alpha: .35),
    onTap: item.onTap,
    child: Row(
      children: [
        IconTile(item.icon, item.color, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                item.body,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        CountBadge(item.count, color: item.color),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      ],
    ),
  );

  Widget _liveCard(BuildContext context, int active, int onTrip) {
    final card = Ink(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102A43), Color(0xFF1B6CA8)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.radar_rounded,
              color: Color(0xFF8DE2C1),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.driversActiveValue(active.toString()),
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.areCurrentlyOnATripValue(onTrip.toString()),
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
          ),
          if (AppSession.hasAdminCapability('operations'))
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ),
    );
    if (!AppSession.hasAdminCapability('operations')) return card;
    return InkWell(
      onTap: () => _open('/admin/live-map'),
      borderRadius: BorderRadius.circular(22),
      child: card,
    );
  }

  Widget _stat(String value, String label, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _toolTile(_Tool tool) => Material(
    color: AppColors.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      onTap: () => _open(tool.route),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconTile(tool.icon, tool.color, size: 44),
                Positioned(top: -8, right: -12, child: CountBadge(tool.count)),
              ],
            ),
            const SizedBox(height: 8),
            // Room for two lines always, so tiles in a row match.
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(12) * 1.25 * 2 + 2,
              child: Text(
                tool.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _bookingRow(BuildContext context, BookingModel b, bool canOpen) {
    final color = switch (b.status) {
      BookingStatus.completed => AppColors.success,
      BookingStatus.pending => AppColors.warning,
      BookingStatus.ongoing => AppColors.primary,
      BookingStatus.cancelled => AppColors.danger,
      _ => AppColors.textSecondary,
    };
    return AdminPanel(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: canOpen ? () => _open('/admin/booking/${b.id}') : null,
      child: Row(
        children: [
          const IconTile(
            Icons.electric_rickshaw_outlined,
            AppColors.primary,
            size: 36,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.message(AppSession.bookingTitle(b)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  context.l10n.twoPartSummary(
                    AppFormatters.bookingId(b.id),
                    b.touristName,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              bookingStatusLabel(context, b.status),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Operational alerts ────────────────────────────────────────────────

  Future<void> _openAlerts(List<Map<String, dynamic>> alerts) async {
    // All alerts point to the same place: go straight there.
    final routes = alerts.map(_alertRoute).toSet();
    if (routes.length == 1 && routes.first != null) {
      await _open(routes.first!);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AlertsSheet(onOpen: _open),
    );
  }
}

enum _AlertKind { payment, driverStale, location, notifications, jobs, other }

_AlertKind _alertKind(Map<String, dynamic> alert) {
  final metadata = alert['metadata'];
  final metric = metadata is Map ? metadata['metric'] : null;
  final category = alert['category'];
  if (category == 'payment' ||
      metric == 'failed_payments' ||
      metric == 'blocked_expiry') {
    return _AlertKind.payment;
  }
  if (category == 'dispatch' || metric == 'stale_online_drivers') {
    return _AlertKind.driverStale;
  }
  if (category == 'location') return _AlertKind.location;
  if (metric == 'notification_failures') return _AlertKind.notifications;
  if (metric == 'cron_failures') return _AlertKind.jobs;
  return _AlertKind.other;
}

/// The driver an alert is about, from keys like `mock-location:<id>`.
String? _alertDriverId(Map<String, dynamic> alert) {
  final key = alert['dedupe_key'] as String? ?? '';
  final split = key.indexOf(':');
  if (split < 0 || key.startsWith('health:')) return null;
  final id = key.substring(split + 1);
  return RegExp(r'^[0-9a-f-]{36}$').hasMatch(id) ? id : null;
}

/// Where the admin can fix what the alert is about, or null when it is a
/// system problem with no screen of its own.
String? _alertRoute(Map<String, dynamic> alert) {
  switch (_alertKind(alert)) {
    case _AlertKind.payment:
      return AppSession.hasAdminCapability('finance') ||
              AppSession.hasAdminCapability('operations')
          ? '/admin/gcash-disputes'
          : null;
    case _AlertKind.driverStale:
    case _AlertKind.location:
      final driver = _alertDriverId(alert);
      if (driver != null &&
          AppSession.hasAdminCapability('driver_compliance')) {
        return '/admin/drivers/$driver';
      }
      return '/admin/live-map';
    case _AlertKind.notifications:
    case _AlertKind.jobs:
    case _AlertKind.other:
      return null;
  }
}

class _AlertsSheet extends StatefulWidget {
  const _AlertsSheet({required this.onOpen});

  final Future<void> Function(String route) onOpen;

  @override
  State<_AlertsSheet> createState() => _AlertsSheetState();
}

class _AlertsSheetState extends State<_AlertsSheet> {
  String? _busy;

  Future<void> _resolve(Map<String, dynamic> alert) async {
    final id = alert['id'] as String?;
    if (id == null || _busy != null) return;
    setState(() => _busy = id);
    try {
      if (BackendConfig.isConfigured) {
        await BackendRepository.resolveOperationalAlert(id);
      }
      AppSession.operationalAlerts.value = [
        for (final a in AppSession.operationalAlerts.value)
          if (a['id'] != id) a,
      ];
      if (!mounted) return;
      showAdminToast(context, context.l10n.alertResolvedToast);
      if (AppSession.operationalAlerts.value.isEmpty) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        showAdminToast(context, ErrorMessages.forError(error), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  String _title(BuildContext context, _AlertKind kind) => switch (kind) {
    _AlertKind.payment => context.l10n.alertKindPayment,
    _AlertKind.driverStale => context.l10n.alertKindDriverStale,
    _AlertKind.location => context.l10n.alertKindLocation,
    _AlertKind.notifications => context.l10n.alertKindNotifications,
    _AlertKind.jobs => context.l10n.alertKindJobs,
    _AlertKind.other => context.l10n.alertKindOther,
  };

  IconData _icon(_AlertKind kind) => switch (kind) {
    _AlertKind.payment => Icons.payments_outlined,
    _AlertKind.driverStale => Icons.location_off_outlined,
    _AlertKind.location => Icons.wrong_location_outlined,
    _AlertKind.notifications => Icons.notifications_off_outlined,
    _AlertKind.jobs => Icons.schedule_outlined,
    _AlertKind.other => Icons.report_gmailerrorred_outlined,
  };

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: AppSession.operationalAlerts,
        builder: (context, alerts, _) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              AdminSectionTitle(context.l10n.dashSystemAlerts),
              for (final alert in alerts) _alert(context, alert),
            ],
          ),
        ),
      );

  Widget _alert(BuildContext context, Map<String, dynamic> alert) {
    final kind = _alertKind(alert);
    final route = _alertRoute(alert);
    final seen = DateTime.tryParse(alert['last_seen_at']?.toString() ?? '');
    final times = (alert['occurrences'] as num?)?.toInt() ?? 1;
    final critical = alert['severity'] == 'critical';
    final tone = critical ? AppColors.danger : AppColors.warning;
    return AdminPanel(
      borderColor: tone.withValues(alpha: .35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(_icon(kind), tone, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(context, kind),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (seen != null)
                      Text(
                        context.l10n.twoPartSummary(
                          AppFormatters.dateTime(seen.toLocal()),
                          context.l10n.alertTimesValue(times.toString()),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (route == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          context.l10n.alertSystemHint,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _busy == null ? () => _resolve(alert) : null,
                child: Text(context.l10n.alertMarkResolved),
              ),
              if (route != null) ...[
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onOpen(route);
                  },
                  child: Text(context.l10n.alertOpen),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AttentionItem {
  const _AttentionItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.count,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title, body;
  final int count;
  final VoidCallback onTap;
}

class _Tool {
  const _Tool(this.icon, this.label, this.color, this.route, this.count);
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final int count;
}
