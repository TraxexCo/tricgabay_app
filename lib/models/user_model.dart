enum UserRole { tourist, driver, admin }

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      photoUrl: map['photoUrl'],
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.tourist,
      ),
      createdAt: map['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(map['createdAt'] as String),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber,
    'photoUrl': photoUrl,
    'role': role.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'isActive': isActive,
  };

  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? photoUrl,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum DriverStatus { online, offline, busy }

enum VerificationStatus { pending, verified, rejected }

class DriverModel {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? photoUrl;
  final String plateNumber;
  final String franchiseNumber;
  final String? licenseUrl;
  final String? franchiseUrl;
  final DriverStatus status;
  final VerificationStatus verificationStatus;
  final double rating;
  final int totalTrips;
  final double currentLat;
  final double currentLng;
  final DateTime createdAt;
  final bool isActive;

  const DriverModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.photoUrl,
    required this.plateNumber,
    required this.franchiseNumber,
    this.licenseUrl,
    this.franchiseUrl,
    this.status = DriverStatus.offline,
    this.verificationStatus = VerificationStatus.pending,
    this.rating = 0.0,
    this.totalTrips = 0,
    this.currentLat = 14.9500,
    this.currentLng = 120.9200,
    required this.createdAt,
    this.isActive = true,
  });

  factory DriverModel.fromMap(Map<String, dynamic> map, String id) {
    return DriverModel(
      id: id,
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      photoUrl: map['photoUrl'],
      plateNumber: map['plateNumber'] ?? '',
      franchiseNumber: map['franchiseNumber'] ?? '',
      licenseUrl: map['licenseUrl'],
      franchiseUrl: map['franchiseUrl'],
      status: DriverStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => DriverStatus.offline,
      ),
      verificationStatus: VerificationStatus.values.firstWhere(
        (s) => s.name == map['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalTrips: map['totalTrips'] ?? 0,
      currentLat: (map['currentLat'] ?? 14.9500).toDouble(),
      currentLng: (map['currentLng'] ?? 120.9200).toDouble(),
      createdAt: map['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(map['createdAt'] as String),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber,
    'photoUrl': photoUrl,
    'plateNumber': plateNumber,
    'franchiseNumber': franchiseNumber,
    'licenseUrl': licenseUrl,
    'franchiseUrl': franchiseUrl,
    'status': status.name,
    'verificationStatus': verificationStatus.name,
    'rating': rating,
    'totalTrips': totalTrips,
    'currentLat': currentLat,
    'currentLng': currentLng,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'isActive': isActive,
  };
}
