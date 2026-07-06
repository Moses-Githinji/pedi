import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String creatorId;
  final String creatorName;
  final String creatorPhotoUrl;
  final String videoUrl;
  final String thumbnailUrl;
  final String title;
  final String description;
  final List<String> tags;
  final int likesCount;
  final int commentsCount;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.creatorPhotoUrl,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    required this.description,
    required this.tags,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PostModel(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      creatorPhotoUrl: data['creatorPhotoUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorPhotoUrl': creatorPhotoUrl,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'description': description,
      'tags': tags,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
