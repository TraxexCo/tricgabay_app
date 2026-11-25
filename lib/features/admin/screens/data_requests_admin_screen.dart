import 'package:flutter/material.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:tricgabay_app/core/l10n/record_labels.dart';

import '../../../core/config/backend_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/error_messages.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/list_skeleton.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../widgets/admin_ui.dart';

/// Requests from tourists and drivers for a copy of their own data. Preparing
/// an export builds the file on the server; only the account that asked can
/// download it.
class DataRequestsAdminScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function()? loader;
  const DataRequestsAdminScreen({super.key, this.loader});
  @override
  State<DataRequestsAdminScreen> createState() =>
      _DataRequestsAdminScreenState();
}

class _DataRequestsAdminScreenState extends State<DataRequestsAdminScreen> {
  static List<Map<String, dynamic>>? _cache;

  List<Map<String, dynamic>>? _rows = _cache;
  Object? _error;
  String? _busy;
  int _throughPage = 0;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.loader != null) return widget.loader!();
    final visibleCount = (_throughPage + 1) * 50;
    final rows = List<Map<String, dynamic>>.from(
      await BackendConfig.client
          .from('data_subject_requests')
          .select()
          .order('status', ascending: false)
          .order('requested_at', ascending: false)
          .order('id', ascending: false)
          .range(0, visibleCount),
    );
    _hasMore = rows.length > visibleCount;
    return rows.take(visibleCount).toList();
  }

  Future<void> _refresh() async {
    try {
      final rows = await _load();
      if (widget.loader == null) _cache = rows;
      if (mounted) {
        setState(() {
          _rows = rows;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _fulfil(String id) async {
    if (_busy != null) return;
    setState(() => _busy = id);
    try {
      if (widget.loader == null) {
        await BackendConfig.client.rpc(
          'fulfil_data_subject_request',
          params: {'p_request_id': id},
        );
      }
      if (!mounted) return;
      showAdminToast(context, context.l10n.dataRequestPreparedToast);
      await _refresh();
    } catch (error) {
      if (mounted) {
        showAdminToast(context, ErrorMessages.forError(error), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// The requester's name, from the account lists the admin already has.
  String? _nameFor(String? subjectId) {
    if (subjectId == null) return null;
    for (final row in [
      ...AppSession.adminTourists.value,
      ...AppSession.adminDrivers.value,
    ]) {
      if (row['id'] == subjectId) {
        final name = (row['name'] ?? row['full_name'])?.toString().trim();
        if (name != null && name.isNotEmpty) return name;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rows = _rows;
    return Scaffold(
      appBar: AppBar(title: Text(l.dataExportRequests)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: () {
          if (rows == null && _error != null) {
            return ScrollableEmptyState(
              icon: Icons.cloud_off_rounded,
              title: context.message(ErrorMessages.forError(_error!)),
              subtitle: l.pullDownToTryAgain,
            );
          }
          if (rows == null) return const ListSkeleton();
          if (rows.isEmpty) {
            return ScrollableEmptyState(
              icon: Icons.folder_shared_outlined,
              title: l.dataRequestsEmptyTitle,
              subtitle: l.dataRequestsEmptyBody,
            );
          }
          final pending = rows.where((r) => r['status'] == 'pending').toList();
          final done = rows.where((r) => r['status'] != 'pending').toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              AdminPanel(
                color: AppColors.surfaceVariant,
                borderColor: AppColors.surfaceVariant,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.exportsAreDeliveredOnlyToTheRequestingAccountFulfilmentIsAudited,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AdminSectionTitle(
                l.dataRequestsWaiting,
                trailing: CountBadge(pending.length),
              ),
              if (pending.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    l.dataRequestsNoneWaiting,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              for (final row in pending) _card(context, row),
              if (done.isNotEmpty) ...[
                const SizedBox(height: 8),
                AdminSectionTitle(l.dataRequestsDone),
                for (final row in done) _card(context, row),
              ],
              if (_hasMore)
                TextButton(
                  onPressed: _busy == null
                      ? () {
                          _throughPage++;
                          _refresh();
                        }
                      : null,
                  child: Text(l.loadMore),
                ),
            ],
          );
        }(),
      ),
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> row) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final id = row['id'] as String;
    final status = row['status'] as String;
    final pending = status == 'pending';
    final name = _nameFor(row['subject_id'] as String?);
    final tone = pending
        ? AppColors.warning
        : status == 'fulfilled'
        ? AppColors.success
        : AppColors.textSecondary;
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                pending
                    ? Icons.hourglass_top_rounded
                    : status == 'fulfilled'
                    ? Icons.download_done_rounded
                    : Icons.block_rounded,
                tone,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? l.dataRequestAccount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l.twoPartSummary(
                        recordDateTime(row['requested_at'].toString()),
                        row['notice_language'] == 'fil'
                            ? l.filipino
                            : l.english,
                      ),
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(
                      label: exportStatusLabel(context, status),
                      color: tone.withValues(alpha: .12),
                      textColor: tone,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy == null ? () => _fulfil(id) : null,
                icon: _busy == id
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.inventory_2_outlined),
                label: Text(l.prepareExport),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
