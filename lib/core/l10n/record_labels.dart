import 'package:flutter/widgets.dart';
import 'app_l10n.dart';
import '../utils/formatters.dart';
import '../../models/booking_model.dart';
import '../../models/tourist_spot_model.dart';
import '../../models/trip_record.dart';

/// Wire identifiers are translated explicitly at the presentation boundary.
/// Unknown server values use a forward-compatible label, never source matching.
String exportStatusLabel(BuildContext context, String status) =>
    switch (status) {
      'pending' => context.l10n.exportPending,
      'fulfilled' => context.l10n.exportFulfilled,
      'rejected' => context.l10n.exportRejected,
      _ => context.l10n.updateRequired,
    };

String recordDateTime(String value) {
  final date = DateTime.tryParse(value);
  return date == null ? value : AppFormatters.dateTime(date.toLocal());
}

String bookingStatusLabel(BuildContext context, BookingStatus status) =>
    switch (status) {
      BookingStatus.unknown => context.l10n.unknown,
      BookingStatus.paymentPending => context.l10n.paymentPending,
      BookingStatus.scheduled => context.l10n.scheduled,
      BookingStatus.pending => context.l10n.pending,
      BookingStatus.accepted => context.l10n.accepted,
      BookingStatus.replacementPending => context.l10n.replacementNeeded,
      BookingStatus.ongoing => context.l10n.ongoing,
      BookingStatus.completed => context.l10n.completed,
      BookingStatus.cancelled => context.l10n.cancelled,
    };

String paymentStatusLabel(BuildContext context, PaymentStatus status) =>
    switch (status) {
      PaymentStatus.unknown => context.l10n.unknown,
      PaymentStatus.unpaid => context.l10n.unpaid,
      PaymentStatus.checkoutCreated => context.l10n.paymentCheckoutCreated,
      PaymentStatus.processing => context.l10n.paymentProcessing,
      PaymentStatus.failed => context.l10n.paymentFailed,
      PaymentStatus.awaitingConfirmation =>
        context.l10n.paymentAwaitingConfirmation,
      PaymentStatus.gcashAwaitingConfirmation =>
        context.l10n.gcashAwaitingDriver,
      PaymentStatus.disputed => context.l10n.gcashDisputed,
      PaymentStatus.underReview => context.l10n.underReview,
      PaymentStatus.paid => context.l10n.paid,
      PaymentStatus.waived => context.l10n.waived,
      PaymentStatus.refundDue => context.l10n.paymentRefundDue,
      PaymentStatus.refundProcessing => context.l10n.paymentRefundProcessing,
      PaymentStatus.partiallyRefunded => context.l10n.partiallyRefunded,
      PaymentStatus.refunded => context.l10n.refunded,
    };

String paymentMethodLabel(BuildContext context, PaymentMethod method) =>
    switch (method) {
      PaymentMethod.unknown => context.l10n.unknown,
      PaymentMethod.cash => context.l10n.cash,
      PaymentMethod.online => context.l10n.online,
      PaymentMethod.gcashDirect => context.l10n.gcashSendToDriver,
    };

String tripActorLabel(BuildContext context, TripActor actor) => switch (actor) {
  TripActor.unknown => context.l10n.unknown,
  TripActor.tourist => context.l10n.tourist,
  TripActor.driver => context.l10n.driver,
  TripActor.admin => context.l10n.administrator,
  TripActor.system => context.l10n.actorSystem,
};

String spotCategoryLabel(BuildContext context, SpotCategory category) =>
    switch (category) {
      SpotCategory.heritage => context.l10n.heritage,
      SpotCategory.nature => context.l10n.nature,
      SpotCategory.church => context.l10n.church,
      SpotCategory.park => context.l10n.park,
      SpotCategory.market => context.l10n.market,
      SpotCategory.other => context.l10n.other,
    };

String accountStatusLabel(BuildContext context, String status) =>
    switch (status) {
      'active' => context.l10n.active,
      'suspended' => context.l10n.suspended,
      'pending' => context.l10n.pending,
      'approved' => context.l10n.approved,
      'rejected' => context.l10n.rejected,
      'online' => context.l10n.online,
      'offline' => context.l10n.offline,
      'busy' => context.l10n.statusBusy,
      _ => context.l10n.updateRequired,
    };
