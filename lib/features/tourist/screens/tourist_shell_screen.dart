import 'package:tricgabay_app/core/l10n/app_l10n.dart';
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

  void _rememberTab(int index) {
    if (_tabHistory.last == index) return;
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
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                label: context.l10n.explore,
              ),
              RoleNavigationDestination(
                icon: Icons.search_outlined,
                selectedIcon: Icons.search,
                label: context.l10n.discover,
              ),
              RoleNavigationDestination(
                icon: Icons.luggage_outlined,
                selectedIcon: Icons.luggage,
                label: context.l10n.trips,
              ),
              RoleNavigationDestination(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: context.l10n.account,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
