import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/backend_config.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/services/gcash_repository.dart';

/// Explains why booking is blocked after an admin "not paid" ruling and links
/// to the trip whose fare is still owed. Renders nothing when nothing is owed.
class OutstandingFareBanner extends StatefulWidget {
  const OutstandingFareBanner({super.key, this.loader});

  /// Returns the owed booking's id, or null. Defaults to the server check.
  final Future<String?> Function()? loader;

  @override
  State<OutstandingFareBanner> createState() => _OutstandingFareBannerState();
}

class _OutstandingFareBannerState extends State<OutstandingFareBanner> {
  late final Future<String?> _owed =
      widget.loader?.call() ??
      (BackendConfig.isConfigured
          ? GcashRepository.outstandingFareBookingId()
          : Future.value());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<String?>(
      future: _owed,
      builder: (context, snapshot) {
        final bookingId = snapshot.data;
        if (bookingId == null) return const SizedBox.shrink();
        return Card(
          color: Theme.of(context).colorScheme.errorContainer,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.outstandingFareTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(l10n.outstandingFareBlocked),
                TextButton(
                  onPressed: () => context.push('/tourist/bookings/$bookingId'),
                  child: Text(l10n.outstandingFareAction),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
