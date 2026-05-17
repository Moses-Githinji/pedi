import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type; // 'like', 'comment', 'follow'
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String? postId;
  final String text;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    this.postId,
    required this.text,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse createdAt dynamic type (Timestamp or String or null)
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
    }

    return NotificationModel(
      id: doc.id,
      type: data['type'] ?? 'info',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Someone',
      senderPhotoUrl: data['senderPhotoUrl'] ?? '',
      postId: data['postId'],
      text: data['text'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'postId': postId,
      'text': text,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? postId,
    String? text,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      postId: postId ?? this.postId,
      text: text ?? this.text,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
