import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'dart:async';
import '../../../core/widgets/remote_page_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';

class ManageDriversScreen extends ConsumerStatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  ConsumerState<ManageDriversScreen> createState() =>
      _ManageDriversScreenState();
}

class _ManageDriversScreenState extends ConsumerState<ManageDriversScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  bool _isBlocked(Map<String, dynamic> driver) {
    final status = driver['status']?.toString();
    if (status == 'suspended' || status == 'rejected') return true;
    final raw = driver['matchingBlockedUntil']?.toString();
    final until = raw == null ? null : DateTime.tryParse(raw);
    return until != null && until.isAfter(DateTime.now());
  }

  List<Map<String, dynamic>> _matching(List<Map<String, dynamic>> drivers) {
    final query = _query;
    if (query.isEmpty) return drivers;
    return drivers.where((driver) {
      return [
        driver['name'],
        driver['plate'],
        driver['franchise'],
        driver['serviceAreaName'],
      ].any((value) => value.toString().toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        bottomNavigationBar: const RemotePageControls(directory: true),
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(context.l10n.driverCompliance),
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.review),
              Tab(text: context.l10n.active),
              Tab(text: context.l10n.blocked),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: AppTextField(
                controller: _search,
                label: context.l10n.searchDrivers,
                hint: context.l10n.namePlateFranchiseOrServiceArea,
                prefixIcon: Icons.search,
                onChanged: (value) {
                  _debounce?.cancel();
                  final query = value.trim().toLowerCase();
                  if (query == _query) return;
                  _debounce = Timer(const Duration(milliseconds: 250), () {
                    if (mounted) setState(() => _query = query);
                  });
                },
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: AppSession.adminDrivers,
                builder: (context, allDrivers, _) {
                  final drivers = _matching(allDrivers);
                  final review = drivers
                      .where(
                        (driver) =>
                            !_isBlocked(driver) && driver['status'] != 'active',
                      )
                      .toList();
                  final active = drivers
                      .where(
                        (driver) =>
                            !_isBlocked(driver) && driver['status'] == 'active',
                      )
                      .toList();
                  final blocked = drivers.where(_isBlocked).toList();
                  return TabBarView(
                    children: [
                      _list(review, MessageCode.noDriversAwaitingReview),
                      _list(active, MessageCode.noEligibleActiveDrivers),
                      _list(blocked, MessageCode.noBlockedDrivers),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<Map<String, dynamic>> drivers, String emptyTitle) {
    if (drivers.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.badge_outlined,
        title: emptyTitle,
        subtitle: context.l10n.driverComplianceRecordsWillAppearHere,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 104),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driver = drivers[index];
        final reliability =
            (driver['reliabilityScore'] as num?)?.toDouble() ?? 100;
        final blocked = _isBlocked(driver);
        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => context.push('/admin/drivers/${driver['id']}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      (blocked ? AppColors.danger : AppColors.primary)
                          .withValues(alpha: .10),
                  child: Text(
                    context.message(
                      driver['name'].toString().isEmpty
                          ? '?'
                          : driver['name'].toString()[0],
                    ),
                    style: TextStyle(
                      color: blocked ? AppColors.danger : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.message('${driver['name']}'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        context.l10n.twoPartDetails(
                          context.message((driver['plate'] ?? '').toString()),
                          context.message(
                            (driver['serviceAreaName'] ??
                                    MessageCode.areaUnverified)
                                .toString(),
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.reliabilitySeatsValue(
                          context.message(
                            (reliability.toStringAsFixed(0)).toString(),
                          ),
                          context.message(
                            (driver['passengerCapacity'] ?? 3).toString(),
                          ),
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        );
      },
    );
  }
}
