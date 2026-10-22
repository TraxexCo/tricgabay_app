class FarePolicy {
  final int revision;
  final int customFareCents;
  final Map<String, int> packageFares;
  final List<String> history;
  const FarePolicy({
    this.revision = 1,
    this.customFareCents = 7000,
    this.packageFares = const {
      'tric-lakbay': 70000,
      'tric-saya': 85000,
      'tric-tuklas': 100000,
    },
    this.history = const [],
  });

  int quote(String? packageId) {
    if (packageId == null) return customFareCents;
    final fare = packageFares[packageId];
    if (fare == null) throw StateError('This package has no published price.');
    return fare;
  }

  static int parsePrice(String text) {
    if (!RegExp(r'^\d{1,6}(\.\d{1,2})?$').hasMatch(text.trim())) {
      throw const FormatException(
        'Enter pesos with at most two decimal places.',
      );
    }
    final cents = (double.parse(text.trim()) * 100).round();
    if (cents <= 0 || cents > 10000000) {
      throw const FormatException('Enter a price between ₱0.01 and ₱100,000.');
    }
    return cents;
  }

  Map<String, dynamic> toMap() => {
    'revision': revision,
    'customFareCents': customFareCents,
    'packageFares': packageFares,
    'history': history,
  };
  factory FarePolicy.fromMap(Map<String, dynamic> map) => FarePolicy(
    revision: map['revision'],
    customFareCents: map['customFareCents'],
    packageFares: Map<String, int>.from(map['packageFares']),
    history: List<String>.from(map['history'] ?? []),
  );
}
