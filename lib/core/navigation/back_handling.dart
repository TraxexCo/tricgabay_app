import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// [MaterialApp.onNavigationNotification] for the whole app.
///
/// With Android predictive back (`enableOnBackInvokedCallback="true"`), the OS
/// only sends Back to Flutter while Flutter says it handles Back. Flutter's
/// default answer is the last navigation notification it saw, and each bottom
/// tab owns a navigator that reports "nothing to pop" whenever it is built.
/// That report overwrote the correct answer, so Android closed the app instead
/// of going back a page.
///
/// Keeping Back inside Flutter is safe: the router walks back through pushed
/// pages and tab history, and when nothing is left Flutter calls
/// [SystemNavigator.pop] itself, which closes the app from the home tab.
bool keepBackInFlutter(NavigationNotification notification) {
  SystemNavigator.setFrameworkHandlesBack(true);
  return true;
}
