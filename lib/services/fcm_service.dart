import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM and request permissions
  static Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission for notifications');
        
        // Get FCM token
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

        // Set up message handlers
        _setupMessageHandlers();
        
      } else {
        print('User declined or has not accepted permission for notifications');
      }
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  /// Save FCM token to Firestore for the current user
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if user is an admin and get their authority
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      
      if (adminDoc.exists) {
        // User is an admin - save token to their authority
        final String authorityId = adminDoc.data()!['authorityId'];
        
        await _firestore.collection('authorities').doc(authorityId).update({
          'fcmTokens': FieldValue.arrayUnion([token])
        });
        
        print('Saved FCM token for authority admin: $authorityId');
      } else {
        // Regular user - save to user's profile
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print('Saved FCM token for user: ${user.uid}');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Set up message handlers for different app states
  static void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      
      if (message.notification != null) {
        _showLocalNotification(message);
      }
      
      _handleMessageData(message.data);
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened app: ${message.messageId}');
      _handleMessageTap(message.data);
    });

    // Handle messages when app is opened from terminated state
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('Message opened app from terminated state: ${message.messageId}');
        _handleMessageTap(message.data);
      }
    });
  }

  /// Show local notification for foreground messages
  static void _showLocalNotification(RemoteMessage message) {
    // In a production app, you would use flutter_local_notifications
    // For now, we'll just print the notification
    print('Notification: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
  }

  /// Handle message data payload
  static void _handleMessageData(Map<String, dynamic> data) {
    print('Message data: $data');
    
    // Handle different types of notifications
    if (data.containsKey('issueId')) {
      // Issue-related notification
      _handleIssueNotification(data);
    }
  }

  /// Handle notification tap (navigate to relevant screen)
  static void _handleMessageTap(Map<String, dynamic> data) {
    print('User tapped notification with data: $data');
    
    // In a production app, you would navigate to the relevant screen
    // For example, navigate to issue details if issueId is present
    if (data.containsKey('issueId')) {
      // Navigate to issue details screen
      // NavigationService.navigateToIssueDetails(data['issueId']);
    }
  }

  /// Handle issue-specific notifications
  static void _handleIssueNotification(Map<String, dynamic> data) {
    final String? issueId = data['issueId'];
    final String? authorityId = data['authorityId'];
    
    if (issueId != null && authorityId != null) {
      print('New issue $issueId assigned to authority $authorityId');
      
      // You could trigger a refresh of the admin dashboard here
      // or show an in-app notification
    }
  }

  /// Remove FCM token when user logs out
  static Future<void> removeToken() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? token = await _messaging.getToken();
      if (token == null) return;

      // Check if user is an admin
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      
      if (adminDoc.exists) {
        // Remove token from authority
        final String authorityId = adminDoc.data()!['authorityId'];
        
        await _firestore.collection('authorities').doc(authorityId).update({
          'fcmTokens': FieldValue.arrayRemove([token])
        });
        
        print('Removed FCM token from authority: $authorityId');
      } else {
        // Remove token from user profile
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
        
        print('Removed FCM token from user: ${user.uid}');
      }

      // Delete token from FCM
      await _messaging.deleteToken();
      
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }

  /// Subscribe to topic (for broadcast notifications)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  
  // Handle background message
  // You can perform light processing here, but avoid heavy operations
  
  if (message.data.containsKey('issueId')) {
    print('Background: New issue ${message.data['issueId']} received');
  }
}
