import 'package:flutter/material.dart';
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
            children: [
              for (final entry in snapshot.data!.entries)
                ListTile(
                  title: Text(
                    context.message(switch (entry.key) {
                      'failed_payments' => MessageCode.failedPayments,
                      'blocked_expiry' => MessageCode.blockedCheckoutExpiry,
                      'cron_failures' => MessageCode.scheduledJobFailures,
                      'stale_online_drivers' => MessageCode.staleOnlineDrivers,
                      _ => MessageCode.notificationDeliveryFailures,
                    }),
                  ),
                  trailing: Text(
                    context.message('${entry.value}'),
                    style: TextStyle(
                      color: entry.value == 0 ? Colors.green : Colors.red,
                    ),
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
