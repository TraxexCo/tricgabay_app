import 'package:flutter/material.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

import '../services/consent_state.dart';
import '../services/driver_location_guard.dart';

/// Strip shown on every driver screen while the phone's location is off or the
/// app lost its location permission during online or trip time. The button
/// opens the system screen that fixes it. Once location works again the strip
/// briefly says the driver is back online.
class LocationIssueBanner extends StatelessWidget {
  const LocationIssueBanner({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      DriverLocationGuard.issue,
      DriverLocationGuard.restoredNotice,
      ConsentState.blocked,
    ]),
    builder: (context, _) {
      if (ConsentState.blocked.value) return const SizedBox.shrink();
      final issue = DriverLocationGuard.issue.value;
      final scheme = Theme.of(context).colorScheme;
      if (issue == LocationIssue.none) {
        if (!DriverLocationGuard.restoredNotice.value) {
          return const SizedBox.shrink();
        }
        return Material(
          color: scheme.primaryContainer,
          child: SafeArea(
            bottom: false,
            child: Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(context.l10n.locationIsBackYouAreOnlineAgain),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      final l10n = context.l10n;
      final serviceOff = issue == LocationIssue.serviceOff;
      return Material(
        color: scheme.errorContainer,
        child: SafeArea(
          bottom: false,
          child: Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    serviceOff
                        ? l10n.locationOffBannerMessage
                        : l10n.locationPermissionBannerMessage,
                  ),
                  TextButton(
                    onPressed: DriverLocationGuard.openSettingsForIssue,
                    child: Text(
                      serviceOff
                          ? l10n.openLocationSettings
                          : l10n.openAppSettings,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
