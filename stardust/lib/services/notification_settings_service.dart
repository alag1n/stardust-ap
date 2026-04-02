import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for notification settings
class NotificationSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get notification settings for user
  Future<Map<String, bool>> getNotificationSettings(String userId) async {
    final doc = await _firestore.collection('notification_settings').doc(userId).get();
    
    if (doc.exists) {
      return {
        'pushEnabled': doc.data()?['pushEnabled'] ?? true,
        'newMatch': doc.data()?['newMatch'] ?? true,
        'newMessage': doc.data()?['newMessage'] ?? true,
        'newLike': doc.data()?['newLike'] ?? true,
        'newSuperLike': doc.data()?['newSuperLike'] ?? true,
        'emailEnabled': doc.data()?['emailEnabled'] ?? true,
      };
    }
    
    // Default settings
    return {
      'pushEnabled': true,
      'newMatch': true,
      'newMessage': true,
      'newLike': true,
      'newSuperLike': true,
      'emailEnabled': true,
    };
  }
  
  /// Update notification settings
  Future<void> updateNotificationSettings(
    String userId, {
    bool? pushEnabled,
    bool? newMatch,
    bool? newMessage,
    bool? newLike,
    bool? newSuperLike,
    bool? emailEnabled,
  }) async {
    final updates = <String, dynamic>{};
    
    if (pushEnabled != null) updates['pushEnabled'] = pushEnabled;
    if (newMatch != null) updates['newMatch'] = newMatch;
    if (newMessage != null) updates['newMessage'] = newMessage;
    if (newLike != null) updates['newLike'] = newLike;
    if (newSuperLike != null) updates['newSuperLike'] = newSuperLike;
    if (emailEnabled != null) updates['emailEnabled'] = emailEnabled;
    
    if (updates.isNotEmpty) {
      await _firestore.collection('notification_settings').doc(userId).set(
        updates,
        SetOptions(merge: true),
      );
    }
  }
  
  /// Toggle all notifications
  Future<void> toggleAllNotifications(String userId, bool enabled) async {
    await _firestore.collection('notification_settings').doc(userId).set({
      'pushEnabled': enabled,
      'newMatch': enabled,
      'newMessage': enabled,
      'newLike': enabled,
      'newSuperLike': enabled,
      'emailEnabled': enabled,
    }, SetOptions(merge: true));
  }
}
