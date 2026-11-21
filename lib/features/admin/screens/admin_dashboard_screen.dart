import '../../../core/widgets/language_selection.dart';
import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import '../../../core/motion/motion_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/session/app_session.dart';
import '../../../models/booking_model.dart';
import '../../../core/l10n/record_labels.dart';
import '../../../core/widgets/account_widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<List<BookingModel>>(
          valueListenable: AppSession.bookings,
          builder: (context, bookings, _) {
            return ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: AppSession.adminDrivers,
              builder: (context, drivers, _) {
                final settled = bookings.where(
                  (b) =>
                      !b.isActive &&
                      !b.trip.reviewRequired &&
                      b.refundDueCents == 0,
                );
                final totalRevenue = settled.fold<double>(
                  0,
                  (sum, b) => sum + b.trip.receivedCents / 100,
                );
                final includesDirectGcash = settled.any(
                  (b) =>
                      b.paymentMethod == PaymentMethod.gcashDirect &&
                      b.trip.receivedCents > 0,
                );
                final int activeRides = bookings
                    .where((b) => b.status == BookingStatus.ongoing)
                    .length;
                final int activeDrivers = drivers
                    .where((d) => d['status'] == 'active')
                    .length;
                final int todayBookings = bookings
                    .where(
                      (b) => b.createdAt.isAfter(
                        DateTime.now().subtract(const Duration(days: 1)),
                      ),
                    )
                    .length;
                final int verifications = drivers
                    .where((d) => d['status'] == 'pending')
                    .length;
                final int totalAccounts =
                    drivers.length + AppSession.adminTourists.value.length;

                final recentBookings = bookings.toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.operationsCentre,
                                  style: GoogleFonts.poppins(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  context.message(
                                    AppFormatters.weekdayDate(DateTime.now()),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
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
                          if (AppSession.hasAdminCapability('support'))
                            IconButton(
                              tooltip: context.l10n.sendAnAnnouncement,
                              onPressed: () =>
                                  context.push('/admin/announcements'),
                              icon: const Icon(Icons.campaign_outlined),
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
                      ),
                      const SizedBox(height: 16),
                      AccountIdentityCard(
                        roleLabel: context.l10n.administrator,
                      ),
                      if (AppSession.hasAdminCapability('operations') &&
                          AppSession.operationalAlerts.value.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 14),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF5B041)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.health_and_safety_outlined,
                                color: Color(0xFFA65F00),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  context.l10n.operationalAlertSNeedReviewValue(
                                    context.message(
                                      (AppSession
                                              .operationalAlerts
                                              .value
                                              .length)
                                          .toString(),
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 22),
                      InkWell(
                        onTap: () => context.push('/admin/live-map'),
                        borderRadius: BorderRadius.circular(25),
                        child: Ink(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF102A43), Color(0xFF1B6CA8)],
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.radar_rounded,
                                  color: Color(0xFF8DE2C1),
                                  size: 27,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.driversActiveValue(
                                        context.message(
                                          (activeDrivers).toString(),
                                        ),
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      context.l10n.areCurrentlyOnATripValue(
                                        context.message(
                                          (activeRides).toString(),
                                        ),
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.l10n.liveOverview,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = width > 600 ? 4 : 2;
                          final itemWidth =
                              (width - (12 * (crossAxisCount - 1))) /
                              crossAxisCount;
                          final aspectRatio =
                              itemWidth /
                              (64 +
                                  MediaQuery.textScalerOf(context).scale(20) *
                                      1.5 +
                                  MediaQuery.textScalerOf(context).scale(12) *
                                      3);

                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: aspectRatio,
                            children: [
                              for (final (i, metric) in <Widget>[
                                _Metric(
                                  value: todayBookings.toString(),
                                  label: MessageCode.bookingsToday,
                                  icon: Icons.receipt_long_outlined,
                                  color: AppColors.primary,
                                ),
                                _Metric(
                                  value: verifications.toString(),
                                  label: MessageCode.driverVerifications,
                                  icon: Icons.verified_user_outlined,
                                  color: AppColors.warning,
                                ),
                                _Metric(
                                  value: NumberFormat.compact(
                                    locale: AppFormatters.resolvedLocale(null),
                                  ).format(totalAccounts),
                                  label: MessageCode.touristAccounts,
                                  icon: Icons.people_outline_rounded,
                                  color: AppColors.success,
                                ),
                                _Metric(
                                  value: AppFormatters.currency(totalRevenue),
                                  label: includesDirectGcash
                                      ? context.l10n.gcashConfirmedFares
                                      : MessageCode.confirmedCash,
                                  icon: Icons.payments_outlined,
                                  color: const Color(0xFF8E44AD),
                                ),
                              ].indexed)
                                FadeSlideIn.staggered(index: i, child: metric),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(context.l10n.loadedBookingTotals),
                      const SizedBox(height: 25),
                      Text(
                        context.l10n.actNow,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 11),
                      if (AppSession.hasAdminCapability('driver_compliance'))
                        _action(
                          context,
                          Icons.verified_user_outlined,
                          MessageCode.reviewPendingDrivers,
                          MessageCode.documentsAreWaitingForVerificationValue(
                            (verifications).toString(),
                          ),
                          '/admin/drivers',
                          AppColors.warning,
                        ),
                      if (AppSession.hasAdminCapability('support')) ...[
                        _action(
                          context,
                          Icons.campaign_outlined,
                          MessageCode.sendAnAnnouncement,
                          MessageCode.shareAnUpdateWithDriversOrTourists,
                          '/admin/announcements',
                          AppColors.primary,
                        ),
                        _action(
                          context,
                          Icons.people_outline,
                          MessageCode.manageTourists,
                          MessageCode.viewAndManageTouristAccounts,
                          '/admin/tourists',
                          AppColors.success,
                        ),
                        _action(
                          context,
                          Icons.forum_outlined,
                          MessageCode.ratingsFeedback,
                          MessageCode.respondToCommunityConcerns,
                          '/admin/ratings',
                          AppColors.secondary,
                        ),
                      ],
                      if (AppSession.hasAdminCapability('finance') ||
                          AppSession.hasAdminCapability('operations'))
                        _action(
                          context,
                          Icons.gavel_rounded,
                          MessageCode.adminGcashDisputes,
                          MessageCode.adminGcashDisputesOpen(
                            bookings
                                .where(
                                  (b) =>
                                      b.paymentMethod ==
                                          PaymentMethod.gcashDirect &&
                                      b.paymentStatus == PaymentStatus.disputed,
                                )
                                .length,
                          ),
                          '/admin/gcash-disputes',
                          AppColors.danger,
                        ),
                      if (AppSession.hasAdminCapability('operations'))
                        _action(
                          context,
                          Icons.map_outlined,
                          MessageCode.liveDriverTracking,
                          MessageCode.viewActiveDriversOnTheMap,
                          '/admin/live-map',
                          const Color(0xFF8E44AD),
                        ),
                      if (AppSession.hasAdminCapability('support'))
                        _action(
                          context,
                          Icons.download_outlined,
                          MessageCode.dataExportRequests,
                          MessageCode.preparePrivateAccountExports,
                          '/admin/data-requests',
                          AppColors.primary,
                        ),
                      if (AppSession.hasAdminCapability('operations')) ...[
                        _action(
                          context,
                          Icons.local_hospital_outlined,
                          MessageCode.emergencyContactsSettings,
                          MessageCode.verifyLocalAgencyNumbers,
                          '/admin/emergency-contacts',
                          AppColors.danger,
                        ),
                        _action(
                          context,
                          Icons.monitor_heart_outlined,
                          MessageCode.serviceHealth,
                          MessageCode.reviewFailuresAndStaleDrivers,
                          '/admin/health',
                          AppColors.warning,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              context.l10n.recentBookings,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Flexible(
                            child: TextButton(
                              onPressed: () => context.push('/admin/bookings'),
                              child: Text(context.l10n.viewAll),
                            ),
                          ),
                        ],
                      ),
                      if (recentBookings.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              context.l10n.noRecentBookings,
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        ...recentBookings
                            .take(3)
                            .map(
                              (b) => _booking(
                                context,
                                // Tour name and a short reference instead of
                                // the full database id.
                                b.trip.packageName ??
                                    AppSession.packageNameFor(
                                      b.trip.packageId,
                                    ) ??
                                    MessageCode.customTour,
                                '#${b.id.split('-').first.toUpperCase()} · ${b.touristName}',
                                bookingStatusLabel(context, b.status),
                                _getStatusColor(b.status),
                              ),
                            ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.ongoing:
        return AppColors.primary;
      case BookingStatus.cancelled:
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    String route,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push(route),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.message(title),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        context.message(description),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _booking(
    BuildContext context,
    String id,
    String subtitle,
    String state,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.electric_rickshaw_outlined,
              size: 19,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.message(id),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.message(subtitle),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              context.message(state),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value, label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  context.message(value),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                context.message(label),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
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
