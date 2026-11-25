import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/widgets/map_surface.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/config/mapbox_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/booking_model.dart';
import '../../../core/widgets/web_map_fallback.dart';

class IncomingBookingScreen extends ConsumerWidget {
  final String bookingId;
  const IncomingBookingScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<List<BookingModel>>(
      valueListenable: AppSession.bookings,
      builder: (context, bookings, _) {
        final booking = bookings
            .where(
              (b) =>
                  b.id == bookingId &&
                  b.status == BookingStatus.pending &&
                  !b.isDispatchExpired &&
                  !b.isOfferExpired,
            )
            .firstOrNull;

        if (booking == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                context.l10n.incomingBooking,
                style: GoogleFonts.poppins(color: AppColors.textPrimary),
              ),
              backgroundColor: AppColors.surface,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
            ),
            body: EmptyStateWidget(
              title: context.l10n.noPendingRequest,
              subtitle: context.l10n.theRideRequestIsNoLongerAvailable,
              icon: Icons.electric_rickshaw,
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF102A43),
          // Fill the screen; sized to the card, the map stopped two-thirds
          // of the way down on tall phones.
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: kIsWeb
                    ? WebMapFallback(
                        title: context.l10n.incomingPickup,
                        subtitle:
                            context.l10n.openTheMobileAppForTheInteractiveRoute,
                      )
                    : MapSurface(
                        builder: (context) => MapWidget(
                          styleUri: MapboxConfig.mapStyle,
                          // The scale bar drew over the status bar.
                          onMapCreated: (map) => map.scaleBar.updateSettings(
                            ScaleBarSettings(enabled: false),
                          ),
                          viewport: CameraViewportState(
                            center: Point(
                              coordinates: Position(
                                booking.pickupLng,
                                booking.pickupLat,
                              ),
                            ),
                            zoom: 15.0,
                            pitch: 0.0,
                            bearing: 0.0,
                          ),
                        ),
                      ),
              ),
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          context.l10n.newRideRequest,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          context.l10n.aNearbyTouristIsLookingForADriver,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 32),
                        AppCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      context.message(
                                        booking.touristName.isNotEmpty
                                            ? booking.touristName[0]
                                                  .toUpperCase()
                                            : AppBrand.initial,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.message(booking.touristName),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    // Was always "Cash"; the driver needs to
                                    // know whether to expect cash or GCash.
                                    child: Text(
                                      booking.paymentMethod ==
                                              PaymentMethod.gcashDirect
                                          ? context.l10n.gcashSendToDriver
                                          : context.l10n.cash,
                                      style: GoogleFonts.poppins(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              _buildLocationRow(
                                context,
                                Icons.my_location,
                                booking.pickupAddress,
                                AppColors.primary,
                              ),
                              const SizedBox(height: 16),
                              _buildLocationRow(
                                context,
                                Icons.groups_2_outlined,
                                MessageCode.passengerCount(
                                  booking.passengerCount,
                                ),
                                AppColors.primary,
                              ),
                              if (booking.luggageNotes.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildLocationRow(
                                  context,
                                  Icons.luggage_outlined,
                                  booking.luggageNotes,
                                  AppColors.secondary,
                                ),
                              ],
                              if (booking.accessibilityNeeds.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildLocationRow(
                                  context,
                                  Icons.accessible_outlined,
                                  booking.accessibilityNeeds,
                                  AppColors.success,
                                ),
                              ],
                              const SizedBox(height: 16),
                              // Which tour, so the driver knows the route
                              // before accepting.
                              _buildLocationRow(
                                context,
                                Icons.route_rounded,
                                AppSession.bookingTitle(booking),
                                AppColors.danger,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                context.message(
                                  '₱ ${AppFormatters.amount(booking.totalFareCents / 100)}',
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                context.l10n.agreedFixedFare,
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: context.l10n.decline,
                                onPressed: () async {
                                  try {
                                    await AppSession.declineDriverOffer(
                                      booking.id,
                                    );
                                    if (context.mounted) context.pop();
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            context.message(
                                              ErrorMessages.forError(error),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                type: AppButtonType.outline,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppButton(
                                label: context.l10n.accept,
                                onPressed: () async {
                                  // Accepting updates the booking list, which
                                  // rebuilds this screen without this button;
                                  // keep the navigator from before the await.
                                  final router = GoRouter.of(context);
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  try {
                                    await AppSession.acceptBooking(booking.id);
                                    router.pushReplacement(
                                      '/driver/trip/${booking.id}',
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            context.message(
                                              ErrorMessages.forError(e),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationRow(
    BuildContext context,
    IconData icon,
    String address,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.message(address),
            style: GoogleFonts.poppins(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
