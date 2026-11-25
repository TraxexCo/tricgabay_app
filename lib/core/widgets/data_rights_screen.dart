import 'package:tricgabay_app/core/l10n/record_labels.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
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

  Widget _step(int number, String title, String body, {bool last = false}) =>
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '$number',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2, bottom: last ? 0 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      body,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _requestCard(Map<String, dynamic> request) {
    final status = request['status'] as String;
    final ready = status == 'fulfilled';
    final color = switch (status) {
      'fulfilled' => AppColors.success,
      'rejected' || 'cancelled' => AppColors.danger,
      _ => AppColors.warning,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ready ? AppColors.success : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  ready
                      ? Icons.download_done_rounded
                      : Icons.hourglass_top_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exportStatusLabel(context, status),
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      context.l10n.requestedOnValue(
                        recordDateTime(request['requested_at'] as String),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ready) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _download(request['id'] as String),
              icon: const Icon(Icons.download_rounded),
              label: Text(context.l10n.downloadExport),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.myData)),
    body: RefreshIndicator(
      onRefresh: () async {
        setState(() => _requests = _load());
        await _requests;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.yourDataYourRight,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.dataRightsIntro,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: .9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _step(
                  1,
                  context.l10n.dataStepRequestTitle,
                  context.l10n.dataStepRequestBody,
                ),
                _step(
                  2,
                  context.l10n.dataStepPrepareTitle,
                  context.l10n.dataStepPrepareBody,
                ),
                _step(
                  3,
                  context.l10n.dataStepDownloadTitle,
                  context.l10n.dataStepDownloadBody,
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _busy || !BackendConfig.isConfigured ? null : _request,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.file_download_outlined),
            label: Text(context.l10n.requestDataExport),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.yourRequests,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.l10n.refresh,
                onPressed: () => setState(() => _requests = _load()),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _requests,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  context.message(ErrorMessages.forError(snapshot.error!)),
                );
              }
              if (!snapshot.hasData) {
                return const SizedBox(height: 200, child: ListSkeleton());
              }
              if (snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.folder_open_outlined,
                        size: 34,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.noExportRequestsYet,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final request in snapshot.data!) _requestCard(request),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
