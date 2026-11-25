import 'package:tricgabay_app/core/l10n/message_codes.g.dart';

class CancellationPolicy {
  final int version;
  final int freeCancellationMinutes;
  final int acceptedTripFeePercent;
  final int driverWaitMinutes;
  final int noShowFeePercent;
  final String terms;
  final List<String> history;

  const CancellationPolicy({
    this.version = 1,
    this.freeCancellationMinutes = 5,
    this.acceptedTripFeePercent = 20,
    this.driverWaitMinutes = 10,
    this.noShowFeePercent = 50,
    this.terms =
        'Pending requests and driver cancellations are free. Tourist cancellation after the grace period may incur the published fee. A no-show requires verified driver arrival and the full waiting period.',
    this.history = const [],
  });

  static int parseBounded(
    String raw, {
    required int minimum,
    required int maximum,
    required String label,
  }) {
    final value = int.tryParse(raw.trim());
    if (value == null || value < minimum || value > maximum) {
      throw FormatException(
        MessageCode.fieldMustBeBetween(label, minimum, maximum),
      );
    }
    return value;
  }
}
