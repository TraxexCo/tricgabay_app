import '../../core/l10n/message_codes.g.dart';
import '../../models/tourist_spot_model.dart';

const spotFilters = [
  MessageCode.all,
  MessageCode.church,
  MessageCode.heritage,
  MessageCode.farmsNature,
  MessageCode.market,
  MessageCode.resorts,
  MessageCode.foodCafes,
  MessageCode.events,
];

List<TouristSpotModel> filterSpots(
  List<TouristSpotModel> spots,
  String filter, {
  String query = '',
}) {
  if (filter == MessageCode.all && query.isEmpty) return spots;

  final normalizedQuery = query.toLowerCase();
  return spots
      .where((spot) {
        late final name = spot.name.toLowerCase();
        final matchesFilter = switch (filter) {
          MessageCode.all => true,
          MessageCode.church => spot.category == SpotCategory.church,
          MessageCode.heritage => spot.category == SpotCategory.heritage,
          MessageCode.farmsNature =>
            spot.category == SpotCategory.nature || name.contains('farm'),
          MessageCode.market => spot.category == SpotCategory.market,
          MessageCode.resorts => name.contains('resort'),
          MessageCode.foodCafes => name.contains('cafe'),
          MessageCode.events =>
            name.contains('festival') || name.contains('event'),
          _ => false,
        };
        return matchesFilter &&
            (normalizedQuery.isEmpty || name.contains(normalizedQuery));
      })
      .toList(growable: false);
}

/// Only the filters that match at least one place, so a chip never leads to
/// an empty list. "All" is always first.
List<String> availableSpotFilters(List<TouristSpotModel> spots) => [
  for (final filter in spotFilters)
    if (filter == MessageCode.all || filterSpots(spots, filter).isNotEmpty)
      filter,
];
