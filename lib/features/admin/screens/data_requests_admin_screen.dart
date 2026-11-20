import 'package:tricgabay_app/core/l10n/record_labels.dart';
import 'package:flutter/material.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/error_messages.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

class DataRequestsAdminScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function()? loader;
  const DataRequestsAdminScreen({super.key, this.loader});
  @override
  State<DataRequestsAdminScreen> createState() =>
      _DataRequestsAdminScreenState();
}

class _DataRequestsAdminScreenState extends State<DataRequestsAdminScreen> {
  late Future<List<Map<String, dynamic>>> _requests;
  String? _busy;
  int _throughPage = 0;
  bool _hasMore = false;
  @override
  void initState() {
    super.initState();
    _requests = _load();
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

  Future<void> _fulfil(String id) async {
    if (_busy != null) return;
    setState(() => _busy = id);
    try {
      await BackendConfig.client.rpc(
        'fulfil_data_subject_request',
        params: {'p_request_id': id},
      );
      if (mounted) setState(() => _requests = _load());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.dataExportRequests)),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _requests,
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
            setState(() => _requests = _load());
            await _requests;
          },
          child: ListView(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  context
                      .l10n
                      .exportsAreDeliveredOnlyToTheRequestingAccountFulfilmentIsAudited,
                ),
              ),
              for (final row in snapshot.data!)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.message(row['id'] as String)),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exportStatusLabel(context, row['status'] as String),
                          ),
                          Text(
                            context.l10n.twoPartSummary(
                              recordDateTime(row['requested_at'].toString()),
                              row['notice_language'] == 'fil'
                                  ? context.l10n.filipino
                                  : context.l10n.english,
                            ),
                          ),
                        ],
                      ),
                      if (row['status'] == 'pending')
                        TextButton(
                          onPressed: _busy == null
                              ? () => _fulfil(row['id'] as String)
                              : null,
                          child: Text(context.l10n.prepareExport),
                        ),
                    ],
                  ),
                ),
              if (_hasMore)
                TextButton(
                  onPressed: _busy == null
                      ? () => setState(() {
                          _throughPage++;
                          _requests = _load();
                        })
                      : null,
                  child: Text(context.l10n.loadMore),
                ),
            ],
          ),
        );
      },
    ),
  );
}
