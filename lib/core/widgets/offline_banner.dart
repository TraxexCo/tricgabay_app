import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import '../services/connectivity_monitor.dart';
import '../services/error_messages.dart';

class OfflineBanner extends StatefulWidget {
  final ConnectivityMonitor monitor;
  final Future<void> Function() retry;
  const OfflineBanner({super.key, required this.monitor, required this.retry});
  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _retrying = false;
  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.monitor.refresh();
      await widget.retry();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.monitor,
    builder: (context, _) => widget.monitor.online == false
        ? Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: SafeArea(
              bottom: false,
              child: Semantics(
                liveRegion: true,
                label: context.l10n.offlineConnection,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(context.l10n.offlineSavedInformationMayBeShown),
                      TextButton(
                        onPressed: _retrying ? null : _retry,
                        child: Text(
                          context.message(
                            _retrying
                                ? MessageCode.retrying
                                : MessageCode.retryConnection,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink(),
  );
}
