import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../models/booking_model.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      body: SafeArea(
        child: ValueListenableBuilder<List<BookingModel>>(
          valueListenable: PrototypeSession.bookings,
          builder: (context, bookings, _) {
            return ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: PrototypeSession.adminDrivers,
              builder: (context, drivers, _) {
                final double totalRevenue = bookings
                    .where(
                      (b) =>
                          !b.isActive &&
                          !b.trip.reviewRequired &&
                          b.refundDueCents == 0,
                    )
                    .fold(0.0, (sum, b) => sum + b.trip.receivedCents / 100);
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
                    drivers.length +
                    PrototypeSession.adminTourists.value.length;
                final formatCurrency = NumberFormat.currency(
                  locale: 'en_PH',
                  symbol: '₱',
                );

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
                                  'Operations centre',
                                  style: GoogleFonts.poppins(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'EEEE, d MMMM',
                                  ).format(DateTime.now()),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (PrototypeSession.hasAdminCapability('support'))
                            IconButton(
                              onPressed: () =>
                                  context.push('/admin/announcements'),
                              icon: const Icon(Icons.campaign_outlined),
                            ),
                          IconButton(
                            onPressed: () async {
                              await PrototypeSession.signOut();
                              if (context.mounted) context.go('/login');
                            },
                            icon: const Icon(Icons.logout_rounded),
                          ),
                        ],
                      ),
                      if (PrototypeSession.hasAdminCapability('operations') &&
                          PrototypeSession.operationalAlerts.value.isNotEmpty)
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
                                  '${PrototypeSession.operationalAlerts.value.length} operational alert(s) need review',
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
                                      '$activeDrivers drivers active',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '$activeRides are currently on a trip',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white70,
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
                        'Live overview',
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
                          final aspectRatio = itemWidth / 80;

                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: aspectRatio,
                            children: [
                              _Metric(
                                value: todayBookings.toString(),
                                label: 'Bookings today',
                                icon: Icons.receipt_long_outlined,
                                color: AppColors.primary,
                              ),
                              _Metric(
                                value: verifications.toString(),
                                label: 'Driver verifications',
                                icon: Icons.verified_user_outlined,
                                color: AppColors.warning,
                              ),
                              _Metric(
                                value: NumberFormat.compact().format(
                                  totalAccounts,
                                ),
                                label: 'Tourist accounts',
                                icon: Icons.people_outline_rounded,
                                color: AppColors.success,
                              ),
                              _Metric(
                                value: formatCurrency.format(totalRevenue),
                                label: 'Confirmed cash',
                                icon: Icons.payments_outlined,
                                color: const Color(0xFF8E44AD),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 25),
                      Text(
                        'Act now',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 11),
                      if (PrototypeSession.hasAdminCapability(
                        'driver_compliance',
                      ))
                        _action(
                          context,
                          Icons.verified_user_outlined,
                          'Review pending drivers',
                          '$verifications documents are waiting for verification',
                          '/admin/drivers',
                          AppColors.warning,
                        ),
                      if (PrototypeSession.hasAdminCapability('support')) ...[
                        _action(
                          context,
                          Icons.campaign_outlined,
                          'Send an announcement',
                          'Share an update with drivers or tourists',
                          '/admin/announcements',
                          AppColors.primary,
                        ),
                        _action(
                          context,
                          Icons.people_outline,
                          'Manage tourists',
                          'View and manage tourist accounts',
                          '/admin/tourists',
                          AppColors.success,
                        ),
                        _action(
                          context,
                          Icons.forum_outlined,
                          'Ratings & feedback',
                          'Respond to community concerns',
                          '/admin/ratings',
                          AppColors.secondary,
                        ),
                      ],
                      if (PrototypeSession.hasAdminCapability('operations'))
                        _action(
                          context,
                          Icons.map_outlined,
                          'Live Driver Tracking',
                          'View active drivers on the map',
                          '/admin/live-map',
                          const Color(0xFF8E44AD),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent bookings',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/admin/bookings'),
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                      if (recentBookings.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No recent bookings',
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
                                b.id.toUpperCase(),
                                b.status.name.toUpperCase(),
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
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
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

  Widget _booking(String id, String state, Color color) {
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
                  id,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Tricycle Booking',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
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
              state,
              style: GoogleFonts.poppins(
                fontSize: 9,
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EDF2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
