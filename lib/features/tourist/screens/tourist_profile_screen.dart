import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/widgets/account_widgets.dart';
import '../../../core/widgets/delete_account_button.dart';

class TouristProfileScreen extends StatelessWidget {
  const TouristProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AccountPage(
      title: l10n.yourAccount,
      roleLabel: l10n.tourist,
      editRoute: AppRoutes.touristEditProfile,
      children: [
        Text(l10n.yourTravel, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        AccountMenuTile(
          icon: Icons.receipt_long_outlined,
          title: l10n.bookingHistory,
          subtitle: l10n.yourRidesAndReceipts,
          onTap: () => context.push(AppRoutes.touristBookingHistory),
        ),
        AccountMenuTile(
          icon: Icons.favorite_outline_rounded,
          title: l10n.savedPlaces,
          subtitle: l10n.destinationsYouLove,
          onTap: () => context.push(AppRoutes.favorites),
        ),
        AccountMenuTile(
          icon: Icons.tour_outlined,
          title: l10n.tourPackages,
          subtitle: l10n.readyMadeDaysOut,
          onTap: () => context.push(AppRoutes.tourPackages),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.supportSettings,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        AccountMenuTile(
          icon: Icons.notifications_none_rounded,
          title: l10n.notifications,
          subtitle: l10n.rideAndBookingUpdates,
          onTap: () => context.push(AppRoutes.touristNotifications),
        ),
        AccountMenuTile(
          icon: Icons.sos_outlined,
          title: l10n.emergencyHelp,
          subtitle: l10n.localContactsAndSos,
          color: AppColors.danger,
          onTap: () => context.push(AppRoutes.emergency),
        ),
        AccountMenuTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: l10n.sendFeedback,
          subtitle: l10n.tellUsWhatToImprove,
          onTap: () => context.push(AppRoutes.feedback),
        ),
        const AccountLanguageTile(),
        AccountMenuTile(
          icon: Icons.download_outlined,
          title: l10n.myData,
          subtitle: l10n.requestDataExport,
          onTap: () => context.push('/tourist/data-rights'),
        ),
        const DeleteAccountButton(),
      ],
    );
  }
}
