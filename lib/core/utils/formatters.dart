import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static String currency(double amount) {
    return '₱${NumberFormat('#,##0.00').format(amount)}';
  }

  static String currencyShort(double amount) {
    return '₱${NumberFormat('#,##0').format(amount)}';
  }

  static String date(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  static String dateShort(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String time(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  static String dateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }

  static String distance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins == 0 ? '${hours}h' : '${hours}h ${mins}m';
  }

  static String phoneDisplay(String phone) {
    if (phone.length != 11) return phone;
    return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
  }

  static String bookingId(String id) {
    return '#${id.substring(0, 8).toUpperCase()}';
  }

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  static String rating(double rating) {
    return rating.toStringAsFixed(1);
  }

  static String tripCount(int count) {
    return '$count ${count == 1 ? 'trip' : 'trips'}';
  }
}
