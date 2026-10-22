// ignore_for_file: avoid_print, avoid_relative_lib_imports

import 'dart:convert';

import '../lib/models/tourist_spot_model.dart';

void main() {
  print(
    jsonEncode({
      'spots': TouristSpotModel.catalog
          .map(
            (spot) => {
              'id': spot.id,
              'name': spot.name,
              'description': spot.description,
              'history': spot.history,
              'latitude': spot.latitude,
              'longitude': spot.longitude,
              'category': spot.category.name,
              'imageUrls': spot.imageUrls,
              'openingHours': spot.openingHours,
              'entranceFee': spot.entranceFee,
              'tips': spot.tips,
              'distanceFromTown': spot.distanceFromTown,
              'isActive': spot.isActive,
            },
          )
          .toList(),
      'packages': TourPackageModel.catalog
          .map(
            (package) => {
              'id': package.id,
              'name': package.name,
              'description': package.description,
              'spotIds': package.spotIds,
            },
          )
          .toList(),
    }),
  );
}
