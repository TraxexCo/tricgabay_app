import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/role_navigation_bar.dart';

class TouristShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const TouristShellScreen({super.key, required this.navigationShell});

  @override
  State<TouristShellScreen> createState() => _TouristShellScreenState();
}

class _TouristShellScreenState extends State<TouristShellScreen> {
  final List<int> _tabHistory = [0];
  DateTime? _lastBackPressed;

  void _rememberTab(int index) {
    if (_tabHistory.last == index) return;
    _tabHistory.remove(index);
    _tabHistory.add(index);
  }

  void _selectTab(int index) {
    final isCurrentTab = index == widget.navigationShell.currentIndex;
    if (!isCurrentTab) _rememberTab(index);
    widget.navigationShell.goBranch(index, initialLocation: isCurrentTab);
  }

  void _handleBack() {
    final currentIndex = widget.navigationShell.currentIndex;
    _rememberTab(currentIndex);

    if (_tabHistory.length > 1) {
      _tabHistory.removeLast();
      widget.navigationShell.goBranch(_tabHistory.last);
      return;
    }

    final now = DateTime.now();
    final shouldExit =
        _lastBackPressed != null &&
        now.difference(_lastBackPressed!) < const Duration(seconds: 2);

    if (shouldExit) {
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
              icon: Icons.explore_outlined,
              selectedIcon: Icons.explore,
              label: 'Explore',
            ),
            RoleNavigationDestination(
              icon: Icons.search_outlined,
              selectedIcon: Icons.search,
              label: 'Discover',
            ),
            RoleNavigationDestination(
              icon: Icons.luggage_outlined,
              selectedIcon: Icons.luggage,
              label: 'Trips',
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
