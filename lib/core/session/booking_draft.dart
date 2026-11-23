/// The tour the tourist is putting together before it becomes a booking:
/// tour day and passenger requirements. Every tour starts and ends at the
/// tourism office (TourSchedule), so there is no pickup to choose. Stops
/// live in the catalog itinerary; the fare comes from the fare policy.
class BookingDraft {
  int passengerCount = 1;
  String luggageNotes = '';
  String accessibilityNeeds = '';

  /// The chosen tour start (required to book).
  DateTime? scheduledAt;

  void clear() {
    passengerCount = 1;
    luggageNotes = '';
    accessibilityNeeds = '';
    scheduledAt = null;
  }
}
