import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPresenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Set user as online
  static Future<void> setUserOnline() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  // Set user as offline
  static Future<void> setUserOffline() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get user online status
  static Stream<DocumentSnapshot> getUserPresence(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Mark message as read
  static Future<void> markMessageAsRead(String messageId, String userId) async {
    await _firestore.collection('chat').doc(messageId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  // Update message status
  static Future<void> updateMessageStatus(
    String messageId,
    String status,
  ) async {
    await _firestore.collection('chat').doc(messageId).update({
      'status': status,
    });
  }
}
