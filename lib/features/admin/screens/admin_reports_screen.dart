import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/session/app_session.dart';
import '../../../models/booking_model.dart';
import 'package:share_plus/share_plus.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _selectedFilter = MessageCode.thisWeek;
  final List<String> _filters = [
    MessageCode.thisWeek,
    MessageCode.thisMonth,
    MessageCode.thisYear,
  ];

  List<({String name, double rating, int trips})> _driverPerformance() {
    final grouped = <String, List<BookingModel>>{};
    for (final booking in AppSession.bookings.value.where(
      (b) => b.status == BookingStatus.completed && b.driverName != null,
    )) {
      grouped.putIfAbsent(booking.driverName!, () => []).add(booking);
    }
    final result = grouped.entries.map((entry) {
      final ratings = entry.value
          .where((b) => b.driverRating != null)
          .map((b) => b.driverRating!)
          .toList();
      final rating = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;
      return (name: entry.key, rating: rating, trips: entry.value.length);
    }).toList();
    result.sort((a, b) {
      final byTrips = b.trips.compareTo(a.trips);
      return byTrips == 0 ? b.rating.compareTo(a.rating) : byTrips;
    });
    return result.take(5).toList();
  }

  String _csv(String value) => '"${value.replaceAll('"', '""')}"';

  Future<void> _exportReport() async {
    final rows = <String>[
      'booking_reference,status,payment_method,amount_received_php,created_at,completed_at',
      ..._getFilteredBookings().map(
        (booking) => [
          _csv(booking.id),
          booking.status.name,
          booking.paymentMethod.name,
          AppFormatters.decimalInput((booking.trip.receivedCents / 100)),
          booking.createdAt.toUtc().toIso8601String(),
          booking.completedAt?.toUtc().toIso8601String() ?? '',
        ].join(','),
      ),
    ];
    await SharePlus.instance.share(
      ShareParams(
        subject: context.l10n.appReportValue(
          context.message(_selectedFilter),
          AppBrand.name,
        ),
        text: context
            .l10n
            .confirmedTransactionsOnlyOpenReviewsAndOutstandingRefundsAreExcluded,
        files: [
          XFile.fromData(utf8.encode(rows.join('\r\n')), mimeType: 'text/csv'),
        ],
        fileNameOverrides: [
          'tric-gabay-${DateTime.now().toUtc().millisecondsSinceEpoch}.csv',
        ],
      ),
    );
  }

  List<BookingModel> _getFilteredBookings() {
    final bookings = AppSession.bookings.value;
    final now = DateTime.now();

    return bookings.where((b) {
      if (b.isActive ||
          b.trip.reviewRequired ||
          b.refundDueCents > 0 ||
          b.trip.receivedCents == 0) {
        return false;
      }
      if (_selectedFilter == MessageCode.thisWeek) {
        return now.difference(b.createdAt).inDays <= 7;
      } else if (_selectedFilter == MessageCode.thisMonth) {
        return now.difference(b.createdAt).inDays <= 30;
      } else {
        // This Year
        return now.difference(b.createdAt).inDays <= 365;
      }
    }).toList();
  }

  List<FlSpot> _getChartData(List<BookingModel> filteredBookings) {
    if (filteredBookings.isEmpty) {
      // Return flat line if empty
      int emptyDays = _selectedFilter == MessageCode.thisWeek
          ? 7
          : (_selectedFilter == MessageCode.thisMonth ? 30 : 12);
      return List.generate(emptyDays, (i) => FlSpot(i.toDouble(), 0));
    }

    int days = _selectedFilter == MessageCode.thisWeek
        ? 7
        : (_selectedFilter == MessageCode.thisMonth ? 30 : 12);
    List<FlSpot> spots = [];

    if (_selectedFilter == MessageCode.thisYear) {
      Map<int, double> monthlyRevenue = {for (var i = 0; i < 12; i++) i: 0.0};
      final now = DateTime.now();

      for (var b in filteredBookings) {
        int monthsAgo =
            (now.year - b.createdAt.year) * 12 + now.month - b.createdAt.month;
        if (monthsAgo >= 0 && monthsAgo < 12) {
          monthlyRevenue[11 - monthsAgo] =
              (monthlyRevenue[11 - monthsAgo] ?? 0) +
              (b.trip.receivedCents / 100);
        }
      }

      for (int i = 0; i < 12; i++) {
        spots.add(FlSpot(i.toDouble(), monthlyRevenue[i]!));
      }
    } else {
      Map<int, double> dailyRevenue = {for (var i = 0; i < days; i++) i: 0.0};
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var b in filteredBookings) {
        final bDate = DateTime(
          b.createdAt.year,
          b.createdAt.month,
          b.createdAt.day,
        );
        int daysAgo = today.difference(bDate).inDays;
        if (daysAgo >= 0 && daysAgo < days) {
          dailyRevenue[days - 1 - daysAgo] =
              (dailyRevenue[days - 1 - daysAgo] ?? 0) +
              (b.trip.receivedCents / 100);
        }
      }

      for (int i = 0; i < days; i++) {
        spots.add(FlSpot(i.toDouble(), dailyRevenue[i]!));
      }
    }

    return spots;
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      color: AppColors.textSecondary,
    );
    Widget text = Text(context.message(''));
    final now = DateTime.now();

    if (_selectedFilter == MessageCode.thisYear) {
      int index = value.toInt();
      if (index >= 0 && index < 12) {
        int monthsAgo = 11 - index;
        DateTime d = DateTime(now.year, now.month - monthsAgo, 1);
        text = Text(AppFormatters.monthShort(d), style: style);
      }
    } else if (_selectedFilter == MessageCode.thisWeek) {
      int index = value.toInt();
      if (index >= 0 && index < 7) {
        int daysAgo = 6 - index;
        DateTime d = now.subtract(Duration(days: daysAgo));
        text = Text(AppFormatters.weekdayShort(d), style: style);
      }
    } else {
      // This Month
      int index = value.toInt();
      if (index >= 0 && index < 30) {
        if (index % 5 == 0 || index == 29) {
          int daysAgo = 29 - index;
          DateTime d = now.subtract(Duration(days: daysAgo));
          text = Text(AppFormatters.monthDay(d), style: style);
        }
      }
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      color: AppColors.textSecondary,
    );
    if (value == meta.max || value == meta.min) return Container();
    if (value >= 1000) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          context.l10n.compactCurrency(
            context.message(((value / 1000).toStringAsFixed(1)).toString()),
          ),
          style: style,
        ),
      );
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(AppFormatters.currencyShort(value), style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = _getFilteredBookings();
    final totalRevenue = filteredBookings.fold(
      0.0,
      (sum, item) => sum + (item.trip.receivedCents / 100),
    );
    final includesDirectGcash = filteredBookings.any(
      (booking) => booking.paymentMethod == PaymentMethod.gcashDirect,
    );
    final totalBookings = filteredBookings.length;
    final chartData = _getChartData(filteredBookings);
    final driverPerformance = _driverPerformance();

    // Find max Y for chart scaling
    double maxY = 0;
    for (var spot in chartData) {
      if (spot.y > maxY) maxY = spot.y;
    }
    if (maxY == 0) maxY = 1000; // default scale
    // Give some padding at top
    maxY = maxY * 1.2;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      appBar: AppBar(
        title: Text(context.l10n.reportsAnalytics),
        actions: [
          IconButton(
            tooltip: context.l10n.downloadReport,
            icon: const Icon(Icons.file_download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(context.message(e)),
                          selected: e == _selectedFilter,
                          onSelected: (val) {
                            if (val) setState(() => _selectedFilter = e);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: e == _selectedFilter
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildReportStat(
                    includesDirectGcash
                        ? context.l10n.gcashConfirmedFares
                        : MessageCode.totalRevenue,
                    AppFormatters.currencyShort(totalRevenue),
                    Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildReportStat(
                    MessageCode.totalBookings,
                    '$totalBookings',
                    Icons.receipt_long,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(context.l10n.loadedBookingTotals),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    includesDirectGcash
                        ? context.l10n.gcashConfirmedFaresOverTime
                        : context.l10n.revenueOverTime,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: filteredBookings.isEmpty
                        ? Center(
                            child: Text(
                              context
                                  .l10n
                                  .noCompletedBookingsFoundForThisPeriod,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) =>
                                    const FlLine(
                                      color: Color(0xFFE5E7EB),
                                      strokeWidth: 1,
                                    ),
                              ),
                              titlesData: FlTitlesData(
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 45,
                                    getTitlesWidget: leftTitleWidgets,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: bottomTitleWidgets,
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minY: 0,
                              maxY: maxY,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: chartData,
                                  isCurved: true,
                                  color: AppColors.primary,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.driverPerformance,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (driverPerformance.isEmpty)
                    Text(
                      context.l10n.noCompletedDriverTripsYet,
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    ...driverPerformance.map(
                      (driver) => _performanceRow(
                        driver.name,
                        driver.rating == 0
                            ? MessageCode.notRated
                            : '${driver.rating.toStringAsFixed(1)} ★',
                        '${driver.trips} ${driver.trips == 1 ? 'trip' : 'trips'}',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStat(String label, String value, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            context.message(value),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            context.message(label),
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _performanceRow(String name, String rating, String trips) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
        const SizedBox(width: 9),
        Expanded(child: Text(context.message(name))),
        Text(
          context.message(rating),
          style: const TextStyle(color: AppColors.secondary),
        ),
        const SizedBox(width: 12),
        Text(
          context.message(trips),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}
