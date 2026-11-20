import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/server_clock.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/booking_model.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = PrototypeSession.activeBookingId;
    final booking = PrototypeSession.bookings.value
        .where((booking) => booking.id == id)
        .firstOrNull;
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.booking)),
        body: Center(
          child: Text(context.l10n.noActiveBookingOpenTripsToViewYourHistory),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
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
                const SizedBox(height: 20),
                Text(
                  context.message(
                    booking.status == BookingStatus.scheduled
                        ? MessageCode.tourScheduled
                        : MessageCode.requestSaved,
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.message(
                    booking.status == BookingStatus.scheduled
                        ? MessageCode
                              .weWillRemindYouAndStartMatching30MinutesBeforePickup
                        : MessageCode
                              .waitingForAnApprovedDriverToAcceptYourRequest,
                  ),
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
                              context.l10n.bookingValue(
                                context.message((booking.id).toString()),
                              ),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          StatusBadge.bookingStatus(booking.status),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(),
                      ),
                      _row(
                        context,
                        MessageCode.pickup,
                        booking.pickupAddress,
                        Icons.my_location_rounded,
                      ),
                      if (booking.scheduledAt != null) ...[
                        const SizedBox(height: 13),
                        _row(
                          context,
                          MessageCode.scheduledFor,
                          ServerClock.formatManila(booking.scheduledAt!),
                          Icons.event_available_outlined,
                        ),
                      ],
                      if (PrototypeSession.activePackage != null) ...[
                        const SizedBox(height: 13),
                        _row(
                          context,
                          MessageCode.tourPackage,
                          PrototypeSession.activePackage!.name,
                          Icons.auto_awesome_outlined,
                        ),
                      ],
                      const SizedBox(height: 13),
                      _row(
                        context,
                        MessageCode.destinations,
                        MessageCode.selectedStopsCount(booking.stops.length),
                        Icons.route_rounded,
                      ),
                      const SizedBox(height: 13),
                      _row(
                        context,
                        MessageCode.payment,
                        switch (booking.paymentMethod) {
                          PaymentMethod.gcashDirect =>
                            context.l10n.gcashSendToDriver,
                          PaymentMethod.cash => MessageCode.cashPayment,
                          _ => MessageCode.onlinePayment,
                        },
                        Icons.account_balance_wallet_outlined,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              context.l10n.agreedFixedFare,
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              context.message(
                                '₱${AppFormatters.amount(booking.totalFare)}',
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: booking.status == BookingStatus.scheduled
                      ? MessageCode.viewScheduledBooking
                      : MessageCode.findMyDriver,
                  prefixIcon: booking.status == BookingStatus.scheduled
                      ? Icons.event_note_outlined
                      : Icons.radar_rounded,
                  onPressed: () => context.push(
                    booking.status == BookingStatus.scheduled
                        ? '/tourist/bookings/${booking.id}'
                        : '/tourist/find-driver',
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.go('/tourist/home'),
                  child: Text(context.l10n.backToExplore),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String detail,
    IconData icon,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.message(label),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              context.message(detail),
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
