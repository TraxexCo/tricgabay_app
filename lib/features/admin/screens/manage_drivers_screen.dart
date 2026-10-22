import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/prototype/prototype_session.dart';
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

  @override
  void dispose() {
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
    final query = _search.text.trim().toLowerCase();
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Driver compliance'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Review'),
              Tab(text: 'Active'),
              Tab(text: 'Blocked'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: AppTextField(
                controller: _search,
                label: 'Search drivers',
                hint: 'Name, plate, franchise, or service area',
                prefixIcon: Icons.search,
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: PrototypeSession.adminDrivers,
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
                      _list(review, 'No drivers awaiting review'),
                      _list(active, 'No eligible active drivers'),
                      _list(blocked, 'No blocked drivers'),
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
        subtitle: 'Driver compliance records will appear here.',
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
                    driver['name'].toString().isEmpty
                        ? '?'
                        : driver['name'].toString()[0],
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
                        '${driver['name']}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${driver['plate'] ?? ''} • ${driver['serviceAreaName'] ?? 'Area unverified'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reliability.toStringAsFixed(0)}% reliability • ${driver['passengerCapacity'] ?? 3} seats',
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
