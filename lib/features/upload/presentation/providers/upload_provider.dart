import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pedi/core/utils/logger.dart';
import '../../../feed/domain/models/post_model.dart';

class UploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload video file to Firebase Storage with a live progress callback
  Future<String> uploadVideo({
    required String uid,
    required String filePath,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final file = File(filePath);
      final postId = _firestore.collection('posts').doc().id;
      final ref = _storage.ref().child('videos').child('$postId.mp4');

      final uploadTask = ref.putFile(file);

      // Listen to progress changes
      final subscription = uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      try {
        final snapshot = await uploadTask.timeout(const Duration(minutes: 5));
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } finally {
        await subscription.cancel();
      }
    } catch (e) {
      logger.e('Error uploading video to storage: $e');
      rethrow;
    }
  }

  /// Create a new post document in Firestore
  Future<void> createPost({
    required String creatorId,
    required String creatorName,
    required String creatorPhotoUrl,
    required String videoUrl,
    required String title,
    required String description,
    required String location,
    double? latitude,
    double? longitude,
    required List<String> tags,
  }) async {
    try {
      final postDoc = _firestore.collection('posts').doc();
      final post = PostModel(
        id: postDoc.id,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorPhotoUrl: creatorPhotoUrl,
        videoUrl: videoUrl,
        thumbnailUrl: 'https://picsum.photos/seed/${postDoc.id}/300/500',
        title: title,
        description: description,
        location: location,
        latitude: latitude,
        longitude: longitude,
        tags: tags,
        createdAt: DateTime.now(),
      );

      await postDoc.set(post.toMap());
      logger.i('Post successfully created: ${postDoc.id}');
    } catch (e) {
      logger.e('Error creating post in Firestore: $e');
      rethrow;
    }
  }
}

final uploadServiceProvider = Provider((ref) => UploadService());

class UploadProgressNotifier extends Notifier<double> {
  @override
  double build() => 0.0;
  void set(double value) => state = value;
}

final uploadProgressProvider = NotifierProvider<UploadProgressNotifier, double>(UploadProgressNotifier.new);
