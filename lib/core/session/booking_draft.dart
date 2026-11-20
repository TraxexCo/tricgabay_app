import 'package:flutter/foundation.dart';

/// The trip the tourist is putting together before it becomes a booking:
/// pickup point and passenger requirements. Destinations live in the catalog
/// itinerary; the fare comes from the fare policy.
class BookingDraft {
  BookingDraft(this.pickupAddress);

  /// Chosen pickup label; null means "current GPS location".
  final ValueNotifier<String?> pickupAddress;
  double? pickupLat;
  double? pickupLng;
  int passengerCount = 1;
  String luggageNotes = '';
  String accessibilityNeeds = '';

  /// Null books now; otherwise a scheduled pickup.
  DateTime? scheduledAt;

  void clear() {
    pickupAddress.value = null;
    pickupLat = null;
    pickupLng = null;
    passengerCount = 1;
    luggageNotes = '';
    accessibilityNeeds = '';
    scheduledAt = null;
  }
}
