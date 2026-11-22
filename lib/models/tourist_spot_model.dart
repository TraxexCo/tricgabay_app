import '../core/constants/app_brand.dart';
import 'package:tricgabay_app/core/l10n/message_codes.g.dart';

enum SpotCategory { heritage, nature, church, park, market, other }

class TouristSpotModel {
  final String id;
  final String name;
  final String description;
  final String history;
  final double latitude;
  final double longitude;
  final SpotCategory category;
  final List<String> imageUrls;
  final String openingHours;
  final String entranceFee;
  final List<String> tips;
  final double distanceFromTown;
  final bool isActive;
  final String availabilityStatus;
  final DateTime? closedUntil;
  final String? closureReason;

  const TouristSpotModel({
    required this.id,
    required this.name,
    required this.description,
    required this.history,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.imageUrls,
    required this.openingHours,
    required this.entranceFee,
    required this.tips,
    this.distanceFromTown = 0.0,
    this.isActive = true,
    this.availabilityStatus = 'open',
    this.closedUntil,
    this.closureReason,
  });

  bool get isTemporarilyClosed =>
      availabilityStatus == 'temporarily_closed' &&
      (closedUntil == null || closedUntil!.isAfter(DateTime.now()));

  factory TouristSpotModel.fromMap(Map<String, dynamic> map, String id) {
    return TouristSpotModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      history: map['history'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      category: SpotCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => SpotCategory.other,
      ),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      openingHours: map['openingHours'] ?? '',
      entranceFee: map['entranceFee'] ?? MessageCode.checkLocally,
      tips: List<String>.from(map['tips'] ?? []),
      distanceFromTown: (map['distanceFromTown'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? true,
      availabilityStatus: map['availabilityStatus'] ?? 'open',
      closedUntil: map['closedUntil'] == null
          ? null
          : DateTime.parse(map['closedUntil']),
      closureReason: map['closureReason'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'history': history,
    'latitude': latitude,
    'longitude': longitude,
    'category': category.name,
    'imageUrls': imageUrls,
    'openingHours': openingHours,
    'entranceFee': entranceFee,
    'tips': tips,
    'distanceFromTown': distanceFromTown,
    'isActive': isActive,
    'availabilityStatus': availabilityStatus,
    'closedUntil': closedUntil?.toIso8601String(),
    'closureReason': closureReason,
  };

  String get categoryLabel => switch (category) {
    SpotCategory.heritage => MessageCode.heritage,
    SpotCategory.nature => MessageCode.nature,
    SpotCategory.church => MessageCode.church,
    SpotCategory.park => MessageCode.park,
    SpotCategory.market => MessageCode.market,
    SpotCategory.other => MessageCode.other,
  };

  static List<TouristSpotModel> get catalog => [
    TouristSpotModel(
      id: 'bustos-heritage-park',
      name: 'Bustos Heritage Park',
      description:
          'A central heritage stop in Bustos and the starting point shared by all three ${AppBrand.name} tour packages.',
      history:
          'This public park highlights local identity and serves as a convenient orientation point for a tour of Bustos.',
      latitude: 14.9532835,
      longitude: 120.9186307,
      category: SpotCategory.heritage,
      imageUrls: ['assets/images/bustos_heritage_park.jpg'],
      openingHours: 'Open daily',
      entranceFee: 'Free',
      tips: [
        'A good first stop for the tour',
        'Bring water and sun protection',
      ],
      distanceFromTown: 0.2,
    ),
    TouristSpotModel(
      id: 'sta-cruz-chapel',
      name: 'Sta. Cruz Chapel',
      description:
          'A neighborhood chapel in Talampas, also mapped as Holy Cross Chapel, and included in the TRIC LAKBAY route.',
      history:
          'A local faith stop included in the supplied ${AppBrand.name} tour package.',
      latitude: 14.9344482,
      longitude: 120.9070123,
      category: SpotCategory.church,
      imageUrls: ['assets/images/san_isidro_labrador_parish.jpg'],
      openingHours: MessageCode.checkLocally,
      entranceFee: 'Free',
      tips: ['Dress respectfully', 'Keep voices low during services'],
      distanceFromTown: 2.4,
    ),
    TouristSpotModel(
      id: 'sta-monica-chapel',
      name: 'Sta. Monica Chapel',
      description:
          'A chapel in Bonga Mayor that appears in every supplied tour package.',
      history:
          'A recurring faith stop on the official ${AppBrand.name} package routes.',
      latitude: 14.9578495,
      longitude: 120.9437551,
      category: SpotCategory.church,
      imageUrls: ['assets/images/sto_nino_tugyaw_festival.jpg'],
      openingHours: MessageCode.checkLocally,
      entranceFee: 'Free',
      tips: ['Dress respectfully', 'Confirm service times before visiting'],
      distanceFromTown: 2.8,
    ),
    TouristSpotModel(
      id: 'sto-nino-church',
      name: 'Sto. Nino Church',
      description:
          'The Sto. Nino Parish Church in Poblacion, a landmark stop on TRIC LAKBAY and TRIC TUKLAS.',
      history:
          'The parish church is one of the best-known religious landmarks in central Bustos.',
      latitude: 14.9550547,
      longitude: 120.9096725,
      category: SpotCategory.church,
      imageUrls: ['assets/images/sto_nino_tugyaw_festival.jpg'],
      openingHours: 'Check parish schedule',
      entranceFee: 'Free',
      tips: ['Dress modestly', 'Avoid disrupting Mass or private prayer'],
      distanceFromTown: 1.0,
    ),
    TouristSpotModel(
      id: 'zenys-minasa',
      name: "Zenny's Minasa Pasalubong",
      description:
          'A local pasalubong stop for Bustos minasa and the final stop in all three supplied packages.',
      history:
          'Minasa is a signature local delicacy and a popular take-home treat from Bustos.',
      latitude: 14.9530664,
      longitude: 120.9192362,
      category: SpotCategory.market,
      imageUrls: ['assets/images/minasa_festival.jpg'],
      openingHours: 'Check store hours',
      entranceFee: 'No entrance fee',
      tips: ['Ask about available box sizes', 'Buy near the end of the tour'],
      distanceFromTown: 0.3,
    ),
    TouristSpotModel(
      id: 'st-peter-chapel',
      name: 'St. Peter Chapel',
      description:
          'The Chapel of Saint Peter under Sto. Nino Parish, included in the TRIC SAYA route.',
      history:
          'A local Catholic chapel serving the surrounding Bustos community.',
      latitude: 14.9432705,
      longitude: 120.9069568,
      category: SpotCategory.church,
      imageUrls: ['assets/images/san_isidro_labrador_parish.jpg'],
      openingHours: MessageCode.checkLocally,
      entranceFee: 'Free',
      tips: ['Dress respectfully', 'Confirm chapel access before visiting'],
      distanceFromTown: 1.8,
    ),
    TouristSpotModel(
      id: 'sto-nino-chapel',
      name: 'Sto. Nino Chapel',
      description:
          'A local Sto. Nino faith stop included in the TRIC SAYA package.',
      history:
          'This stop follows the name and route supplied in the tour package document.',
      latitude: 14.9490860,
      longitude: 120.9115939,
      category: SpotCategory.church,
      imageUrls: ['assets/images/sto_nino_tugyaw_festival.jpg'],
      openingHours: MessageCode.checkLocally,
      entranceFee: 'Free',
      tips: ['Dress respectfully', 'Confirm chapel access before visiting'],
      distanceFromTown: 0.9,
    ),
    TouristSpotModel(
      id: 'perpetual-help-chapel',
      name: 'Nuestra Senora Del Perpetuo',
      description:
          'Our Lady of Perpetual Help Chapel at Sitio Pitong Gatang, included in TRIC TUKLAS.',
      history: 'A community chapel under Sto. Nino Parish in Bustos.',
      latitude: 14.9553980,
      longitude: 120.9177589,
      category: SpotCategory.church,
      imageUrls: ['assets/images/san_isidro_labrador_parish.jpg'],
      openingHours: MessageCode.checkLocally,
      entranceFee: 'Free',
      tips: ['Dress respectfully', 'Keep voices low during services'],
      distanceFromTown: 0.2,
    ),
    TouristSpotModel(
      id: 'sto-rosario-chapel',
      name: 'Sto. Rosario Chapel',
      description:
          'A chapel in Bonga Menor and a faith stop on the TRIC TUKLAS route.',
      history: 'A local Catholic chapel serving the Bonga Menor community.',
      latitude: 14.9504841,
      longitude: 120.9327939,
      category: SpotCategory.church,
      imageUrls: ['assets/images/sto_nino_tugyaw_festival.jpg'],
      openingHours: MessageCode.checkLocally,
      entranceFee: 'Free',
      tips: ['Dress respectfully', 'Confirm chapel access before visiting'],
      distanceFromTown: 1.6,
    ),
    TouristSpotModel(
      id: 'immaculate-conception-chapel',
      name: 'Our Lady of Immaculate',
      description:
          'Our Lady of the Immaculate Conception Chapel in Malamig, included in TRIC TUKLAS.',
      history: 'A local Catholic chapel serving the Malamig community.',
      latitude: 14.9365935,
      longitude: 120.9277048,
      category: SpotCategory.church,
      imageUrls: ['assets/images/san_isidro_labrador_parish.jpg'],
      openingHours: MessageCode.checkLocally,
      entranceFee: 'Free',
      tips: ['Dress respectfully', 'Keep voices low during services'],
      distanceFromTown: 2.2,
    ),
    TouristSpotModel(
      id: 'galilee-wailing-wall',
      name: 'Galilee Wailing Wall',
      description:
          'A themed landmark in Bustos and one of the distinctive stops on the TRIC TUKLAS route.',
      history:
          'This attraction is included by name in the supplied tour package document.',
      latitude: 14.9442340,
      longitude: 120.9082740,
      category: SpotCategory.other,
      imageUrls: ['assets/images/galilee_wonderland_resort.jpg'],
      openingHours: MessageCode.checkLocally,
      entranceFee: MessageCode.checkLocally,
      tips: ['Confirm access before visiting', 'Allow time for photos'],
      distanceFromTown: 1.6,
    ),
  ];
}

class TourPackageModel {
  final String id;
  final String name;
  final String description;
  final String duration;
  final List<String> spotIds;
  final String imageUrl;
  final List<String> highlights;

  const TourPackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.spotIds,
    required this.imageUrl,
    required this.highlights,
  });

  factory TourPackageModel.fromPublishedRow(Map<String, dynamic> row) {
    final id = row['id'] as String;
    final artwork = catalog.where((package) => package.id == id).firstOrNull;
    final stops =
        List<Map<String, dynamic>>.from(row['tour_package_stops'] as List)
          ..sort(
            (a, b) =>
                (a['stop_order'] as int).compareTo(b['stop_order'] as int),
          );
    return TourPackageModel(
      id: id,
      name: row['name'] as String,
      description: row['description'] as String,
      duration: '',
      spotIds: stops
          .map((stop) => stop['spot_id'] as String)
          .toList(growable: false),
      imageUrl: artwork?.imageUrl ?? '',
      highlights: const [],
    );
  }

  static List<TourPackageModel> get catalog => const [
    TourPackageModel(
      id: 'tric-lakbay',
      name: 'TRIC LAKBAY',
      description:
          'A five-stop Bustos route combining the heritage park, community chapels, the parish church, and a minasa pasalubong stop.',
      duration: 'Flexible schedule',
      spotIds: [
        'bustos-heritage-park',
        'sta-cruz-chapel',
        'sta-monica-chapel',
        'sto-nino-church',
        'zenys-minasa',
      ],
      imageUrl: 'assets/images/bustos_heritage_park.jpg',
      highlights: [
        'Fixed five-stop itinerary',
        'Heritage and faith landmarks',
        'Minasa pasalubong stop',
      ],
    ),
    TourPackageModel(
      id: 'tric-saya',
      name: 'TRIC SAYA',
      description:
          'A five-stop chapel trail that begins at Bustos Heritage Park and ends with local minasa pasalubong.',
      duration: 'Flexible schedule',
      spotIds: [
        'bustos-heritage-park',
        'sta-monica-chapel',
        'st-peter-chapel',
        'sto-nino-chapel',
        'zenys-minasa',
      ],
      imageUrl: 'assets/images/sto_nino_tugyaw_festival.jpg',
      highlights: [
        'Fixed five-stop itinerary',
        'Three community chapels',
        'Minasa pasalubong stop',
      ],
    ),
    TourPackageModel(
      id: 'tric-tuklas',
      name: 'TRIC TUKLAS',
      description:
          'The most complete package, with eight ordered stops covering Bustos heritage, chapels, the parish church, Galilee Wailing Wall, and minasa pasalubong.',
      duration: 'Full day suggested',
      spotIds: [
        'bustos-heritage-park',
        'perpetual-help-chapel',
        'sta-monica-chapel',
        'sto-rosario-chapel',
        'immaculate-conception-chapel',
        'sto-nino-church',
        'galilee-wailing-wall',
        'zenys-minasa',
      ],
      imageUrl: 'assets/images/san_isidro_labrador_parish.jpg',
      highlights: [
        'Fixed eight-stop itinerary',
        'Heritage and chapel trail',
        'Galilee Wailing Wall',
        'Minasa pasalubong stop',
      ],
    ),
  ];
}
