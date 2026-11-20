import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/widgets/remote_page_controls.dart';
import '../../../core/services/realtime_refresh_policy.dart';
import '../../../core/widgets/list_skeleton.dart';
import '../../../core/services/server_clock.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/session/app_session.dart';
import '../../../core/l10n/record_labels.dart';

class TouristBookingsScreen extends StatelessWidget {
  const TouristBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        bottomNavigationBar: const RemotePageControls(directory: false),
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(context.l10n.myBookings),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: context.l10n.active),
              Tab(text: context.l10n.past),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BookingList(status: 'ongoing'),
            _BookingList(status: 'past'),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final String status;
  const _BookingList({required this.status});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSession.bookings,
        AppSession.loadingSections,
      ]),
      builder: (context, _) {
        final bookingsList = AppSession.bookings.value;
        if (bookingsList.isEmpty &&
            AppSession.loadingSections.value.contains(RemoteSection.bookings)) {
          return const ListSkeleton();
        }
        final bookings = status == 'ongoing'
            ? bookingsList
                  .where(
                    (b) =>
                        b.touristId == AppSession.currentTouristId &&
                        b.isActive,
                  )
                  .toList()
            : bookingsList
                  .where(
                    (b) =>
                        b.touristId == AppSession.currentTouristId &&
                        !b.isActive,
                  )
                  .toList();

        if (bookings.isEmpty) {
          return EmptyStateWidget(
            icon: status == 'ongoing' ? Icons.directions_bike : Icons.history,
            title: status == 'ongoing'
                ? MessageCode.noActiveTrips
                : MessageCode.noPastTripsYet,
            subtitle: status == 'ongoing'
                ? MessageCode.bookATourToGetStarted
                : MessageCode.yourCompletedRidesWillAppearHere,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final b = bookings[index];
            final names = b.stops.map((s) => s.spotName).toList();
            final preview = names.take(2).join(', ');
            final overflow = names.length > 2
                ? ' +${names.length - 2} more'
                : '';

            return GestureDetector(
              onTap: () => context.push('/tourist/bookings/${b.id}'),
              child: AppCard(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            context.message(b.id).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        StatusBadge.bookingStatus(b.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.message('$preview$overflow'),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.message(
                        b.scheduledAt == null
                            ? AppFormatters.dateTime(b.createdAt.toLocal())
                            : MessageCode.pickupValue(
                                (ServerClock.formatManila(
                                  b.scheduledAt!,
                                )).toString(),
                              ),
                      ),
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            context.l10n.agreedFare,
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            context.message(
                              '₱${AppFormatters.amount(b.totalFareCents / 100)}',
                            ),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!b.isActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          context.message(
                            b.trip.reviewRequired
                                ? MessageCode.paymentOnHoldAdminReview
                                : MessageCode.finalChargeValue(
                                    (AppFormatters.amount(
                                      ((b.trip.finalChargeCents ?? 0) / 100),
                                    )).toString(),
                                    paymentStatusLabel(
                                      context,
                                      b.paymentStatus,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
