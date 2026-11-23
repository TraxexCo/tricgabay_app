// Real photos of the places, from Wikimedia Commons (free licences).
// The first photo of each place is the cover and shows no people.
// Credits are shown in the photo viewer, as the licences require.

class PlacePhoto {
  const PlacePhoto(this.path, this.author, this.licence);
  final String path, author, licence;
}

class PlacePhotos {
  static const _floro = 'Judgefloro';
  static const _jfvFloro = 'JFVelasquez Floro';
  static const _kurteous = 'KurteousDerhen';
  static const _domingo = 'Elmer B. Domingo';
  static const _fbenjr = 'FBenjr123';
  static const _pd = 'Public domain';
  static const _cc0 = 'CC0';
  static const _bySa3 = 'CC BY-SA 3.0';
  static const _bySa4 = 'CC BY-SA 4.0';

  /// Author and licence of each photo, in order; photo n of a place is
  /// `assets/optimized_images/places/<place id>_<n>.webp`.
  static const Map<String, List<(String, String)>> _credits = {
    'sta-cruz-chapel': [
      (_floro, _pd),
      (_floro, _pd),
      (_floro, _pd),
      (_floro, _pd),
      (_floro, _pd),
      (_floro, _pd),
    ],
    'sta-monica-chapel': [
      (_jfvFloro, _cc0),
      (_jfvFloro, _cc0),
      (_jfvFloro, _cc0),
      (_jfvFloro, _cc0),
      (_jfvFloro, _cc0),
    ],
    'sto-nino-church': [
      (_floro, _pd),
      (_kurteous, _bySa4),
      (_floro, _pd),
      (_jfvFloro, _cc0),
      (_domingo, _bySa3),
      (_jfvFloro, _cc0),
    ],
    'st-peter-chapel': [
      (_floro, _bySa3),
      (_floro, _bySa3),
      (_floro, _bySa3),
      (_floro, _bySa3),
      (_floro, _bySa3),
    ],
    'perpetual-help-chapel': [
      (_floro, _cc0),
      (_floro, _cc0),
      (_floro, _cc0),
      (_floro, _cc0),
      (_floro, _cc0),
    ],
    'sto-rosario-chapel': [
      (_floro, _bySa3),
      (_floro, _bySa3),
      (_floro, _bySa3),
      (_floro, _bySa3),
      (_floro, _bySa3),
    ],
    'immaculate-conception-chapel': [
      (_fbenjr, _bySa4),
      (_fbenjr, _bySa4),
      (_fbenjr, _bySa4),
      (_fbenjr, _bySa4),
      (_fbenjr, _bySa4),
      (_floro, _pd),
    ],
    'bustos-heritage-park': [
      (_floro, _pd),
      (_floro, _pd),
      (_floro, _pd),
      (_floro, _pd),
      (_floro, _pd),
    ],
  };

  static List<PlacePhoto> _photos(String spotId) => [
    for (final (i, (author, licence)) in (_credits[spotId] ?? const []).indexed)
      PlacePhoto(
        'assets/optimized_images/places/${spotId}_${i + 1}.webp',
        author,
        licence,
      ),
  ];

  /// Photo paths for a place, or [fallback] when there are none bundled.
  static List<String> pathsFor(String spotId, List<String> fallback) {
    final photos = _photos(spotId);
    return photos.isEmpty ? fallback : [for (final p in photos) p.path];
  }

  /// The credit for a bundled photo, or null for other images.
  static PlacePhoto? creditFor(String path) {
    for (final spotId in _credits.keys) {
      for (final photo in _photos(spotId)) {
        if (photo.path == path) return photo;
      }
    }
    return null;
  }
}
