import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/tourist_spot_model.dart';
import '../../../core/prototype/prototype_session.dart';

class TouristSearchScreen extends StatefulWidget {
  const TouristSearchScreen({super.key});

  @override
  State<TouristSearchScreen> createState() => _TouristSearchScreenState();
}

class _TouristSearchScreenState extends State<TouristSearchScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  List<TouristSpotModel> _results = PrototypeSession.allSpots.value;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _results = PrototypeSession.allSpots.value.where((spot) {
        bool matchesCat = true;
        if (_selectedCategory == 'Church') {
          matchesCat = spot.category == SpotCategory.church;
        } else if (_selectedCategory == 'Heritage') {
          matchesCat = spot.category == SpotCategory.heritage;
        } else if (_selectedCategory == 'Farms/Nature') {
          matchesCat =
              spot.category == SpotCategory.nature ||
              spot.name.toLowerCase().contains('farm') ||
              spot.name.toLowerCase().contains('park');
        } else if (_selectedCategory == 'Market') {
          matchesCat = spot.category == SpotCategory.market;
        } else if (_selectedCategory == 'Resorts') {
          matchesCat = spot.name.toLowerCase().contains('resort');
        } else if (_selectedCategory == 'Food & Cafes') {
          matchesCat = spot.name.toLowerCase().contains('cafe');
        } else if (_selectedCategory == 'Events') {
          matchesCat =
              spot.name.toLowerCase().contains('festival') ||
              spot.name.toLowerCase().contains('event');
        } else if (_selectedCategory != 'All') {
          matchesCat = false;
        }

        final matchesQuery = spot.name.toLowerCase().contains(query);
        return matchesCat && matchesQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      'Church',
      'Heritage',
      'Farms/Nature',
      'Market',
      'Resorts',
      'Food & Cafes',
      'Events',
    ];

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
                label: 'Search',
                controller: _searchCtrl,
                hint: 'Search spots...',
                onChanged: (v) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    _filter();
                  });
                },
                autofocus: true,
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () {
                  _searchCtrl.clear();
                  _filter();
                },
              ),
            IconButton(
              tooltip: 'Map view',
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
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                      _filter();
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
                ? const EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'No spots found',
                    subtitle: 'Try adjusting your filters or search term.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 118),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final spot = _results[index];
                      return AppCard(
                        onTap: () => context.push('/tourist/spot/${spot.id}'),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      spot.name,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      spot.category == SpotCategory.other
                                          ? 'Resort & Café'
                                          : spot.categoryLabel,
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
                                        Text(
                                          '${spot.distanceFromTown} km away',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
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
        ],
      ),
    );
  }
}
