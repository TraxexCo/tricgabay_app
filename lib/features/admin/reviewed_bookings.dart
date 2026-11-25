import '../../models/booking_model.dart';

/// The bookings that have a tourist review, newest review first.
///
/// A booking counts as reviewed when it carries a rating; completed bookings
/// nobody has rated are left out. The order follows when the review was saved
/// (falling back to when the trip completed, then was booked, for a review
/// whose time is unknown); equal times keep a stable order by booking id.
List<BookingModel> reviewedBookings(Iterable<BookingModel> bookings) {
  DateTime reviewedWhen(BookingModel b) =>
      b.driverReviewedAt ?? b.completedAt ?? b.createdAt;
  final reviewed = [
    for (final booking in bookings)
      if (booking.driverRating != null) booking,
  ];
  reviewed.sort((a, b) {
    final byTime = reviewedWhen(b).compareTo(reviewedWhen(a));
    return byTime != 0 ? byTime : b.id.compareTo(a.id);
  });
  return reviewed;
}

/// A review's rating as a whole number of stars from 0 to 5.
int starCount(double rating) => rating.round().clamp(0, 5);
