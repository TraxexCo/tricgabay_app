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
      entranceFee: map['entranceFee'] ?? 'Check locally',
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
    SpotCategory.heritage => 'Heritage',
    SpotCategory.nature => 'Nature',
    SpotCategory.church => 'Church',
    SpotCategory.park => 'Park',
    SpotCategory.market => 'Market',
    SpotCategory.other => 'Other',
  };

  static List<TouristSpotModel> get catalog => [
    TouristSpotModel(
      id: 'bustos-heritage-park',
      name: 'Bustos Heritage Park',
      description:
          'A central heritage stop in Bustos and the starting point shared by all three Tric-Gabay tour packages.',
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
          'A local faith stop included in the supplied Tric-Gabay tour package.',
      latitude: 14.9344482,
      longitude: 120.9070123,
      category: SpotCategory.church,
      imageUrls: ['assets/images/san_isidro_labrador_parish.jpg'],
      openingHours: 'Check locally',
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
          'A recurring faith stop on the official Tric-Gabay package routes.',
      latitude: 14.9578495,
      longitude: 120.9437551,
      category: SpotCategory.church,
      imageUrls: ['assets/images/sto_nino_tugyaw_festival.jpg'],
      openingHours: 'Check locally',
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
      openingHours: 'Check locally',
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
      openingHours: 'Check locally',
      entranceFee: 'Free',
      tips: ['Dress respectfully', 'Confirm chapel access before visiting'],
      distanceFromTown: 0.9,
    ),
    TouristSpotModel(
      id: 'perpetual-help-chapel',
      name: 'Nuestra Senora del Perpetuo',
      description:
          'Our Lady of Perpetual Help Chapel at Sitio Pitong Gatang, included in TRIC TUKLAS.',
      history: 'A community chapel under Sto. Nino Parish in Bustos.',
      latitude: 14.9553980,
      longitude: 120.9177589,
      category: SpotCategory.church,
      imageUrls: ['assets/images/san_isidro_labrador_parish.jpg'],
      openingHours: 'Check locally',
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
      openingHours: 'Check locally',
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
      openingHours: 'Check locally',
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
      openingHours: 'Check locally',
      entranceFee: 'Check locally',
      tips: ['Confirm access before visiting', 'Allow time for photos'],
      distanceFromTown: 1.6,
    ),
    const TouristSpotModel(
      id: 's1',
      name: 'Bustos Dam Eco Park',
      description:
          'A scenic eco-park located near one of the longest sector dams in the world. Ideal for picnics, photography, and relaxing by the riverbank.',
      history:
          'Constructed in 1926, the Bustos Dam was originally built to provide irrigation to local farmlands. It has since become a popular recreational spot.',
      latitude: 14.9546077,
      longitude: 120.9535507,
      category: SpotCategory.nature,
      imageUrls: ['assets/images/bustos_dam_eco_park.jpg'],
      openingHours: '6:00 AM – 5:00 PM',
      entranceFee: '₱50',
      tips: [
        'Best visited during sunrise or sunset',
        'Great for family picnics',
        'Always be careful near the water',
      ],
      distanceFromTown: 3.5,
    ),

    const TouristSpotModel(
      id: 's3',
      name: 'Bustos Public Market',
      description:
          'The bustling commercial hub of Bustos, where locals buy fresh produce, meats, and the town\'s famous local delicacies.',
      history:
          'A long-standing trading center that has fueled the local economy, connecting farmers, artisans, and consumers for decades.',
      latitude: 14.9514976,
      longitude: 120.9172582,
      category: SpotCategory.market,
      imageUrls: ['assets/images/bustos_public_market.jpg'],
      openingHours: '4:00 AM – 6:00 PM',
      entranceFee: 'Free',
      tips: [
        'Go early in the morning for the freshest produce',
        'Don\'t forget to buy Minasa cookies',
        'Haggling is part of the experience',
      ],
      distanceFromTown: 0.1,
    ),

    const TouristSpotModel(
      id: 's5',
      name: 'Mercado Ancestral House',
      description:
          'A well-preserved heritage stone house featuring intricate Baroque carvings and classic Filipino-Spanish architectural elements.',
      history:
          'Dating back to the mid-19th century, this house is a testament to the affluent lifestyle of the early principalia in Bustos.',
      latitude: 14.9506629,
      longitude: 120.9294725,
      category: SpotCategory.heritage,
      imageUrls: ['assets/images/mercado_ancestral_house.jpg'],
      openingHours:
          'Exterior viewing only from the public road. Do not enter the property. (Private Property)',
      entranceFee: 'Free (Roadside viewing)',
      tips: [
        'Best appreciated during daylight',
        'Respect the privacy of the current residents',
        'Located in the historic district of Bonga Menor',
      ],
      distanceFromTown: 1.5,
    ),

    const TouristSpotModel(
      id: 's6',
      name: 'La Florentina Resort',
      description:
          'A popular destination for locals and tourists, offering beautiful swimming pools and modern amenities in a nature-inspired setting.',
      history:
          'Developed to cater to the growing demand for leisure facilities in Bustos, it has become a staple venue for family gatherings and events.',
      latitude: 14.9473511,
      longitude: 120.9393883,
      category: SpotCategory.other,
      imageUrls: ['assets/images/la_florentina_resort.jpg'],
      openingHours: '8:00 AM – 5:00 PM (Day Swim)',
      entranceFee: '₱150 - ₱250',
      tips: [
        'Book in advance during summer months',
        'Ideal for family reunions and team building',
        'Cottages are available for rent',
      ],
      distanceFromTown: 2.2,
    ),

    const TouristSpotModel(
      id: 's7',
      name: 'Malamig Park Resort',
      description:
          'A family-friendly resort known for its wave pools and exciting water slides, providing a fun and refreshing getaway.',
      history:
          'One of the pioneering wave pool resorts in the area, offering affordable leisure and recreation for Bulakenyos over the years.',
      latitude: 14.9339711,
      longitude: 120.9273098,
      category: SpotCategory.other,
      imageUrls: ['assets/images/galilee_wonderland_resort.jpg'],
      openingHours: '8:00 AM – 5:00 PM',
      entranceFee: '₱200',
      tips: [
        'Arrive early to secure the best cottages',
        'Wave pool schedules are announced regularly',
        'Expect large crowds during the summer',
      ],
      distanceFromTown: 3.0,
    ),

    const TouristSpotModel(
      id: 's8',
      name: 'Galilee Wonderland Resort',
      description:
          'A uniquely themed resort with large pools and various biblical and whimsical statues, perfect for a fun day out.',
      history:
          'Formerly known as Galilee Mansion, it was rebranded and expanded to include more attractions, merging recreation with unique thematic elements.',
      latitude: 14.9426537,
      longitude: 120.9095893,
      category: SpotCategory.other,
      imageUrls: ['assets/images/galilee_wonderland_resort.jpg'],
      openingHours: '8:00 AM – 5:00 PM',
      entranceFee: '₱150',
      tips: [
        'Explore the different themed areas for great photos',
        'Kid-friendly with specialized kiddie pools',
        'Event spaces available for booking',
      ],
      distanceFromTown: 1.8,
    ),

    const TouristSpotModel(
      id: 's9',
      name: 'General Alejo Santos Bridge',
      description:
          'A vital bridge crossing the Angat River, providing a scenic view of the water and surrounding landscapes, especially at sunset.',
      history:
          'Named in honor of General Alejo Santos, a WWII hero and former Secretary of National Defense, this bridge is a key infrastructural link in Bulacan.',
      latitude: 14.9565923,
      longitude: 120.9073392,
      category: SpotCategory.heritage,
      imageUrls: ['assets/images/general_alejo_santos_bridge.jpg'],
      openingHours: 'Open 24 hours',
      entranceFee: 'Free',
      tips: [
        'Perfect spot for sunset photography',
        'Be mindful of traffic when walking',
        'Connects Bustos to Baliuag',
      ],
      distanceFromTown: 1.0,
    ),

    const TouristSpotModel(
      id: 's10',
      name: 'Bahay at Yaman ni San Martin de Porres Inc.',
      description:
          'A charitable institution and orphanage with stunning architecture inspired by the traditional stone houses of Batanes.',
      history:
          'Founded to provide shelter and education to children in need, it grew into a self-sustaining community with beautifully constructed facilities.',
      latitude: 14.9360174,
      longitude: 120.9426398,
      category: SpotCategory.heritage,
      imageUrls: ['assets/images/bahay_at_yaman_san_martin.jpg'],
      openingHours: 'By appointment only',
      entranceFee: 'Donation',
      tips: [
        'Contact management before visiting',
        'Donations are welcome and highly appreciated',
        'Respect the privacy of the children and staff',
      ],
      distanceFromTown: 2.5,
    ),

    const TouristSpotModel(
      id: 's11',
      name: 'Cafe Apolonio and Restaurant sa Bahay Na Bato',
      description:
          'A historic Bahay na Bato turned into a charming restaurant, offering a unique dining experience amidst antique furnishings and classic architecture.',
      history:
          'Originally an ancestral house built in the 1850s, it has been carefully preserved and repurposed to showcase the culinary and cultural heritage of Bustos.',
      latitude: 14.9504491,
      longitude: 120.9290193,
      category: SpotCategory.heritage,
      imageUrls: ['assets/images/cafe_apolonio_bahay_na_bato.jpg'],
      openingHours: 'Temporarily Closed',
      entranceFee: 'Free (Restaurant purchases)',
      tips: [
        'Check their social media for reopening updates',
        'A must-visit for heritage enthusiasts when open',
        'Located in the heritage zone of Bonga Menor',
      ],
      distanceFromTown: 1.4,
    ),

    const TouristSpotModel(
      id: 's12',
      name: 'Cunanan Ancestral House',
      description:
          'An impressive ancestral home that showcases the typical prosperous lifestyle of Filipino families during the late Spanish and early American periods.',
      history:
          'Part of the rich collection of old houses in Bonga Menor, it has withstood the test of time, reflecting the town\'s glorious past.',
      latitude: 14.9526049,
      longitude: 120.9372526,
      category: SpotCategory.heritage,
      imageUrls: ['assets/images/galilee_wonderland_resort.jpg'],
      openingHours:
          'Exterior viewing only from the public road. Do not enter the property. (Private Property)',
      entranceFee: 'Free (Roadside viewing)',
      tips: [
        'Best viewed as part of a heritage walking tour',
        'Observe the intricate details on the facade',
        'Please respect the property and do not trespass',
      ],
      distanceFromTown: 2.0,
    ),

    const TouristSpotModel(
      id: 's13',
      name: 'Lopez Ancestral House',
      description:
          'Another jewel in Bustos\' crown of ancestral houses, featuring classic wood and stone elements that characterize Philippine colonial architecture.',
      history:
          'Once the residence of a prominent local family, it serves as a silent witness to the historical events that shaped the municipality.',
      latitude: 14.9544661,
      longitude: 120.9200347,
      category: SpotCategory.heritage,
      imageUrls: ['assets/images/galilee_wonderland_resort.jpg'],
      openingHours:
          'Exterior viewing only from the public road. Do not enter the property. (Private Property)',
      entranceFee: 'Free (Roadside viewing)',
      tips: [
        'Located near the town center',
        'Great addition to a cultural photography tour',
        'Appreciate the classic capiz shell windows',
      ],
      distanceFromTown: 0.3,
    ),

    const TouristSpotModel(
      id: 's14',
      name: 'Cafe Portillo Bustos',
      description:
          'A cozy and modern cafe offering a great selection of coffee and pastries, serving as a popular hangout spot for locals and visitors.',
      history:
          'Established to provide a contemporary coffee culture experience in Bustos, blending modern tastes with local hospitality.',
      latitude: 14.9560029,
      longitude: 120.9094761,
      category: SpotCategory.other,
      imageUrls: ['assets/images/galilee_wonderland_resort.jpg'],
      openingHours: '9:00 AM – 9:00 PM',
      entranceFee: 'Free',
      tips: [
        'Perfect place to relax after a day of touring',
        'Try their signature coffee blends',
        'A popular study and remote work spot',
      ],
      distanceFromTown: 0.6,
    ),

    const TouristSpotModel(
      id: 's15',
      name: 'San Isidro Labrador Parish Church - Liciada',
      description:
          'A beautiful parish church serving the spiritual needs of the community in Liciada, known for its peaceful ambiance and dedicated parishioners.',
      history:
          'Dedicated to San Isidro Labrador, the patron saint of farmers, reflecting the strong agricultural roots of the local community.',
      latitude: 14.9078610,
      longitude: 120.9290900,
      category: SpotCategory.church,
      imageUrls: ['assets/images/san_isidro_labrador_parish.jpg'],
      openingHours: '6:00 AM – 6:00 PM',
      entranceFee: 'Free',
      tips: [
        'Attend a Sunday mass for the full community experience',
        'Enjoy the quiet and serene environment',
        'Located a bit further from the town center',
      ],
      distanceFromTown: 5.5,
    ),

    const TouristSpotModel(
      id: 's16',
      name: 'El Reloj del Centenario de Bustos (Bustos Clock Tower)',
      description:
          'A prominent clock tower that serves as a modern landmark in Bustos, commemorating the town\'s history and progress.',
      history:
          'Built as part of the centennial celebrations, it stands as a symbol of Bustos\' continuous march towards development while honoring its past.',
      latitude: 14.9548746,
      longitude: 120.9190243,
      category: SpotCategory.heritage,
      imageUrls: ['assets/images/bustos_clock_tower.jpg'],
      openingHours: 'Open 24 hours',
      entranceFee: 'Free',
      tips: [
        'Easily visible from the main roads',
        'A great meeting point in the town center',
        'Beautifully lit at night',
      ],
      distanceFromTown: 0.1,
    ),

    const TouristSpotModel(
      id: 's17',
      name: 'Bustos Welcome Arch',
      description:
          'The grand entrance arch of the municipality, greeting visitors with local designs and serving as a boundary marker.',
      history:
          'Erected to formally welcome travelers and showcase the pride of Bustosenyos, marking the boundary with neighboring towns.',
      latitude: 14.9485074,
      longitude: 120.9580958,
      category: SpotCategory.heritage,
      imageUrls: ['assets/images/bustos_welcome_arch.jpg'],
      openingHours: 'Open 24 hours',
      entranceFee: 'Free',
      tips: [
        'A classic photo op for road-trippers',
        'Be careful of traffic when taking photos',
        'Marks the transition into the town',
      ],
      distanceFromTown: 4.5,
    ),

    const TouristSpotModel(
      id: 's18',
      name: 'Summer Place Resort',
      description:
          'A refreshing local resort that offers a cool escape during the hot summer months, featuring well-maintained pools and recreational facilities.',
      history:
          'A favored destination for local excursions and a quick getaway for those wanting to relax without traveling far from town.',
      latitude: 14.9561022,
      longitude: 120.9504986,
      category: SpotCategory.other,
      imageUrls: ['assets/images/summer_place_resort.jpg'],
      openingHours: '8:00 AM – 5:00 PM',
      entranceFee: '₱150',
      tips: [
        'Great for casual swimming and small parties',
        'Inquire about exclusive rentals',
        'Bring your own food and drinks',
      ],
      distanceFromTown: 3.8,
    ),

    const TouristSpotModel(
      id: 's19',
      name: 'Daily Bread Organic Farm',
      description:
          'A serene organic farm advocating for sustainable agriculture, offering visitors a glimpse into eco-friendly farming practices and fresh produce.',
      history:
          'Established to promote healthy living and sustainable farming, it has become an educational destination for nature lovers and students.',
      latitude: 14.9391250,
      longitude: 120.9421563,
      category: SpotCategory.nature,
      imageUrls: ['assets/images/daily_bread_organic_farm.jpg'],
      openingHours: '8:00 AM – 4:00 PM',
      entranceFee: '₱100',
      tips: [
        'Try their fresh organic meals if available',
        'Wear comfortable walking shoes',
        'Learn about their composting and farming techniques',
      ],
      distanceFromTown: 3.0,
    ),

    const TouristSpotModel(
      id: 's20',
      name: 'Minasa Festival',
      description:
          'The premier annual cultural festival of Bustos, celebrating the town\'s famous Minasa cookies with colorful street dances and parades.',
      history:
          'Initiated to promote local tourism and the traditional Minasa cookie industry, which dates back to the Spanish era when the cookies were made for the elite.',
      latitude: 14.9534,
      longitude: 120.9189,
      category: SpotCategory.other,
      imageUrls: ['assets/images/minasa_festival.jpg'],
      openingHours: 'Every January (Schedule varies)',
      entranceFee: 'Free',
      tips: [
        'Plan your visit around the second week of January',
        'Expect large crowds and road closures',
        'Don\'t miss the street dancing competition',
      ],
      distanceFromTown: 0.2,
    ),
  ];
}

class TourPackageModel {
  final String id;
  final String name;
  final String description;
  final String duration;
  final List<String> spotIds;
  final double estimatedFare;
  final String imageUrl;
  final List<String> highlights;

  const TourPackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.spotIds,
    required this.estimatedFare,
    required this.imageUrl,
    required this.highlights,
  });

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
      estimatedFare: 700,
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
      estimatedFare: 850,
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
      estimatedFare: 1000,
      imageUrl: 'assets/images/galilee_wonderland_resort.jpg',
      highlights: [
        'Fixed eight-stop itinerary',
        'Heritage and chapel trail',
        'Galilee Wailing Wall',
        'Minasa pasalubong stop',
      ],
    ),
  ];
}
