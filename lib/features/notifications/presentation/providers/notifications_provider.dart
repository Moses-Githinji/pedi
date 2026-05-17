import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pedi/core/utils/logger.dart';
import '../../domain/models/notification_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class NotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of user notifications list
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            // Seed a few friendly demo notifications for a gorgeous first-run experience
            _seedDemoNotifications(userId);
            return [];
          }
          final list = snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
          // Sort descending in memory
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Stream of unread notifications count
  Stream<int> getUnreadNotificationsCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark a specific notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      logger.d('Notification marked as read: $notificationId');
    } catch (e) {
      logger.e('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final unreadQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadQuery.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in unreadQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      logger.i('All notifications marked as read for user: $userId');
    } catch (e) {
      logger.e('Error marking all notifications as read: $e');
    }
  }

  // Create a new notification
  Future<void> createNotification(
    String targetUserId, {
    required String type,
    required String senderId,
    required String senderName,
    required String senderPhotoUrl,
    String? postId,
    required String text,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .add({
            'type': type,
            'senderId': senderId,
            'senderName': senderName,
            'senderPhotoUrl': senderPhotoUrl,
            'postId': postId,
            'text': text,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
      logger.d('Notification created successfully for user: $targetUserId');
    } catch (e) {
      logger.e('Error creating notification: $e');
    }
  }

  // Seed demo notifications to showcase a premium first-time experience
  void _seedDemoNotifications(String userId) {
    final notificationsRef = _firestore.collection('users').doc(userId).collection('notifications');
    final batch = _firestore.batch();

    final now = DateTime.now();

    final demoData = [
      {
        'type': 'follow',
        'senderId': 'alex_uid',
        'senderName': 'alex_smith',
        'senderPhotoUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&fit=crop&q=80',
        'text': 'started following you.',
        'isRead': false,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      },
      {
        'type': 'like',
        'senderId': 'jordan_uid',
        'senderName': 'jordan_b',
        'senderPhotoUrl': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&fit=crop&q=80',
        'text': 'liked your video post.',
        'isRead': false,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 4))),
      },
      {
        'type': 'comment',
        'senderId': 'sam_uid',
        'senderName': 'sam_cook',
        'senderPhotoUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&fit=crop&q=80',
        'text': 'commented: "This is fire! 🔥 Go check mine too."',
        'isRead': false,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
    ];

    for (var data in demoData) {
      final docRef = notificationsRef.doc();
      batch.set(docRef, data);
    }

    batch.commit().catchError((e) {
      logger.e('Failed to seed demo notifications: $e');
    });
  }
}

// Providers
final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) return Stream.value([]);
  return ref.watch(notificationsServiceProvider).getNotificationsStream(user.uid);
});

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) return Stream.value(0);
  return ref.watch(notificationsServiceProvider).getUnreadNotificationsCountStream(user.uid);
});
