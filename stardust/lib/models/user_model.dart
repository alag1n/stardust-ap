/// User model for Firestore
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? bio;
  final int age;
  final String gender;
  final String? interestedIn;
  final List<String> interests;
  final List<String> photos;
  final DateTime createdAt;
  final DateTime? lastActive;
  final double? latitude;
  final double? longitude;
  final String? location;
  final bool isPremium;
  final int likesCount;
  final int matchesCount;
  final bool isProfileComplete;
  final bool isActive; // видимость в поиске
  final bool isVisible;
  final bool isOnline; // онлайн статус
  final int superLikesToday; // использовано суперлайков сегодня
  final DateTime? superLikesResetDate; // когда сбросить счётчик

  // Настройки поиска
  final String preferredGender;
  final int preferredAgeMin;
  final int preferredAgeMax;
  final double preferredDistance;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.bio,
    required this.age,
    required this.gender,
    this.interestedIn,
    this.interests = const [],
    this.photos = const [],
    required this.createdAt,
    this.lastActive,
    this.latitude,
    this.longitude,
    this.location,
    this.isPremium = false,
    this.likesCount = 0,
    this.matchesCount = 0,
    this.isProfileComplete = false,
    this.isActive = true,
    this.isVisible = true,
    this.isOnline = false,
    this.superLikesToday = 0,
    this.superLikesResetDate = null,
    this.preferredGender = 'all',
    this.preferredAgeMin = 18,
    this.preferredAgeMax = 45,
    this.preferredDistance = 50.0,
  });

  /// Check if profile is complete enough to show in search
  bool get canAppearInSearch {
    return isProfileComplete &&
        isActive &&
        isVisible &&
        name.isNotEmpty &&
        age > 0 &&
        gender.isNotEmpty &&
        (photoUrl != null || photos.isNotEmpty);
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      interestedIn: data['interestedIn'],
      interests: List<String>.from(data['interests'] ?? []),
      photos: List<String>.from(data['photos'] ?? []),
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      lastActive: data['lastActive'] != null 
          ? DateTime.parse(data['lastActive'])
          : null,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      location: data['location'],
      isPremium: data['isPremium'] ?? false,
      likesCount: data['likesCount'] ?? 0,
      matchesCount: data['matchesCount'] ?? 0,
      isProfileComplete: data['isProfileComplete'] ?? false,
      isActive: data['isActive'] ?? true,
      isVisible: data['isVisible'] ?? true,
      isOnline: data['isOnline'] ?? false,
      superLikesToday: data['superLikesToday'] ?? 0,
      superLikesResetDate: data['superLikesResetDate'] != null 
          ? DateTime.parse(data['superLikesResetDate']) 
          : null,
      preferredGender: data['preferredGender'] ?? 'all',
      preferredAgeMin: data['preferredAgeMin'] ?? 18,
      preferredAgeMax: data['preferredAgeMax'] ?? 45,
      preferredDistance: (data['preferredDistance'] ?? 50).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'bio': bio,
      'age': age,
      'gender': gender,
      'interestedIn': interestedIn,
      'interests': interests,
      'photos': photos,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'isPremium': isPremium,
      'likesCount': likesCount,
      'matchesCount': matchesCount,
      'isProfileComplete': isProfileComplete,
      'isActive': isActive,
      'isVisible': isVisible,
      'isOnline': isOnline,
      'superLikesToday': superLikesToday,
      'superLikesResetDate': superLikesResetDate?.toIso8601String(),
      'preferredGender': preferredGender,
      'preferredAgeMin': preferredAgeMin,
      'preferredAgeMax': preferredAgeMax,
      'preferredDistance': preferredDistance,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? bio,
    int? age,
    String? gender,
    String? interestedIn,
    List<String>? interests,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? lastActive,
    double? latitude,
    double? longitude,
    String? location,
    bool? isPremium,
    int? likesCount,
    int? matchesCount,
    bool? isProfileComplete,
    bool? isActive,
    bool? isVisible,
    String? preferredGender,
    int? preferredAgeMin,
    int? preferredAgeMax,
    double? preferredDistance,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      interests: interests ?? this.interests,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      isPremium: isPremium ?? this.isPremium,
      likesCount: likesCount ?? this.likesCount,
      matchesCount: matchesCount ?? this.matchesCount,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isActive: isActive ?? this.isActive,
      isVisible: isVisible ?? this.isVisible,
      preferredGender: preferredGender ?? this.preferredGender,
      preferredAgeMin: preferredAgeMin ?? this.preferredAgeMin,
      preferredAgeMax: preferredAgeMax ?? this.preferredAgeMax,
      preferredDistance: preferredDistance ?? this.preferredDistance,
    );
  }
}
