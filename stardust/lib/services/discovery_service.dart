import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

/// Service for getting users for discovery/swipe
class DiscoveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get users for discovery (excluding current user and already liked)
  /// with filters: age range, distance, gender
  Future<List<UserModel>> getDiscoveryUsers({
    required String currentUserId,
    List<String>? likedUserIds,
    int limit = 20,
    // User's search preferences
    String gender = 'all', // all, male, female
    int? ageMin,
    int? ageMax,
    double? maxDistanceKm,
    double? userLatitude,
    double? userLongitude,
  }) async {
    // Get all active users with complete profiles
    QuerySnapshot snapshot;
    
    if (gender != 'all') {
      snapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .where('isVisible', isEqualTo: true)
          .where('isProfileComplete', isEqualTo: true)
          .where('gender', isEqualTo: gender)
          .limit(limit * 3)
          .get();
    } else {
      snapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .where('isVisible', isEqualTo: true)
          .where('isProfileComplete', isEqualTo: true)
          .limit(limit * 3)
          .get();
    }
    
    final users = <UserModel>[];
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data is! Map) continue;
      final user = UserModel.fromFirestore(Map<String, dynamic>.from(data), doc.id);
      
      // Skip current user
      if (user.id == currentUserId) continue;
      
      // Skip already liked users
      if (likedUserIds?.contains(user.id) ?? false) continue;
      
      // Skip users without photo
      if (user.photoUrl == null && user.photos.isEmpty) continue;
      
      // Filter by age
      if (ageMin != null && user.age < ageMin) continue;
      if (ageMax != null && user.age > ageMax) continue;
      
      // Filter by distance (if we have coordinates)
      if (maxDistanceKm != null && userLatitude != null && userLongitude != null) {
        if (user.latitude != null && user.longitude != null) {
          final distance = _calculateDistance(
            userLatitude,
            userLongitude,
            user.latitude!,
            user.longitude!,
          );
          if (distance > maxDistanceKm) continue;
        }
      }
      
      users.add(user);
      
      if (users.length >= limit) break;
    }
    
    return users;
  }
  
  /// Get recommended users based on preferences (alias for getDiscoveryUsers)
  Future<List<UserModel>> getRecommendedUsers({
    required String currentUserId,
    required String gender,
    required int ageMin,
    required int ageMax,
    List<String>? likedUserIds,
    double? maxDistanceKm,
    double? userLatitude,
    double? userLongitude,
    int limit = 20,
  }) async {
    return getDiscoveryUsers(
      currentUserId: currentUserId,
      likedUserIds: likedUserIds,
      limit: limit,
      gender: gender,
      ageMin: ageMin,
      ageMax: ageMax,
      maxDistanceKm: maxDistanceKm,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
  }
  
  /// Calculate distance between two points in kilometers
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // Haversine formula
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    
    final a = 
      _sin(dLat / 2) * _sin(dLat / 2) +
      _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
      _sin(dLng / 2) * _sin(dLng / 2);
    
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }
  
  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
  double _sin(double x) => _sinApprox(x);
  double _cos(double x) => _cosApprox(x);
  double _sqrt(double x) => _sqrtApprox(x);
  double _atan2(double y, double x) => _atan2Approx(y, x);
  
  double _sinApprox(double x) {
    // Normalize to -PI to PI
    while (x > 3.141592653589793) x -= 2 * 3.141592653589793;
    while (x < -3.141592653589793) x += 2 * 3.141592653589793;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
  
  double _cosApprox(double x) {
    return _sinApprox(x + 1.5707963267948966);
  }
  
  double _sqrtApprox(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  
  double _atan2Approx(double y, double x) {
    if (x > 0) return _atanApprox(y / x);
    if (x < 0 && y >= 0) return _atanApprox(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atanApprox(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 1.5707963267948966;
    if (x == 0 && y < 0) return -1.5707963267948966;
    return 0;
  }
  
  double _atanApprox(double x) {
    if (x > 1) return 1.5707963267948966 - _atanApprox(1 / x);
    if (x < -1) return -1.5707963267948966 - _atanApprox(1 / x);
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
  }
  
  /// Mark profile as complete
  Future<void> markProfileComplete(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isProfileComplete': true,
    });
  }
  
  /// Check if user profile is complete
  Future<bool> isProfileComplete(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data()?['isProfileComplete'] ?? false;
    }
    return false;
  }
  
  /// Get user's search preferences
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return {
        'preferredGender': doc.data()?['preferredGender'] ?? 'all',
        'preferredAgeMin': doc.data()?['preferredAgeMin'] ?? 18,
        'preferredAgeMax': doc.data()?['preferredAgeMax'] ?? 45,
        'preferredDistance': doc.data()?['preferredDistance'] ?? 50.0,
        'latitude': doc.data()?['latitude'],
        'longitude': doc.data()?['longitude'],
      };
    }
    return null;
  }
  
  /// Update user's search preferences
  Future<void> updateUserPreferences(
    String userId, {
    String? preferredGender,
    int? preferredAgeMin,
    int? preferredAgeMax,
    double? preferredDistance,
  }) async {
    final updates = <String, dynamic>{};
    if (preferredGender != null) updates['preferredGender'] = preferredGender;
    if (preferredAgeMin != null) updates['preferredAgeMin'] = preferredAgeMin;
    if (preferredAgeMax != null) updates['preferredAgeMax'] = preferredAgeMax;
    if (preferredDistance != null) updates['preferredDistance'] = preferredDistance;
    
    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update(updates);
    }
  }
  
  /// Update user's location
  Future<void> updateUserLocation(
    String userId, {
    required double latitude,
    required double longitude,
    String? location,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
    });
  }
}
