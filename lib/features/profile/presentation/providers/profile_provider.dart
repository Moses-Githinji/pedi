import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pedi/core/utils/logger.dart';
import '../../domain/models/user_model.dart';
import '../../../feed/domain/models/post_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of user profile details
  Stream<UserModel> getProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        // Self-heal: Create user document in Firestore asynchronously if it doesn't exist yet
        final currentUser = _auth.currentUser;
        final email = currentUser?.email ?? '';
        final displayName = currentUser?.displayName ?? 'New User';
        final username = currentUser?.displayName
                ?.toLowerCase()
                .replaceAll(' ', '_')
                .replaceAll(RegExp(r'[^a-z0-9_]'), '') ??
            'user_${uid.substring(0, 5)}';
        final photoUrl = currentUser?.photoURL ??
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=150';

        _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'username': username,
          'photoUrl': photoUrl,
          'bio': '',
          'followersCount': 0,
          'followingCount': 0,
          'likesCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return UserModel(
          uid: uid,
          email: email,
          username: username,
          displayName: displayName,
          bio: '',
          photoUrl: photoUrl,
          followersCount: 0,
          followingCount: 0,
          likesCount: 0,
        );
      }
      return UserModel.fromFirestore(doc);
    });
  }

  // Check if username is unique/available
  Future<bool> isUsernameUnique(String uid, String username) async {
    try {
      final cleanUsername = username.trim().toLowerCase();
      if (cleanUsername.isEmpty) return false;

      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 2));

      if (query.docs.isEmpty) return true;
      return query.docs.first.id == uid;
    } catch (e) {
      logger.w('Username check timed out or failed: $e. Defaulting to true to prevent locking UI.');
      return true;
    }
  }

  // Update profile details in Firestore & Firebase Auth
  Future<void> updateProfile(
    String uid, {
    required String displayName,
    required String username,
    required String bio,
    String? photoUrl,
  }) async {
    try {
      final cleanUsername = username.trim().toLowerCase();
      
      // Update Firebase Auth display name and photo
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        try {
          await currentUser.updateDisplayName(displayName).timeout(const Duration(seconds: 2));
          if (photoUrl != null) {
            await currentUser.updatePhotoURL(photoUrl).timeout(const Duration(seconds: 2));
          }
        } catch (authError) {
          logger.w('Auth profile update timed out or failed (non-fatal): $authError');
        }
      }

      // Update Firestore user document
      final userRef = _firestore.collection('users').doc(uid);
      final Map<String, dynamic> dataToSet = {
        'uid': uid,
        'email': currentUser?.email ?? '',
        'displayName': displayName,
        'username': cleanUsername,
        'bio': bio,
      };
      if (photoUrl != null) {
        dataToSet['photoUrl'] = photoUrl;
      }

      try {
        await userRef.set(dataToSet, SetOptions(merge: true)).timeout(const Duration(seconds: 2));
      } catch (firestoreError) {
        logger.w('Firestore profile write timed out (will synchronize in background): $firestoreError');
        // Do not throw on timeout, as Firestore offline sync will seamlessly write to cache and sync in background.
      }

      logger.i('Profile update successfully triggered for UID: $uid');
    } catch (e) {
      logger.e('Error updating profile: $e');
      rethrow;
    }
  }

  // Upload profile photo to Firebase Storage
  Future<String> uploadProfileImage(String uid, String filePath) async {
    try {
      final file = File(filePath);
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      // Upload file with a 15-second timeout for robust performance
      final uploadTask = await ref.putFile(file).timeout(const Duration(seconds: 15));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      logger.e('Error uploading profile image to Firebase Storage: $e');
      rethrow;
    }
  }

  // Fetch posts uploaded by a specific user
  Stream<List<PostModel>> getUserPosts(String uid) {
    return _firestore
        .collection('posts')
        .where('creatorId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
          // Sort in memory to avoid missing index errors
          posts.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return posts;
        });
  }

  // Fetch posts liked by a specific user
  Stream<List<PostModel>> getUserLikedPosts(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('likedPosts')
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
          posts.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return posts;
        });
  }

  // Fetch posts saved by a specific user
  Stream<List<PostModel>> getUserSavedPosts(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('savedPosts')
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
          posts.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return posts;
        });
  }
}

// Providers
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final userProfileStreamProvider = StreamProvider.family<UserModel, String>((ref, uid) {
  final service = ref.watch(profileServiceProvider);
  return service.getProfileStream(uid);
});

final userPostsStreamProvider = StreamProvider.family<List<PostModel>, String>((ref, uid) {
  final service = ref.watch(profileServiceProvider);
  return service.getUserPosts(uid);
});

final userLikedPostsStreamProvider = StreamProvider.family<List<PostModel>, String>((ref, uid) {
  final service = ref.watch(profileServiceProvider);
  return service.getUserLikedPosts(uid);
});

final userSavedPostsStreamProvider = StreamProvider.family<List<PostModel>, String>((ref, uid) {
  final service = ref.watch(profileServiceProvider);
  return service.getUserSavedPosts(uid);
});
