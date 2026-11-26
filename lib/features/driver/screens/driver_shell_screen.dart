import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/battery_optimization_service.dart';
import '../../../core/services/consent_state.dart';
import '../../../core/widgets/role_navigation_bar.dart';

class DriverShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const DriverShellScreen({super.key, required this.navigationShell});

  @override
  State<DriverShellScreen> createState() => _DriverShellScreenState();
}

class _DriverShellScreenState extends State<DriverShellScreen> {
  final List<int> _tabHistory = [0];

  @override
  void initState() {
    super.initState();
    unawaited(_offerBatteryExemption());
  }

  /// One-time prompt: phones that restrict background apps can pause the
  /// driver's live location. Asked once, after the privacy notice, and the
  /// status stays available from the account page.
  Future<void> _offerBatteryExemption() async {
    await ConsentState.whenClear();
    if (!mounted || !await BatteryOptimizationService.shouldPrompt()) return;
    if (!mounted) return;
    await BatteryOptimizationService.markPrompted();
    if (!mounted) return;
    final l10n = context.l10n;
    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.batteryPromptTitle),
        content: Text(l10n.batteryPromptBody(AppBrand.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.batteryPromptNotNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.batteryPromptOpenSettings),
          ),
        ],
      ),
    );
    if (open == true) await BatteryOptimizationService.openSettings();
  }

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
      ),
    );
  }
}
