import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/role_navigation_bar.dart';
import '../../../core/prototype/prototype_session.dart';

class AdminShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AdminShellScreen({super.key, required this.navigationShell});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  final List<int> _tabHistory = [0];
  DateTime? _lastBackPressed;

  void _rememberTab(int index) {
    if (_tabHistory.last == index) return;
    _tabHistory.remove(index);
    _tabHistory.add(index);
  }

  void _selectTab(int index) {
    final required = switch (index) {
      1 => 'driver_compliance',
      2 => 'content',
      3 => 'operations',
      _ => null,
    };
    if (required != null && !PrototypeSession.hasAdminCapability(required)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Your administrator role does not include this area.',
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
    final now = DateTime.now();
    if (_lastBackPressed != null &&
        now.difference(_lastBackPressed!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPressed = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    _rememberTab(widget.navigationShell.currentIndex);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: widget.navigationShell,
        extendBody: true,
        bottomNavigationBar: RoleNavigationBar(
          currentIndex: widget.navigationShell.currentIndex,
          onSelected: _selectTab,
          destinations: const [
            RoleNavigationDestination(
              icon: Icons.space_dashboard_outlined,
              selectedIcon: Icons.space_dashboard,
              label: 'Overview',
            ),
            RoleNavigationDestination(
              icon: Icons.verified_user_outlined,
              selectedIcon: Icons.verified_user,
              label: 'Drivers',
            ),
            RoleNavigationDestination(
              icon: Icons.map_outlined,
              selectedIcon: Icons.map,
              label: 'Places',
            ),
            RoleNavigationDestination(
              icon: Icons.bar_chart_outlined,
              selectedIcon: Icons.bar_chart,
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}
