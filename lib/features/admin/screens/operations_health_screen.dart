import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/motion.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/error_messages.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

class OperationsHealthScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> Function()? loader;
  const OperationsHealthScreen({super.key, this.loader});
  @override
  State<OperationsHealthScreen> createState() => _OperationsHealthScreenState();
}

class _OperationsHealthScreenState extends State<OperationsHealthScreen> {
  late Future<Map<String, dynamic>> _health;
  @override
  void initState() {
    super.initState();
    _health = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    if (widget.loader != null) return widget.loader!();
    return Map<String, dynamic>.from(
      await BackendConfig.client.rpc('get_operations_health'),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.serviceHealth)),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _health,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              context.message(ErrorMessages.forError(snapshot.error!)),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _health = _load());
            await _health;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            children: [
              for (final (i, entry) in snapshot.data!.entries.indexed)
                FadeSlideIn.staggered(
                  index: i,
                  child: _HealthTile(
                    label: context.message(switch (entry.key) {
                      'failed_payments' => MessageCode.failedPayments,
                      'blocked_expiry' => MessageCode.blockedCheckoutExpiry,
                      'cron_failures' => MessageCode.scheduledJobFailures,
                      'stale_online_drivers' => MessageCode.staleOnlineDrivers,
                      _ => MessageCode.notificationDeliveryFailures,
                    }),
                    icon: switch (entry.key) {
                      'failed_payments' => Icons.credit_card_off_outlined,
                      'blocked_expiry' => Icons.timer_off_outlined,
                      'cron_failures' => Icons.schedule_outlined,
                      'stale_online_drivers' => Icons.wifi_off_rounded,
                      _ => Icons.notifications_off_outlined,
                    },
                    count: (entry.value as num?)?.toInt() ?? 0,
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  context
                      .l10n
                      .criticalConditionsAlsoAppearInOperationalAlertsInvestigateBeforeClearingAnAlert,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// One health signal: green when clear, red with a count when something
/// needs attention.
class _HealthTile extends StatelessWidget {
  const _HealthTile({
    required this.label,
    required this.icon,
    required this.count,
  });

  final String label;
  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ok = count == 0;
    final color = ok ? AppColors.success : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(label),
          trailing: AnimatedContainer(
            duration: Motion.medium,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ok
                ? Icon(Icons.check_rounded, color: color, size: 18)
                : Text(
                    '$count',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}
