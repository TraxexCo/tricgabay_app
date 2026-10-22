import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _lastBackPressed;

  void _rememberTab(int index) {
    if (_tabHistory.last == index) return;
    _tabHistory.remove(index);
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
              icon: Icons.radar_outlined,
              selectedIcon: Icons.radar,
              label: 'Ride',
            ),
            RoleNavigationDestination(
              icon: Icons.assignment_outlined,
              selectedIcon: Icons.assignment,
              label: 'Jobs',
            ),
            RoleNavigationDestination(
              icon: Icons.insights_outlined,
              selectedIcon: Icons.insights,
              label: 'Earnings',
            ),
            RoleNavigationDestination(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
