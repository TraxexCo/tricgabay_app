import 'package:tricgabay_app/core/l10n/record_labels.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'list_skeleton.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../config/backend_config.dart';
import '../services/error_messages.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

class DataRightsScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function()? loader;
  const DataRightsScreen({super.key, this.loader});
  @override
  State<DataRightsScreen> createState() => _DataRightsScreenState();
}

class _DataRightsScreenState extends State<DataRightsScreen> {
  late Future<List<Map<String, dynamic>>> _requests;
  String? _requestId;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _requests = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.loader != null) return widget.loader!();
    if (!BackendConfig.isConfigured) return [];
    final rows = await BackendConfig.client
        .from('data_subject_requests')
        .select()
        .eq('subject_id', BackendConfig.client.auth.currentUser!.id)
        .order('requested_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _request() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _requestId ??= const Uuid().v4();
      await BackendConfig.client.rpc(
        'request_own_data_export',
        params: {
          'p_request_id': _requestId,
          'p_language': Localizations.localeOf(context).languageCode == 'fil'
              ? 'fil'
              : 'en',
        },
      );
      _requestId = null;
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
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download(String id) async {
    try {
      final row = await BackendConfig.client
          .from('data_subject_exports')
          .select('payload')
          .eq('request_id', id)
          .single();
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(
                const JsonEncoder.withIndent('  ').convert(row['payload']),
              ),
              mimeType: 'application/json',
            ),
          ],
          fileNameOverrides: ['tric-gabay-personal-data.json'],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.myData)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          context
              .l10n
              .requestACopyOfYourAccountAndTripDataSupportPreparesTheExport,
        ),
        FilledButton(
          onPressed: _busy || !BackendConfig.isConfigured ? null : _request,
          child: Text(context.l10n.requestDataExport),
        ),
        TextButton(
          onPressed: () => setState(() => _requests = _load()),
          child: Text(context.l10n.refresh),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _requests,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                context.message(ErrorMessages.forError(snapshot.error!)),
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox(height: 260, child: ListSkeleton());
            }
            if (snapshot.data!.isEmpty) {
              return Text(context.l10n.noExportRequestsYet);
            }
            return Column(
              children: [
                for (final request in snapshot.data!)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exportStatusLabel(
                            context,
                            request['status'] as String,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(recordDateTime(request['requested_at'] as String)),
                        if (request['status'] == 'fulfilled')
                          TextButton(
                            onPressed: () => _download(request['id'] as String),
                            child: Text(context.l10n.downloadExport),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
