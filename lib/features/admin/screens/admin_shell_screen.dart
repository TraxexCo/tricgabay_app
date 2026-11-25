import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/role_navigation_bar.dart';
import '../../../core/session/app_session.dart';

class AdminShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AdminShellScreen({super.key, required this.navigationShell});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  final List<int> _tabHistory = [0];

  void _rememberTab(int index) {
    if (_tabHistory.last == index) return;
    _tabHistory.add(index);
  }

  void _selectTab(int index) {
    final required = switch (index) {
      1 => 'driver_compliance',
      2 => 'content',
      3 => 'operations',
      _ => null,
    };
    if (required != null && !AppSession.hasAdminCapability(required)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.yourAdministratorRoleDoesNotIncludeThisArea,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    final isCurrent = index == widget.navigationShell.currentIndex;
    if (!isCurrent) _rememberTab(index);
    widget.navigationShell.goBranch(index, initialLocation: isCurrent);
  }

  void _handleBack() {
    _rememberTab(widget.navigationShell.currentIndex);
    if (_tabHistory.length > 1) {
      _tabHistory.removeLast();
      widget.navigationShell.goBranch(_tabHistory.last);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    _rememberTab(widget.navigationShell.currentIndex);
    return PopScope(
      canPop:
          _tabHistory.length == 1 && widget.navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // Home tabs have light tops; keep the status-bar icons dark.
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: widget.navigationShell,
          extendBody: true,
          bottomNavigationBar: RoleNavigationBar(
            currentIndex: widget.navigationShell.currentIndex,
            onSelected: _selectTab,
            destinations: [
              RoleNavigationDestination(
                icon: Icons.space_dashboard_outlined,
                selectedIcon: Icons.space_dashboard,
                label: context.l10n.overview,
              ),
              RoleNavigationDestination(
                icon: Icons.verified_user_outlined,
                selectedIcon: Icons.verified_user,
                label: context.l10n.drivers,
              ),
              RoleNavigationDestination(
                icon: Icons.map_outlined,
                selectedIcon: Icons.map,
                label: context.l10n.places,
              ),
              RoleNavigationDestination(
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: context.l10n.reports,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
