               import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Service for push notifications
class NotificationsService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  /// Initialize push notifications
  static Future<void> initialize() async {
    // Request permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (kDebugMode) {
      print('Notification permission status: ${settings.authorizationStatus}');
    }
    
    // Get token
    final token = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print('FCM Token: $token');
    }
    
    // Subscribe to topics
    await subscribeToTopic('all');
    await subscribeToTopic('matches');
    await subscribeToTopic('messages');
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle when app opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Check if app was opened from notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }
  }
  
  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }
  
  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
  
  /// Handle foreground message
  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Received foreground message: ${message.notification?.title}');
    }
    
    // Show local notification
    // You can use flutter_local_notifications package here
  }
  
  /// Handle when app opened from notification
  static void _handleMessageOpenedApp(RemoteMessage message) {
    _navigateToMessage(message);
  }
  
  /// Handle initial message (when app was closed)
  static void _handleInitialMessage(RemoteMessage message) {
    _navigateToMessage(message);
  }
  
  /// Navigate based on message data
  static void _navigateToMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    
    switch (type) {
      case 'match':
        // Navigate to likes
        break;
      case 'message':
        // Navigate to chat
        final conversationId = data['conversationId'];
        if (conversationId != null) {
          // Use global key or navigation service
        }
        break;
      default:
        break;
    }
  }
  
  /// Save token to Firestore for this user
  static Future<void> saveTokenToFirestore(String userId) async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      // Save to user document
      // await FirebaseFirestore.instance.collection('users').doc(userId).update({
      //   'fcmToken': token,
      // });
    }
  }
  
  /// Get FCM token
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
