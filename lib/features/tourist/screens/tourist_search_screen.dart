import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/motion/motion_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/list_skeleton.dart';
import '../../../core/services/realtime_refresh_policy.dart';
import '../../../models/tourist_spot_model.dart';
import '../../../core/session/app_session.dart';
import '../spot_filters.dart';

/// Discover tab: the three tours up top, then every place on them, with a
/// search field the tourist taps when they want it (no keyboard on arrival).
class TouristSearchScreen extends StatefulWidget {
  const TouristSearchScreen({super.key});

  @override
  State<TouristSearchScreen> createState() => _TouristSearchScreenState();
}

class _TouristSearchScreenState extends State<TouristSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _selectedCategory = MessageCode.all;
  List<TouristSpotModel> _results = AppSession.allSpots.value;
  Timer? _debounce;

  bool get _searching => _searchCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    AppSession.allSpots.addListener(_filter);
    AppSession.favorites.addListener(_refresh);
  }

  @override
  void dispose() {
    AppSession.allSpots.removeListener(_filter);
    AppSession.favorites.removeListener(_refresh);
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _filter() => _applyFilter(_selectedCategory);

  void _applyFilter(String category) {
    _debounce?.cancel();
    final results = filterSpots(
      AppSession.allSpots.value,
      category,
      query: _searchCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _selectedCategory = category;
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = availableSpotFilters(AppSession.allSpots.value);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        // Tapping outside the field puts the keyboard away.
        onTap: () => _searchFocus.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            if (!_searching) ...[
              SliverToBoxAdapter(
                child: _sectionTitle(
                  context.l10n.tourPackages,
                  action: TextButton(
                    onPressed: () => context.push('/tourist/tour-packages'),
                    child: Text(context.l10n.seeAll),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _packageCarousel()),
            ],
            SliverToBoxAdapter(
              child: _sectionTitle(
                _searching
                    ? context.l10n.resultsCountValue(
                        AppFormatters.integer(_results.length),
                      )
                    : context.l10n.placesOnOurTours,
              ),
            ),
            if (filters.length > 1)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                    itemCount: filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = filters[index];
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(context.message(cat)),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) _applyFilter(cat);
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        labelStyle: GoogleFonts.poppins(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (_results.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ValueListenableBuilder(
                  valueListenable: AppSession.loadingSections,
                  builder: (context, sections, _) =>
                      sections.contains(RemoteSection.spots)
                      ? const ListSkeleton()
                      : EmptyStateWidget(
                          icon: Icons.search_off,
                          title: context.l10n.noSpotsFound,
                          subtitle:
                              context.l10n.tryAdjustingYourFiltersOrSearchTerm,
                        ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                sliver: SliverList.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) => FadeSlideIn.staggered(
                    index: index,
                    child: _placeCard(_results[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryDark, AppColors.primary],
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.discoverBustos,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.mapView,
                  onPressed: () => context.go('/tourist/home'),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .15),
                  ),
                  icon: const Icon(Icons.map_outlined, color: Colors.white),
                ),
              ],
            ),
            Text(
              context.l10n.discoverSubtitle(
                AppFormatters.integer(AppSession.allSpots.value.length),
                AppFormatters.integer(AppSession.tourPackages.value.length),
              ),
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: .85),
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              shadowColor: Colors.black26,
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                onChanged: (_) {
                  setState(() {});
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 250), _filter);
                },
                style: GoogleFonts.poppins(fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: context.l10n.searchSpots,
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.textHint,
                    fontSize: 14.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.l10n.clearSearch,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            _filter();
                          },
                        ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _sectionTitle(String title, {Widget? action}) => Padding(
    padding: EdgeInsets.fromLTRB(20, 22, action == null ? 20 : 8, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ?action,
      ],
    ),
  );

  Widget _packageCarousel() => ValueListenableBuilder<List<TourPackageModel>>(
    valueListenable: AppSession.tourPackages,
    builder: (context, packages, _) {
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
      return SizedBox(
        height: 210 * scale,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: packages.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (context, i) {
            final package = packages[i];
            return SizedBox(
              width: 264,
              child: Material(
                color: AppColors.darkBg,
                borderRadius: BorderRadius.circular(22),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () =>
                      context.push('/tourist/tour-packages/${package.id}'),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SafeAppImage(path: AppSession.packageImage(package)),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0xE6081A33)],
                            stops: [.3, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '₱${AppFormatters.integer(AppSession.packageFare(package))}',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.message(package.name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.stopsValue(
                                    package.spotIds.length.toString(),
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: .9),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );

  Widget _placeCard(TouristSpotModel spot) {
    final tours = AppSession.packagesWithSpot(spot.id).length;
    final favorite = AppSession.isFavorite(spot.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/tourist/spot/${spot.id}'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SafeAppImage(
                        path: spot.imageUrls.isNotEmpty
                            ? spot.imageUrls.first
                            : '',
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            context.message(spot.categoryLabel),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: IconButton(
                          tooltip: favorite
                              ? context.l10n.removeFromSaved
                              : context.l10n.savePlace,
                          onPressed: () => AppSession.toggleFavorite(spot.id),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: .94,
                            ),
                          ),
                          icon: Icon(
                            favorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: favorite
                                ? AppColors.danger
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.message(spot.name),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (spot.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.message(spot.description),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          _meta(
                            Icons.near_me_outlined,
                            context.l10n.kmAwayValueLabel(
                              spot.distanceFromTown.toString(),
                            ),
                          ),
                          if (tours > 0)
                            _meta(
                              Icons.confirmation_number_outlined,
                              context.l10n.inToursValue(tours),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.primary),
      const SizedBox(width: 4),
      Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );
}
