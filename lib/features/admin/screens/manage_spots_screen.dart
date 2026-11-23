import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import '../../../core/motion/motion_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/session/app_session.dart';
import '../../../core/services/backend_repository.dart';
import '../../../models/tourist_spot_model.dart';
import '../../../core/constants/app_routes.dart';
import '../widgets/admin_ui.dart';
import 'manage_packages_screen.dart';

class ManageSpotsScreen extends ConsumerStatefulWidget {
  const ManageSpotsScreen({super.key});

  @override
  ConsumerState<ManageSpotsScreen> createState() => _ManageSpotsScreenState();
}

class _ManageSpotsScreenState extends ConsumerState<ManageSpotsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = MessageCode.all;
  String _query = '';
  final Set<String> _pendingSpotIds = {};
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (mounted) setState(() {});
    });

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _delete(TouristSpotModel spot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deletePlaceValue(spot.name)),
        content: Text(context.l10n.deletePlaceBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runSpotMutation(
      spot,
      () => AppSession.deleteSpot(spot.id),
      MessageCode.deletedValue(spot.name),
    );
  }

  Future<void> _runSpotMutation(
    TouristSpotModel spot,
    Future<void> Function() operation,
    String successMessage,
  ) async {
    if (_pendingSpotIds.contains(spot.id)) return;
    setState(() => _pendingSpotIds.add(spot.id));
    try {
      await operation();
      await AppSession.syncRemoteState();
      if (!mounted) return;
      showAdminToast(context, successMessage);
    } catch (error) {
      if (!mounted) return;
      showAdminToast(context, ErrorMessages.forError(error), error: true);
    } finally {
      if (mounted) setState(() => _pendingSpotIds.remove(spot.id));
    }
  }

  Future<void> _changeAvailability(TouristSpotModel spot) async {
    if (spot.isTemporarilyClosed) {
      await _runSpotMutation(
        spot,
        () => BackendRepository.setSpotAvailability(
          spotId: spot.id,
          closed: false,
        ),
        MessageCode.reopenedValue((spot.name).toString()),
      );
      return;
    }
    final reason = TextEditingController();
    DateTime? until;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.temporarilyCloseAttraction),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context
                      .l10n
                      .affectedTouristsAndAssignedDriversWillBeNotifiedExistingBookingsKeepAnAudit,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reason,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.l10n.closureReason,
                  ),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  scrollPadding: const EdgeInsets.all(96),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.expectedReopening),
                  subtitle: Text(
                    context.message(
                      until == null
                          ? MessageCode.unknownUntilManuallyReopened
                          : AppFormatters.dateTime(until!.toLocal()),
                    ),
                  ),
                  trailing: const Icon(Icons.event_outlined),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selected != null) {
                      setDialogState(
                        () => until = DateTime(
                          selected.year,
                          selected.month,
                          selected.day,
                          23,
                          59,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.keepOpen),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.closeAndNotify),
            ),
          ],
        ),
      ),
    );
    final explanation = reason.text.trim();
    reason.dispose();
    if (approved != true || !mounted) return;
    if (explanation.length < 5) {
      showAdminToast(
        context,
        context.l10n.enterAClearClosureReason,
        error: true,
      );
      return;
    }
    await _runSpotMutation(
      spot,
      () => BackendRepository.setSpotAvailability(
        spotId: spot.id,
        closed: true,
        reason: explanation,
        closedUntil: until,
      ),
      MessageCode.temporarilyClosedValue((spot.name).toString()),
    );
  }

  static const _categories = [
    MessageCode.all,
    MessageCode.heritage,
    MessageCode.nature,
    MessageCode.church,
    MessageCode.park,
    MessageCode.market,
    MessageCode.other,
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final onPlaces = _tabs.index == 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.places),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            ValueListenableBuilder<List<TouristSpotModel>>(
              valueListenable: AppSession.allSpots,
              builder: (context, spots, _) =>
                  Tab(text: l.placesTabValue(spots.length.toString())),
            ),
            ValueListenableBuilder<List<TourPackageModel>>(
              valueListenable: AppSession.tourPackages,
              builder: (context, packages, _) =>
                  Tab(text: l.packagesTabValue(packages.length.toString())),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          onPlaces ? '/admin/spots/form' : AppRoutes.packageForm,
        ),
        icon: Icon(
          onPlaces ? Icons.add_location_alt_outlined : Icons.add_rounded,
        ),
        label: Text(onPlaces ? l.newPlace : l.newPackage),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_places(context), const TourPackagesAdminList()],
      ),
    );
  }

  Widget _places(BuildContext context) {
    final l = context.l10n;
    return ValueListenableBuilder<List<TouristSpotModel>>(
      valueListenable: AppSession.allSpots,
      builder: (context, spots, _) {
        final query = _query.trim().toLowerCase();
        final filtered = spots.where((s) {
          final inCategory =
              _selectedCategory == MessageCode.all ||
              s.categoryLabel.toLowerCase() == _selectedCategory.toLowerCase();
          return inCategory &&
              (query.isEmpty || s.name.toLowerCase().contains(query));
        }).toList();
        final hidden = spots.where((s) => !s.isActive).length;
        final closed = spots.where((s) => s.isTemporarilyClosed).length;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: InputDecoration(
                    hintText: l.searchPlaces,
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  children: [
                    for (final c in _categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Text(context.message(c)),
                          selected: _selectedCategory == c,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = c),
                          selectedColor: AppColors.primary,
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedCategory == c
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                child: Text(
                  l.placesSummaryValue(
                    spots.length.toString(),
                    hidden.toString(),
                    closed.toString(),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  icon: Icons.place_outlined,
                  title: l.noTouristSpotsFound,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => FadeSlideIn.staggered(
                    index: index,
                    child: _spotCard(context, filtered[index]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _spotCard(BuildContext context, TouristSpotModel spot) {
    final l = context.l10n;
    final pending = _pendingSpotIds.contains(spot.id);
    return AdminPanel(
      padding: const EdgeInsets.all(10),
      onTap: pending
          ? null
          : () => context.push('/admin/spots/form', extra: spot),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 92,
              height: 92,
              child: Opacity(
                opacity: spot.isActive ? 1 : .45,
                child: SafeAppImage(
                  path: spot.imageUrls.isNotEmpty ? spot.imageUrls.first : '',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.message(spot.name),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.message(spot.categoryLabel),
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (spot.isTemporarilyClosed) ...[
                  const SizedBox(height: 6),
                  StatusBadge(
                    label: l.temporarilyClosed,
                    color: AppColors.dangerLight,
                    textColor: AppColors.danger,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Semantics(
                      label: l.touristVisibilityValue(spot.name),
                      value: context.message(
                        spot.isActive
                            ? MessageCode.visible
                            : MessageCode.hidden,
                      ),
                      enabled: !pending,
                      child: pending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Transform.scale(
                              scale: .85,
                              alignment: Alignment.centerLeft,
                              child: Switch(
                                value: spot.isActive,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppColors.success,
                                onChanged: (value) => _runSpotMutation(
                                  spot,
                                  () => BackendRepository.setSpotActive(
                                    spot.id,
                                    value,
                                  ),
                                  value
                                      ? MessageCode.isNowVisibleValue(spot.name)
                                      : MessageCode.isNowHiddenValue(spot.name),
                                ),
                              ),
                            ),
                    ),
                    Expanded(
                      child: Text(
                        spot.isActive
                            ? l.shownToTourists
                            : l.hiddenFromTourists,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: spot.isActive
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !pending,
            tooltip: l.placeOptions,
            onSelected: (value) async {
              if (value == 'edit') {
                context.push('/admin/spots/form', extra: spot);
              } else if (value == 'delete') {
                await _delete(spot);
              } else if (value == 'availability') {
                await _changeAvailability(spot);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l.edit),
                ),
              ),
              PopupMenuItem(
                value: 'availability',
                child: ListTile(
                  leading: Icon(
                    spot.isTemporarilyClosed
                        ? Icons.lock_open_rounded
                        : Icons.event_busy_outlined,
                  ),
                  title: Text(
                    context.message(
                      spot.isTemporarilyClosed
                          ? MessageCode.reopenAttraction
                          : MessageCode.closeTemporarily,
                    ),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                  title: Text(
                    l.delete,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
