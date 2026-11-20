import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/config/backend_config.dart';
import 'driver_gcash_settings_screen.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/l10n/record_labels.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/account_widgets.dart';
import '../../../core/widgets/delete_account_button.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final driverId = PrototypeSession.currentDriverId;
    return AccountPage(
      title: l10n.driverAccount,
      roleLabel: l10n.driver,
      editRoute: AppRoutes.driverEditProfile,
      children: [
        Text(l10n.driverTools, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        AccountMenuTile(
          icon: Icons.person_outline_rounded,
          title: l10n.personalInformation,
          subtitle: l10n.updateYourDriverDetails,
          onTap: () => context.push(AppRoutes.driverEditProfile),
        ),
        AccountMenuTile(
          icon: Icons.receipt_long_outlined,
          title: l10n.tripHistory,
          subtitle: l10n.completedAndActiveBookings,
          onTap: () => context.go(AppRoutes.driverBookings),
        ),
        if (BackendConfig.isConfigured && driverId != null)
          AccountMenuTile(
            icon: Icons.account_balance_wallet_outlined,
            title: l10n.gcashDetails,
            subtitle: l10n.gcashVisibility,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DriverGcashSettingsScreen(driverId: driverId),
              ),
            ),
          ),
        ValueListenableBuilder(
          valueListenable: PrototypeSession.adminDrivers,
          builder: (context, drivers, _) {
            final driver = drivers
                .where((row) => row['id'] == PrototypeSession.currentDriverId)
                .firstOrNull;
            if (driver == null) return const SizedBox.shrink();
            final rating = driver['rating'] as num?;
            final plate = driver['plate'] as String?;
            final status = driver['status'] as String?;
            return Column(
              children: [
                if (plate != null && plate.isNotEmpty)
                  AccountMenuTile(
                    icon: Icons.directions_car_outlined,
                    title: l10n.plateNumber,
                    subtitle: plate,
                  ),
                AccountMenuTile(
                  icon: Icons.star_outline,
                  title: l10n.rating,
                  subtitle: rating != null && rating > 0
                      ? AppFormatters.rating(rating)
                      : l10n.notRated,
                ),
                if (status != null)
                  AccountMenuTile(
                    icon: Icons.verified_user_outlined,
                    title: l10n.verificationStatus,
                    subtitle: status == 'active'
                        ? l10n.approved
                        : accountStatusLabel(context, status),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(l10n.safetySupport, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        AccountMenuTile(
          icon: Icons.notifications_none_rounded,
          title: l10n.notifications,
          subtitle: l10n.bookingAndSystemUpdates,
          onTap: () => context.push(AppRoutes.driverNotifications),
        ),
        AccountMenuTile(
          icon: Icons.sos_outlined,
          title: l10n.emergencyHelp,
          subtitle: l10n.localContactsAndSos,
          color: AppColors.danger,
          onTap: () => context.push(AppRoutes.driverEmergency),
        ),
        AccountMenuTile(
          icon: Icons.help_outline_rounded,
          title: l10n.helpSupport,
          subtitle: l10n.sendASupportMessage,
          onTap: () => context.push(AppRoutes.driverFeedback),
        ),
        const AccountLanguageTile(),
        AccountMenuTile(
          icon: Icons.download_outlined,
          title: l10n.myData,
          subtitle: l10n.requestDataExport,
          onTap: () => context.push('/driver/data-rights'),
        ),
        const DeleteAccountButton(),
      ],
    );
  }
}
