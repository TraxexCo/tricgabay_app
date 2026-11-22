import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/motion/motion_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/list_skeleton.dart';
import '../../../core/services/realtime_refresh_policy.dart';
import '../../../models/tourist_spot_model.dart';
import '../../../core/session/app_session.dart';
import '../spot_filters.dart';

class TouristSearchScreen extends StatefulWidget {
  const TouristSearchScreen({super.key});

  @override
  State<TouristSearchScreen> createState() => _TouristSearchScreenState();
}

class _TouristSearchScreenState extends State<TouristSearchScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = MessageCode.all;
  List<TouristSpotModel> _results = AppSession.allSpots.value;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    AppSession.allSpots.addListener(_filter);
  }

  @override
  void dispose() {
    AppSession.allSpots.removeListener(_filter);
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter() => _applyFilter(_selectedCategory);

  void _applyFilter(String category) {
    _debounce?.cancel();
    final results = filterSpots(
      AppSession.allSpots.value,
      category,
      query: _searchCtrl.text,
    );
    setState(() {
      _selectedCategory = category;
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Row(
          children: [
            Expanded(
              child: AppTextField(
                label: context.l10n.search,
                controller: _searchCtrl,
                hint: context.l10n.searchSpots,
                onChanged: (_) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), _filter);
                },
                autofocus: true,
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                tooltip: context.l10n.clearSearch,
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () {
                  _searchCtrl.clear();
                  _filter();
                },
              ),
            IconButton(
              tooltip: context.l10n.mapView,
              onPressed: () => context.go('/tourist/home'),
              icon: const Icon(Icons.map_outlined, color: AppColors.primary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: availableSpotFilters(AppSession.allSpots.value).length,
              itemBuilder: (context, index) {
                final cat = availableSpotFilters(
                  AppSession.allSpots.value,
                )[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(context.message(cat)),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) _applyFilter(cat);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    labelStyle: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? ValueListenableBuilder(
                    valueListenable: AppSession.loadingSections,
                    builder: (context, sections, _) =>
                        sections.contains(RemoteSection.spots)
                        ? const ListSkeleton()
                        : EmptyStateWidget(
                            icon: Icons.search_off,
                            title: context.l10n.noSpotsFound,
                            subtitle: context
                                .l10n
                                .tryAdjustingYourFiltersOrSearchTerm,
                          ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 118),
                    itemCount: _results.length,
                    itemBuilder: (context, index) => FadeSlideIn.staggered(
                      index: index,
                      child: Builder(
                        builder: (context) {
                          final spot = _results[index];
                          return AppCard(
                            onTap: () =>
                                context.push('/tourist/spot/${spot.id}'),
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.zero,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(16),
                                  ),
                                  child: SafeAppImage(
                                    path: spot.imageUrls.isNotEmpty
                                        ? spot.imageUrls.first
                                        : '',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.message(spot.name),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          context.message(
                                            spot.category == SpotCategory.other
                                                ? MessageCode.resortCaf
                                                : spot.categoryLabel,
                                          ),
                                          style: GoogleFonts.poppins(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                context.l10n.kmAwayValueLabel(
                                                  context.message(
                                                    (spot.distanceFromTown)
                                                        .toString(),
                                                  ),
                                                ),
                                                style: GoogleFonts.poppins(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
