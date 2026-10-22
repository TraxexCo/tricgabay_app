import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/booking_model.dart';
import '../../../core/prototype/prototype_session.dart';

class TouristBookingsScreen extends StatelessWidget {
  const TouristBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'My Bookings',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.surface,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Ongoing'),
              Tab(text: 'Past'),
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
    return ValueListenableBuilder<List<BookingModel>>(
      valueListenable: PrototypeSession.bookings,
      builder: (context, bookingsList, _) {
        final bookings = status == 'ongoing'
            ? bookingsList
                  .where(
                    (b) =>
                        b.touristId == PrototypeSession.currentTouristId &&
                        b.isActive,
                  )
                  .toList()
            : bookingsList
                  .where(
                    (b) =>
                        b.touristId == PrototypeSession.currentTouristId &&
                        !b.isActive,
                  )
                  .toList();

        if (bookings.isEmpty) {
          return EmptyStateWidget(
            icon: status == 'ongoing' ? Icons.directions_bike : Icons.history,
            title: status == 'ongoing'
                ? 'No active trips'
                : 'No past trips yet',
            subtitle: status == 'ongoing'
                ? 'Book a tour to get started!'
                : 'Your completed rides will appear here.',
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
                            b.id.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        StatusBadge.bookingStatus(b.status.name),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$preview$overflow',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.scheduledAt == null
                          ? b.createdAt.toLocal().toString().split('.')[0]
                          : 'Pickup: ${b.scheduledAt!.toLocal().toString().split('.')[0]}',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Agreed fare',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '₱${b.totalFare.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (!b.isActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          b.trip.reviewRequired
                              ? 'Payment on hold · admin review'
                              : 'Final charge: ₱${((b.trip.finalChargeCents ?? 0) / 100).toStringAsFixed(2)} · ${b.paymentStatus.name}',
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
