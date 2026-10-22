import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/booking_model.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    BookingModel? booking;
    try {
      final id = PrototypeSession.activeBookingId;
      if (id != null) {
        booking = PrototypeSession.bookings.value.firstWhere((b) => b.id == id);
      }
    } catch (_) {}
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: const Center(
          child: Text('No active booking. Open Trips to view your history.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Lottie.asset(
                  'assets/animations/success.json',
                  width: 150,
                  height: 150,
                  repeat: false,
                  errorBuilder: (ctx, err, st) => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 80,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                booking.status == BookingStatus.scheduled
                    ? 'Tour scheduled'
                    : 'Request saved',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                booking.status == BookingStatus.scheduled
                    ? 'We will remind you and start matching 30 minutes before pickup.'
                    : 'Waiting for an approved driver to accept your request.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x100D1B2A),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Booking ${booking.id}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        StatusBadge.bookingStatus(booking.status.name),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    _row(
                      'Pickup',
                      booking.pickupAddress,
                      Icons.my_location_rounded,
                    ),
                    if (booking.scheduledAt != null) ...[
                      const SizedBox(height: 13),
                      _row(
                        'Scheduled for',
                        booking.scheduledAt!
                            .toLocal()
                            .toString()
                            .split('.')
                            .first,
                        Icons.event_available_outlined,
                      ),
                    ],
                    if (PrototypeSession.activePackage != null) ...[
                      const SizedBox(height: 13),
                      _row(
                        'Tour package',
                        PrototypeSession.activePackage!.name,
                        Icons.auto_awesome_outlined,
                      ),
                    ],
                    const SizedBox(height: 13),
                    _row(
                      'Destinations',
                      '${booking.stops.length} selected stops',
                      Icons.route_rounded,
                    ),
                    const SizedBox(height: 13),
                    _row(
                      'Payment',
                      booking.paymentMethod.name == 'cash'
                          ? 'Cash payment'
                          : 'Online payment',
                      Icons.account_balance_wallet_outlined,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Agreed fixed fare',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '₱${booking.totalFare.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: booking.status == BookingStatus.scheduled
                    ? 'View scheduled booking'
                    : 'Find my driver',
                prefixIcon: booking.status == BookingStatus.scheduled
                    ? Icons.event_note_outlined
                    : Icons.radar_rounded,
                onPressed: () => context.push(
                  booking!.status == BookingStatus.scheduled
                      ? '/tourist/bookings/${booking.id}'
                      : '/tourist/find-driver',
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/tourist/home'),
                child: const Text('Back to explore'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String detail, IconData icon) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              detail,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
