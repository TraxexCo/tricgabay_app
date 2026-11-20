import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import '../../models/booking_model.dart';

class TripRuleException implements Exception {
  final String message;
  const TripRuleException(this.message);
  @override
  String toString() => message;
}

/// Client-side checks that give fast, friendly feedback before a request goes
/// to the server. Booking state transitions themselves are decided only by
/// the server's RPCs (see supabase/migrations); the app never simulates them.
class TripRules {
  static const policyText =
      MessageCode.theAgreedTourFareIsFixedThereIsNoSurgePricingPendingRequests;

  static void require(bool condition, String message) {
    if (!condition) throw TripRuleException(message);
  }

  /// Pro-rated charge an admin is offered as a starting point when resolving
  /// a trip that ended early: the share of confirmed stops.
  static int suggestedCharge(BookingModel b) => b.stops.isEmpty
      ? 0
      : (b.quotedCents * b.trip.confirmedStops / b.stops.length).round();
}
