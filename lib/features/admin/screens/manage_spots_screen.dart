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

class ManageSpotsScreen extends ConsumerStatefulWidget {
  const ManageSpotsScreen({super.key});

  @override
  ConsumerState<ManageSpotsScreen> createState() => _ManageSpotsScreenState();
}

class _ManageSpotsScreenState extends ConsumerState<ManageSpotsScreen> {
  String _selectedCategory = MessageCode.all;
  final Set<String> _pendingSpotIds = {};

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.message(successMessage))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.message(ErrorMessages.forError(error))),
          action: SnackBarAction(
            label: context.l10n.refresh,
            onPressed: () => AppSession.syncRemoteState(),
          ),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterAClearClosureReason)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      appBar: AppBar(title: Text(context.l10n.touristSpots)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/spots/form'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children:
                  [
                        MessageCode.all,
                        MessageCode.heritage,
                        MessageCode.nature,
                        MessageCode.church,
                        MessageCode.park,
                        MessageCode.market,
                        MessageCode.other,
                      ]
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              context.message(c),
                              style: TextStyle(
                                color: _selectedCategory == c
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            selected: _selectedCategory == c,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = c);
                              }
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<TouristSpotModel>>(
              valueListenable: AppSession.allSpots,
              builder: (context, spots, _) {
                final filteredSpots = _selectedCategory == MessageCode.all
                    ? spots
                    : spots
                          .where(
                            (s) =>
                                s.categoryLabel.toLowerCase() ==
                                _selectedCategory.toLowerCase(),
                          )
                          .toList();

                if (filteredSpots.isEmpty) {
                  return Center(child: Text(context.l10n.noTouristSpotsFound));
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 104),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.sizeOf(context).width < 412 ||
                            MediaQuery.textScalerOf(context).scale(14) > 20
                        ? 1
                        : 2,
                    mainAxisExtent:
                        240 + MediaQuery.textScalerOf(context).scale(14) * 5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredSpots.length,
                  itemBuilder: (context, index) => FadeSlideIn.staggered(
                    index: index,
                    child: Builder(
                      builder: (context) {
                        final spot = filteredSpots[index];
                        final pending = _pendingSpotIds.contains(spot.id);
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: SafeAppImage(
                                        path: spot.imageUrls.isNotEmpty
                                            ? spot.imageUrls.first
                                            : '',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (!spot.isActive)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            context.l10n.hidden,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (spot.isTemporarilyClosed)
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.danger,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            context.l10n.temporarilyClosed,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.message(spot.name),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // Category, and what the switch
                                    // below currently does.
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: context.message(
                                              spot.categoryLabel,
                                            ),
                                          ),
                                          const TextSpan(text: ' · '),
                                          TextSpan(
                                            text: context.message(
                                              spot.isActive
                                                  ? MessageCode.visible
                                                  : MessageCode.hidden,
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: spot.isActive
                                                  ? AppColors.success
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Semantics(
                                          label: context.l10n
                                              .touristVisibilityValue(
                                                context.message(
                                                  (spot.name).toString(),
                                                ),
                                              ),
                                          value: context.message(
                                            spot.isActive
                                                ? MessageCode.visible
                                                : MessageCode.hidden,
                                          ),
                                          enabled: !pending,
                                          child: pending
                                              ? const SizedBox.square(
                                                  dimension: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : Switch(
                                                  value: spot.isActive,
                                                  onChanged: (value) => _runSpotMutation(
                                                    spot,
                                                    () =>
                                                        BackendRepository.setSpotActive(
                                                          spot.id,
                                                          value,
                                                        ),
                                                    value
                                                        ? MessageCode.isNowVisibleValue(
                                                            (spot.name)
                                                                .toString(),
                                                          )
                                                        : MessageCode.isNowHiddenValue(
                                                            (spot.name)
                                                                .toString(),
                                                          ),
                                                  ),
                                                  activeThumbColor:
                                                      AppColors.success,
                                                ),
                                        ),
                                        PopupMenuButton<String>(
                                          enabled: !pending,
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              context.push(
                                                '/admin/spots/form',
                                                extra: spot,
                                              );
                                            } else if (value == 'delete') {
                                              await _runSpotMutation(
                                                spot,
                                                () => AppSession.deleteSpot(
                                                  spot.id,
                                                ),
                                                MessageCode.deletedValue(
                                                  (spot.name).toString(),
                                                ),
                                              );
                                            } else if (value ==
                                                'availability') {
                                              await _changeAvailability(spot);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'availability',
                                              child: Text(
                                                context.message(
                                                  spot.isTemporarilyClosed
                                                      ? MessageCode
                                                            .reopenAttraction
                                                      : MessageCode
                                                            .closeTemporarily,
                                                ),
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text(context.l10n.edit),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text(
                                                context.l10n.delete,
                                                style: TextStyle(
                                                  color: AppColors.danger,
                                                ),
                                              ),
                                            ),
                                          ],
                                          icon: const Icon(
                                            Icons.more_vert,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
