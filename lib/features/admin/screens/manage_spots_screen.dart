import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/services/backend_repository.dart';
import '../../../models/tourist_spot_model.dart';

class ManageSpotsScreen extends ConsumerStatefulWidget {
  const ManageSpotsScreen({super.key});

  @override
  ConsumerState<ManageSpotsScreen> createState() => _ManageSpotsScreenState();
}

class _ManageSpotsScreenState extends ConsumerState<ManageSpotsScreen> {
  String _selectedCategory = 'All';

  Future<void> _setAvailability(TouristSpotModel spot) async {
    if (spot.isTemporarilyClosed) {
      await BackendRepository.setSpotAvailability(
        spotId: spot.id,
        closed: false,
      );
      await PrototypeSession.syncRemoteState();
      return;
    }
    final reason = TextEditingController();
    DateTime? until;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Temporarily close attraction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Affected tourists and assigned drivers will be notified. Existing bookings keep an audit record.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reason,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Closure reason',
                    border: OutlineInputBorder(),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expected reopening'),
                  subtitle: Text(
                    until == null
                        ? 'Unknown / until manually reopened'
                        : until!.toLocal().toString().split('.').first,
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
              child: const Text('Keep open'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Close and notify'),
            ),
          ],
        ),
      ),
    );
    final explanation = reason.text.trim();
    reason.dispose();
    if (approved != true || explanation.length < 5 || !mounted) return;
    await BackendRepository.setSpotAvailability(
      spotId: spot.id,
      closed: true,
      reason: explanation,
      closedUntil: until,
    );
    await PrototypeSession.syncRemoteState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      appBar: AppBar(title: const Text('Tourist Spots')),
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
                        'All',
                        'Heritage',
                        'Nature',
                        'Church',
                        'Park',
                        'Market',
                        'Other',
                      ]
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              c,
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
              valueListenable: PrototypeSession.allSpots,
              builder: (context, spots, _) {
                final filteredSpots = _selectedCategory == 'All'
                    ? spots
                    : spots
                          .where(
                            (s) =>
                                s.categoryLabel.toLowerCase() ==
                                _selectedCategory.toLowerCase(),
                          )
                          .toList();

                if (filteredSpots.isEmpty) {
                  return const Center(child: Text('No tourist spots found.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 104),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredSpots.length,
                  itemBuilder: (context, index) {
                    final spot = filteredSpots[index];
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
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'HIDDEN',
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
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'TEMPORARILY CLOSED',
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
                                  spot.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  spot.categoryLabel,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.secondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Switch(
                                      value: spot.isActive,
                                      onChanged: (val) {
                                        final updatedSpot = TouristSpotModel(
                                          id: spot.id,
                                          name: spot.name,
                                          description: spot.description,
                                          history: spot.history,
                                          latitude: spot.latitude,
                                          longitude: spot.longitude,
                                          category: spot.category,
                                          imageUrls: spot.imageUrls,
                                          openingHours: spot.openingHours,
                                          entranceFee: spot.entranceFee,
                                          tips: spot.tips,
                                          distanceFromTown:
                                              spot.distanceFromTown,
                                          isActive: val,
                                          availabilityStatus:
                                              spot.availabilityStatus,
                                          closedUntil: spot.closedUntil,
                                          closureReason: spot.closureReason,
                                        );
                                        PrototypeSession.addOrUpdateSpot(
                                          updatedSpot,
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              val
                                                  ? '${spot.name} is now visible'
                                                  : '${spot.name} is now hidden',
                                            ),
                                          ),
                                        );
                                      },
                                      activeThumbColor: AppColors.success,
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          context.push(
                                            '/admin/spots/form',
                                            extra: spot,
                                          );
                                        } else if (value == 'delete') {
                                          try {
                                            PrototypeSession.deleteSpot(
                                              spot.id,
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(content: Text('$e')),
                                            );
                                            return;
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${spot.name} deleted',
                                              ),
                                            ),
                                          );
                                        } else if (value == 'availability') {
                                          try {
                                            await _setAvailability(spot);
                                          } catch (error) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('$error'),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'availability',
                                          child: Text(
                                            spot.isTemporarilyClosed
                                                ? 'Reopen attraction'
                                                : 'Close temporarily',
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            'Delete',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
