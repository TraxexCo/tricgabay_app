import 'place_photos.dart';
import 'package:tricgabay_app/core/l10n/message_codes.g.dart';

enum SpotCategory { heritage, nature, church, park, market, other }

class TouristSpotModel {
  final String id;
  final String name;
  final String description;
  final String history;
  final String address;
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
    this.address = '',
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
      address: map['address'] ?? '',
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
    'address': address,
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
      name: "Bustos Heritage Park",
      description:
          "The town's heritage park inside the Municipal Hall compound, where every Tric-Gabay tour begins. It holds the Bulacan Military Area (BMA) monument plaza, the municipal library and museum, and the Arts, Culture and Tourism Center that runs the tours.",
      history:
          "Bustos began as a barrio of Baliuag. In 1862 a boat carrying parents, children and godparents to a baptism in Baliuag overturned on the Angat River, and the grief that followed led the people to ask for their own town and parish. Bustos separated from Baliuag on 29 April 1867, was returned to it during the American period, and became a municipality again on 1 January 1916; its first municipal hall opened in 1917 with Leon Prado as mayor.\n\nThe park also remembers the town's role in World War II. The Bulacan Military Area, formed on 3 July 1942, made Bustos the headquarters of the province's guerrillas under Bustos-born Capt. (later General) Alejo Santos. A historical marker for Santos was unveiled here in 2022, and the BMA grounds host the Minasa Festival every January.",
      address: "Municipal Compound, Brgy. Poblacion, Bustos, Bulacan",
      latitude: 14.9532835,
      longitude: 120.9186307,
      category: SpotCategory.heritage,
      imageUrls: PlacePhotos.pathsFor('bustos-heritage-park', [
        'assets/images/bustos_heritage_park.jpg',
      ]),
      openingHours: "Mon–Fri 8:00 AM–5:00 PM",
      entranceFee: "Free",
      tips: [
        "The park grounds are open every day; the museum and tourism center follow office hours",
        "Ask the tourism staff about the BMA monument and the Bustos centennial exhibit",
        "Bring water and sun protection for the outdoor plaza",
      ],
      distanceFromTown: 0.2,
    ),
    TouristSpotModel(
      id: 'sta-cruz-chapel',
      name: "Sta. Cruz Chapel",
      description:
          "The Chapel of the Holy Cross (Bisita ng Sta. Cruz) of Barangay Talampas, a community chapel of Sto. Niño Parish and a stop on the TRIC LAKBAY route.",
      history:
          "Talampas is one of the old barrios that once lay across the Angat River from Baliuag. Before Bustos had its own parish, families from Talampas, Tanawan and Bonga had to cross the river to reach the church in Baliuag, and it was on one of these crossings in 1862 that a boat carrying children to their baptism capsized. That tragedy led to the founding of the Sto. Niño Parish in 1867.\n\nToday Talampas keeps its own chapel under the parish, dedicated to the Holy Cross. It is run by the barangay's parish pastoral council, which gathers the community for Masses, novenas and the yearly fiesta in honor of the Cross.",
      address: "Purok 3, Brgy. Talampas, Bustos, Bulacan",
      latitude: 14.9344482,
      longitude: 120.9070123,
      category: SpotCategory.church,
      imageUrls: PlacePhotos.pathsFor('sta-cruz-chapel', [
        'assets/images/san_isidro_labrador_parish.jpg',
      ]),
      openingHours: "Mon–Fri 8:00 AM–5:00 PM",
      entranceFee: "Free",
      tips: [
        "Visits are arranged by the Bustos Tourism Office during tour hours",
        "Dress modestly and keep voices low if a service is going on",
        "Sunday and fiesta Mass times are announced by Sto. Niño Parish",
      ],
      distanceFromTown: 2.4,
    ),
    TouristSpotModel(
      id: 'sta-monica-chapel',
      name: "Sta. Monica Chapel",
      description:
          "The Chapel of St. Monica (Bisita ni Sta. Monica) of Barangay Bonga Mayor, beside the highway near Tibagan, and the only chapel included in all three tour packages.",
      history:
          "Bonga Mayor was one of the two Bonga barrios joined to the new town when Bustos separated from Baliuag in 1867. Its chapel is dedicated to St. Monica, the mother of St. Augustine. The choice reflects the Augustinian roots of the local Church: the Augustinians founded the Sto. Niño Parish of Bustos, and St. Monica and St. Augustine are carved on the main doors of the parish church.\n\nThe chapel serves the families of Bonga Mayor and the neighboring part of Tibagan under the Sto. Niño Parish, which holds Masses here and leads the community's devotions and fiesta.",
      address: "Gen. Alejo G. Santos Hwy, Brgy. Bonga Mayor, Bustos, Bulacan",
      latitude: 14.9578495,
      longitude: 120.9437551,
      category: SpotCategory.church,
      imageUrls: PlacePhotos.pathsFor('sta-monica-chapel', [
        'assets/images/sto_nino_tugyaw_festival.jpg',
      ]),
      openingHours: "Mon–Fri 8:00 AM–5:00 PM",
      entranceFee: "Free",
      tips: [
        "Weekend evening services are held on Saturdays and Sundays",
        "The chapel faces the busy highway, so stay on the shoulder when taking photos",
        "Dress modestly inside the chapel",
      ],
      distanceFromTown: 2.8,
    ),
    TouristSpotModel(
      id: 'sto-nino-church',
      name: "Sto. Niño Parish Church",
      description:
          "The parish church of the Sto. Niño de Bustos, the town's patron, in Poblacion. Founded in 1867, it was named a Jubilee Church of the Diocese of Malolos for the 500 years of Christianity in the Philippines.",
      history:
          "The parish exists because of a tragedy. In 1862 a boat carrying parents, children and godparents to a baptism in Baliuag overturned in the Angat River. The people asked for a parish of their own so no one would have to cross the river again, and chose the Holy Child (Sto. Niño) as patron in memory of the infants who drowned. The Augustinians established the parish in 1867, with Padre Gabriel Alvarez as its first parish priest.\n\nThe church has a facade crowned by Christ the Redeemer, with niches for the Sto. Niño, St. Augustine and the crucified Christ. Its wooden doors are carved with St. Monica and St. Augustine, and its ceiling paintings follow the Sistine Chapel. The parish celebrated its 150th anniversary in 2017 together with the town's centennial, and honors the Sto. Niño every third Sunday of January with the Tugyaw (tugtog at sayaw) street dancing.",
      address:
          "Beltran St. cor. C.L. Hilario Hwy, Brgy. Poblacion, Bustos, Bulacan",
      latitude: 14.9550547,
      longitude: 120.9096725,
      category: SpotCategory.church,
      imageUrls: PlacePhotos.pathsFor('sto-nino-church', [
        'assets/images/sto_nino_tugyaw_festival.jpg',
      ]),
      openingHours:
          "Tue–Sat 8:00 AM–12:00 PM · Tue–Sat 2:00 PM–5:00 PM · Sun 9:30 AM–12:00 PM",
      entranceFee: "Free",
      tips: [
        "Mass: Sundays 6:30 AM, 8:00 AM and 5:00 PM; Monday to Saturday 6:30 AM",
        "The parish office is closed on Mondays; call (044) 796 2194",
        "Do not walk around during Mass or private prayer",
      ],
      distanceFromTown: 1.0,
    ),
    TouristSpotModel(
      id: 'zenys-minasa',
      name: "Zeny's Minasa",
      description:
          "A family-run pasalubong store near the Municipal Hall, known for Bustos minasa and other Bulacan delicacies. It is the last stop of all three tour packages.",
      history:
          "Minasa are crisp cassava cookies made from cassava flour, egg yolk, yeast, butter and coconut milk. The name comes from the kneading (masa) of the dough. In Spanish times they were baked for well-off Bulakeño families, and local lore links them to the egg yolks left over when egg whites were used in building stone houses. Bustos holds the Minasa Festival every January, and the town's motto is \"Minasa ng kaunlaran!\"\n\nZeny's bakes its minasa in small batches. Maria Elena de Lara learned the recipe from her grandmother, who learned it from the family before her. Besides minasa, the store sells lengua de gato, barquillos and other native treats that visitors and balikbayans bring home.",
      address: "7 Tanawan, Bustos, Bulacan (near the Municipal Hall)",
      latitude: 14.9530664,
      longitude: 120.9192362,
      category: SpotCategory.market,
      imageUrls: PlacePhotos.pathsFor('zenys-minasa', [
        'assets/images/minasa_festival.jpg',
      ]),
      openingHours: "Mon–Fri 7:00 AM–6:00 PM · Sat, Sun 7:00 AM–5:00 PM",
      entranceFee: "No entrance fee",
      tips: [
        "Minasa is fragile; ask for a sturdy box if you are travelling far",
        "Buy at the end of the tour so the cookies stay crisp",
        "Contact: (044) 617 0227",
      ],
      distanceFromTown: 0.3,
    ),
    TouristSpotModel(
      id: 'st-peter-chapel',
      name: "St. Peter Chapel",
      description:
          "The Chapel of St. Peter (Bisita ni San Pedro), the community chapel of Barangay San Pedro under Sto. Niño Parish, on the TRIC SAYA route.",
      history:
          "San Pedro takes its name from its patron, St. Peter the Apostle, and its chapel stands at the heart of the barangay along Col. P. Garcia Street. It is one of the chapels of the Sto. Niño Parish, which has served the barrios of Bustos since 1867.\n\nThe chapel's San Pedro parish pastoral council organizes Masses, novenas and the yearly fiesta. The chapel keeps images of St. Peter and other saints that are brought out for the barangay's processions. It is a short ride from the Galilee Wonderland complex on the highway.",
      address: "Col. P. Garcia St., Brgy. San Pedro, Bustos, Bulacan",
      latitude: 14.9432705,
      longitude: 120.9069568,
      category: SpotCategory.church,
      imageUrls: PlacePhotos.pathsFor('st-peter-chapel', [
        'assets/images/san_isidro_labrador_parish.jpg',
      ]),
      openingHours: "Mon–Fri 8:00 AM–5:00 PM",
      entranceFee: "Free",
      tips: [
        "Visits are arranged by the Bustos Tourism Office during tour hours",
        "Dress modestly and keep voices low",
        "The images of the saints are devotional objects, so please do not touch them",
      ],
      distanceFromTown: 1.8,
    ),
    TouristSpotModel(
      id: 'sto-nino-chapel',
      name: "Sto. Niño Chapel",
      description:
          "A small community chapel dedicated to the Sto. Niño, the patron of Bustos, and a stop on the TRIC SAYA route.",
      history:
          "Devotion to the Sto. Niño is at the center of Bustos life. The town chose the Holy Child as its patron in memory of the infants who drowned in the Angat River in 1862, the tragedy that led to the founding of the parish and the town in 1867.\n\nNeighborhood chapels like this one keep that devotion close to home. Families gather here to pray to the Holy Child, especially in January, when the whole town celebrates the Sto. Niño feast with processions and the Tugyaw street dancing.",
      address: "WWX6+MQX, Bustos, Bulacan",
      latitude: 14.949086,
      longitude: 120.9115939,
      category: SpotCategory.church,
      imageUrls: PlacePhotos.pathsFor('sto-nino-chapel', [
        'assets/images/sto_nino_tugyaw_festival.jpg',
      ]),
      openingHours: "Mon–Fri 8:00 AM–5:00 PM",
      entranceFee: "Free",
      tips: [
        "Visits are arranged by the Bustos Tourism Office during tour hours",
        "The busiest time is the Sto. Niño feast every third Sunday of January",
        "Dress modestly inside the chapel",
      ],
      distanceFromTown: 0.9,
    ),
    TouristSpotModel(
      id: 'perpetual-help-chapel',
      name: "Our Lady of Perpetual Help Chapel",
      description:
          "The Chapel of Our Lady of Perpetual Help (Bisita ng Ina ng Laging Saklolo) in Sitio Pitong Gatang, Poblacion, a short walk from the Heritage Park and a stop on TRIC TUKLAS.",
      history:
          "This is the Poblacion chapel of the Sto. Niño Parish. It is dedicated to Our Mother of Perpetual Help, the Marian devotion whose Wednesday novena is one of the most widely prayed in the Philippines. It serves the families of Sitio Pitong Gatang, a neighborhood of the town center.\n\nInside, a framed icon of the Virgin and Child is set on a carved wooden altar flanked by images of Mary. The Poblacion parish pastoral council keeps the chapel and leads its novenas and devotions.",
      address:
          "67 Domingo St., Sitio Pitong Gatang, Brgy. Poblacion, Bustos, Bulacan",
      latitude: 14.955398,
      longitude: 120.9177589,
      category: SpotCategory.church,
      imageUrls: PlacePhotos.pathsFor('perpetual-help-chapel', [
        'assets/images/san_isidro_labrador_parish.jpg',
      ]),
      openingHours: "Mon–Fri 8:00 AM–5:00 PM",
      entranceFee: "Free",
      tips: [
        "Visits are arranged by the Bustos Tourism Office during tour hours",
        "Wednesday is the traditional day of the Perpetual Help novena",
        "The chapel is on a narrow street; tricycles drop off at the corner",
      ],
      distanceFromTown: 0.2,
    ),
    TouristSpotModel(
      id: 'sto-rosario-chapel',
      name: "Sto. Rosario Chapel",
      description:
          "The Chapel of the Holy Rosary in Barangay Bonga Menor, a white chapel with a blue spire and a stop on the TRIC TUKLAS route.",
      history:
          "Bonga Menor is one of the two Bonga barrios that joined Bustos when it became its own town in 1867. It is the birthplace of Gen. Alejo Santos, who led the Bulacan guerrillas in World War II. It is also home to several of the town's ancestral houses.\n\nThe barangay's chapel is dedicated to Our Lady of the Holy Rosary. It is a rounded white building with a blue conical spire and a bell turret over its gate. It belongs to the Sto. Niño Parish, which celebrates Mass here, and the community gathers in it for the Rosary devotions of October.",
      address:
          "Ester Compound, C.L. Hilario St., Brgy. Bonga Menor, Bustos, Bulacan",
      latitude: 14.9504841,
      longitude: 120.9327939,
      category: SpotCategory.church,
      imageUrls: PlacePhotos.pathsFor('sto-rosario-chapel', [
        'assets/images/sto_nino_tugyaw_festival.jpg',
      ]),
      openingHours: "Mon–Fri 8:00 AM–5:00 PM",
      entranceFee: "Free",
      tips: [
        "Visits are arranged by the Bustos Tourism Office during tour hours",
        "October, the month of the Rosary, is the chapel’s busiest season",
        "Combine with a look at the ancestral houses of Bonga Menor from the road",
      ],
      distanceFromTown: 1.6,
    ),
    TouristSpotModel(
      id: 'immaculate-conception-chapel',
      name: "Immaculate Conception Chapel",
      description:
          "The Chapel of the Immaculate Conception (Bisita ng Inmaculada Concepcion) of Barangay Malamig, a community chapel of Sto. Niño Parish on the TRIC TUKLAS route.",
      history:
          "Malamig is a farming barangay south of the town center, on the road toward Liciada and Pandi. Its chapel is dedicated to the Immaculate Conception, a devotion close to Bulacan, whose cathedral in Malolos shares the same title.\n\nThe chapel belongs to the Sto. Niño Parish and is cared for by the Malamig parish pastoral council. It is a two-storey cream building with a tall arched entrance, and its blue-and-white interior centers on the crucifix and an image of the Immaculate Conception. The community's biggest celebration is the feast of the Immaculate Conception on 8 December.",
      address: "Brgy. Malamig, Bustos, Bulacan",
      latitude: 14.9365935,
      longitude: 120.9277048,
      category: SpotCategory.church,
      imageUrls: PlacePhotos.pathsFor('immaculate-conception-chapel', [
        'assets/images/san_isidro_labrador_parish.jpg',
      ]),
      openingHours: "Mon–Fri 8:00 AM–5:00 PM",
      entranceFee: "Free",
      tips: [
        "Visits are arranged by the Bustos Tourism Office during tour hours",
        "The feast on 8 December draws the most people",
        "Dress modestly inside the chapel",
      ],
      distanceFromTown: 2.2,
    ),
    TouristSpotModel(
      id: 'galilee-wailing-wall',
      name: "Galilee Wailing Wall",
      description:
          "A prayer wall inside Galilee Wonderland Waterpark and Hotel, modelled on Jerusalem's Western Wall, where visitors write prayers on paper and tuck them between the stones.",
      history:
          "Galilee opened on 5 March 2004 in San Pedro, Bustos, as Galilee Mansion and Garden Resort, and has since grown into Galilee Wonderland Waterpark and Hotel. The whole complex is built around biblical themes. Its pools and halls carry names such as Noah's Ark, the Jordan River, Mt. Sinai and the Garden of Eden.\n\nThe Wailing Wall follows the Western Wall in Jerusalem, the last remaining wall of the Temple Mount, where pilgrims have long placed written prayers in the cracks. Here visitors can do the same in a quiet corner of the resort, near its church.",
      address:
          "Galilee Wonderland Resort, Gen. Alejo G. Santos Hwy, Brgy. San Pedro, Bustos, Bulacan",
      latitude: 14.944234,
      longitude: 120.908274,
      category: SpotCategory.other,
      imageUrls: PlacePhotos.pathsFor('galilee-wailing-wall', [
        'assets/images/galilee_wonderland_resort.jpg',
      ]),
      openingHours: "Mon–Sun 7:00 AM–3:00 PM · Mon–Sun 4:00 PM–11:00 PM",
      entranceFee:
          "Resort entrance: ₱200 adults, ₱180 kids, ₱160 seniors and PWD",
      tips: [
        "The wall is inside the resort, so the resort entrance fee may apply; confirm at the gate",
        "Bring a pen and a small piece of paper for your prayer",
        "Respect people who are praying at the wall",
      ],
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
      imageUrl: 'assets/optimized_images/places/bustos-heritage-park_1.webp',
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
      imageUrl: 'assets/optimized_images/places/sta-monica-chapel_1.webp',
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
      imageUrl: 'assets/optimized_images/places/sto-nino-church_1.webp',
      highlights: [
        'Fixed eight-stop itinerary',
        'Heritage and chapel trail',
        'Galilee Wailing Wall',
        'Minasa pasalubong stop',
      ],
    ),
  ];
}
