import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/record_labels.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/session/app_session.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/remote_page_controls.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/booking_model.dart';
import '../widgets/admin_ui.dart';

/// Every booking, grouped by what the admin may need to do about it.
class MonitorBookingsScreen extends StatelessWidget {
  const MonitorBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<BookingModel>>(
        valueListenable: AppSession.bookings,
        builder: (context, bookings, _) {
          final l = context.l10n;
          final sorted = bookings.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final groups = <(String, List<BookingModel>, IconData)>[
            (
              l.needsReview,
              sorted.where((b) => b.trip.reviewRequired).toList(),
              Icons.flag_outlined,
            ),
            (
              l.paymentAttention,
              sorted
                  .where((b) => needsPaymentReview(b) && !b.trip.reviewRequired)
                  .toList(),
              Icons.payments_outlined,
            ),
            (
              l.active,
              sorted.where((b) => b.isActive).toList(),
              Icons.electric_rickshaw_outlined,
            ),
            (
              l.unsettledCash,
              sorted
                  .where(
                    (b) =>
                        !b.isActive &&
                        !b.trip.reviewRequired &&
                        (b.amountDueCents > 0 || b.refundDueCents > 0),
                  )
                  .toList(),
              Icons.account_balance_wallet_outlined,
            ),
            (l.all, sorted, Icons.receipt_long_outlined),
          ];
          return DefaultTabController(
            length: groups.length,
            child: Scaffold(
              bottomNavigationBar: const RemotePageControls(directory: false),
              appBar: AppBar(
                title: Text(l.bookingsPaymentReviews),
                bottom: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  tabs: [
                    for (final (label, list, _) in groups)
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label),
                            if (list.isNotEmpty && list != sorted) ...[
                              const SizedBox(width: 6),
                              CountBadge(
                                list.length,
                                color: label == l.active
                                    ? AppColors.primary
                                    : AppColors.danger,
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  for (final (_, list, icon) in groups)
                    _BookingList(list: list, emptyIcon: icon),
                ],
              ),
            ),
          );
        },
      );
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.list, required this.emptyIcon});

  final List<BookingModel> list;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.task_alt_rounded,
        title: context.l10n.noBookingsInThisCategory,
        subtitle: context.l10n.noBookingsInThisCategoryBody,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, index) => FadeSlideIn.staggered(
        index: index,
        child: _BookingCard(booking: list[index]),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = booking;
    final statusColor = switch (b.status) {
      BookingStatus.completed => AppColors.success,
      BookingStatus.pending => AppColors.warning,
      BookingStatus.ongoing => AppColors.primary,
      BookingStatus.cancelled => AppColors.danger,
      _ => AppColors.textSecondary,
    };
    final review = b.trip.reviewRequired;
    final payTone = review || needsPaymentReview(b)
        ? AppColors.danger
        : AppColors.success;
    return AdminPanel(
      onTap: () => context.push('/admin/booking/${b.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                review
                    ? Icons.flag_outlined
                    : b.paymentStatus == PaymentStatus.failed
                    ? Icons.error_outline_rounded
                    : Icons.electric_rickshaw_outlined,
                review ? AppColors.danger : AppColors.primary,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.message(AppSession.bookingTitle(b)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      l.twoPartSummary(
                        AppFormatters.bookingId(b.id),
                        AppFormatters.dateTime(b.scheduledAt ?? b.createdAt),
                      ),
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
              Text(
                AppFormatters.currency(b.totalFareCents / 100),
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _person(Icons.person_outline_rounded, b.touristName),
          const SizedBox(height: 4),
          _person(
            Icons.badge_outlined,
            context.message(b.driverName ?? MessageCode.noDriverYet),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(
                label: bookingStatusLabel(context, b.status),
                color: statusColor.withValues(alpha: .12),
                textColor: statusColor,
              ),
              StatusBadge(
                label: context.message(
                  review
                      ? MessageCode.paymentReview
                      : paymentStatusLabel(context, b.paymentStatus),
                ),
                color: payTone.withValues(alpha: .1),
                textColor: payTone,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _person(IconData icon, String name) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    ],
  );
}
