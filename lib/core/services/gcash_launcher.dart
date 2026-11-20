import 'package:url_launcher/url_launcher.dart';

class GcashLauncher {
  const GcashLauncher();

  // If GCash documents a send-money prefill link, build it here.
  static final _appUri = Uri.parse('gcash://');

  Future<bool> isGcashInstalled() async {
    try {
      return await canLaunchUrl(_appUri);
    } catch (_) {
      return false;
    }
  }

  Future<bool> openGcash() async {
    try {
      return await launchUrl(_appUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
