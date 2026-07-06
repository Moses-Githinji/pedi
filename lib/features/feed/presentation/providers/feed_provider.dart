import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/post_model.dart';
import '../../../../core/utils/logger.dart';

final feedProvider = StreamProvider.autoDispose<List<PostModel>>((ref) {
  logger.i('Initializing feed provider stream');
  
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    logger.d('Received ${snapshot.docs.length} posts from Firestore');
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  });
});
