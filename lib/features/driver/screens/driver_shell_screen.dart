import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/role_navigation_bar.dart';

class DriverShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const DriverShellScreen({super.key, required this.navigationShell});

  @override
  State<DriverShellScreen> createState() => _DriverShellScreenState();
}

class _DriverShellScreenState extends State<DriverShellScreen> {
  final List<int> _tabHistory = [0];

  void _rememberTab(int index) {
    if (_tabHistory.last == index) return;
    _tabHistory.add(index);
  }

  void _selectTab(int index) {
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
      child: Scaffold(
        body: widget.navigationShell,
        extendBody: true,
        bottomNavigationBar: RoleNavigationBar(
          currentIndex: widget.navigationShell.currentIndex,
          onSelected: _selectTab,
          destinations: [
            RoleNavigationDestination(
              icon: Icons.radar_outlined,
              selectedIcon: Icons.radar,
              label: context.l10n.ride,
            ),
            RoleNavigationDestination(
              icon: Icons.assignment_outlined,
              selectedIcon: Icons.assignment,
              label: context.l10n.jobs,
            ),
            RoleNavigationDestination(
              icon: Icons.insights_outlined,
              selectedIcon: Icons.insights,
              label: context.l10n.earnings,
            ),
            RoleNavigationDestination(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: context.l10n.account,
            ),
          ],
        ),
      ),
    );
  }
}
