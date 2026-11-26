import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

import '../constants/app_colors.dart';
import '../services/driver_location_guard.dart';

/// Chip on the driver home map. Green "Sharing location" only while the phone
/// really can share it; when location is switched off or the permission is
/// gone it turns red and says so (it used to stay green on the last position).
class SharingLocationChip extends StatelessWidget {
  final ValueListenable<LocationIssue>? issue;
  const SharingLocationChip({super.key, this.issue});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<LocationIssue>(
    valueListenable: issue ?? DriverLocationGuard.issue,
    builder: (context, current, _) {
      final off = current != LocationIssue.none;
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        decoration: BoxDecoration(
          color: off ? AppColors.danger : AppColors.success,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x290D1B2A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              off
                  ? Icons.location_off_rounded
                  : Icons.radio_button_checked_rounded,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                off
                    ? context.l10n.locationSharingIsOff
                    : context.l10n.sharingLocation,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
