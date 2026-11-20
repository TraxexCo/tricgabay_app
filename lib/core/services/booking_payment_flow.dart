import 'error_messages.dart';

/// Checkout initiation never changes authoritative booking/payment state.
Future<void> openBookingPayment({
  required String bookingId,
  required Future<String> Function(String) createCheckout,
  required Future<bool> Function(Uri) launch,
}) async {
  final uri = Uri.parse(await createCheckout(bookingId));
  if (uri.scheme != 'https' ||
      uri.host != 'checkout.paymongo.com' ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort) {
    throw const ClientOperationException(ClientFailure.checkoutUntrusted);
  }
  if (!await launch(uri)) {
    throw const ClientOperationException(ClientFailure.checkoutLaunch);
  }
}
