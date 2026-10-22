import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/config/mapbox_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/prototype/prototype_session.dart';
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
      valueListenable: PrototypeSession.bookings,
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
                'Incoming Booking',
                style: GoogleFonts.poppins(color: AppColors.textPrimary),
              ),
              backgroundColor: AppColors.surface,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
            ),
            body: const EmptyStateWidget(
              title: 'No Pending Request',
              subtitle: 'The ride request is no longer available.',
              icon: Icons.electric_rickshaw,
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF102A43),
          body: Stack(
            children: [
              Positioned.fill(
                child: kIsWeb
                    ? const WebMapFallback(
                        title: 'Incoming pickup',
                        subtitle:
                            'Open the mobile app for the interactive route.',
                      )
                    : MapWidget(
                        styleUri: MapboxConfig.mapStyle,
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
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Text(
                        'New ride request',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'A nearby tourist is looking for a driver.',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(height: 24),
                      AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Text(
                                    booking.touristName.isNotEmpty
                                        ? booking.touristName[0].toUpperCase()
                                        : 'T',
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
                                        booking.touristName,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: AppColors.secondary,
                                            size: 16,
                                          ),
                                          Text(
                                            ' 5.0 (New)',
                                            style: GoogleFonts.poppins(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
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
                                  child: Text(
                                    'Cash',
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
                              Icons.my_location,
                              booking.pickupAddress,
                              AppColors.primary,
                            ),
                            const SizedBox(height: 16),
                            _buildLocationRow(
                              Icons.groups_2_outlined,
                              '${booking.passengerCount} passenger${booking.passengerCount == 1 ? '' : 's'}',
                              AppColors.primary,
                            ),
                            if (booking.luggageNotes.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildLocationRow(
                                Icons.luggage_outlined,
                                booking.luggageNotes,
                                AppColors.secondary,
                              ),
                            ],
                            if (booking.accessibilityNeeds.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildLocationRow(
                                Icons.accessible_outlined,
                                booking.accessibilityNeeds,
                                AppColors.success,
                              ),
                            ],
                            if (booking.stops.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildLocationRow(
                                Icons.location_on,
                                booking.stops.last.spotName,
                                AppColors.danger,
                              ),
                            ],
                            const SizedBox(height: 24),
                            Text(
                              '₱ ${booking.totalFare.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Agreed fixed fare',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'DECLINE',
                              onPressed: () async {
                                try {
                                  await PrototypeSession.declineDriverOffer(
                                    booking.id,
                                  );
                                  if (context.mounted) context.pop();
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$error')),
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
                              label: 'ACCEPT',
                              onPressed: () async {
                                try {
                                  await PrototypeSession.acceptBooking(
                                    booking.id,
                                  );
                                  if (context.mounted) {
                                    context.go('/driver/trip/${booking.id}');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationRow(IconData icon, String address, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            style: GoogleFonts.poppins(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
