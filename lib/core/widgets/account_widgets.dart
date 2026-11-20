import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../l10n/app_l10n.dart';
import '../session/app_session.dart';
import 'language_selection.dart';
import 'shared_widgets.dart';

class AccountIdentityCard extends StatelessWidget {
  const AccountIdentityCard({super.key, required this.roleLabel});

  final String roleLabel;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: AppSession.currentAccount,
    builder: (context, account, _) {
      final name = account?.name.trim();
      final email = account?.email.trim();
      final textTheme = Theme.of(context).textTheme;
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const ExcludeSemantics(child: AppLogo()),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name != null && name.isNotEmpty)
                    Text(
                      name,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  if (email != null && email.isNotEmpty)
                    Text(
                      email,
                      style: textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    roleLabel,
                    style: textTheme.labelMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.title,
    required this.roleLabel,
    required this.editRoute,
    required this.children,
  });

  final String title;
  final String roleLabel;
  final String editRoute;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [
        IconButton(
          tooltip: context.l10n.editProfile,
          onPressed: () => context.push(editRoute),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          AccountIdentityCard(roleLabel: roleLabel),
          const SizedBox(height: 16),
          ...children,
          const AccountLogoutButton(),
        ],
      ),
    ),
  );
}

class AccountMenuTile extends StatelessWidget {
  const AccountMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    ),
  );
}

class AccountLogoutButton extends StatelessWidget {
  const AccountLogoutButton({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () async {
      final accountId = AppSession.authenticatedUserId;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.logOutLabel),
          content: Text(
            context.l10n.areYouSureYouWantToLogOutOfApp(AppBrand.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.logOut),
            ),
          ],
        ),
      );
      if (confirm != true ||
          !context.mounted ||
          AppSession.authenticatedUserId != accountId) {
        return;
      }
      await AppSession.signOut();
      if (context.mounted) context.go(AppRoutes.login);
    },
    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
    icon: const Icon(Icons.logout_rounded),
    label: Text(context.l10n.logOut),
  );
}

class AccountLanguageTile extends StatelessWidget {
  const AccountLanguageTile({super.key});

  @override
  Widget build(BuildContext context) => AccountMenuTile(
    icon: Icons.language_rounded,
    title: context.l10n.language,
    subtitle: Localizations.localeOf(context).languageCode == 'fil'
        ? context.l10n.filipino
        : context.l10n.english,
    onTap: () => showModalBottomSheet<void>(
      context: context,
      builder: (_) => const LanguageSelection(),
    ),
  );
}
