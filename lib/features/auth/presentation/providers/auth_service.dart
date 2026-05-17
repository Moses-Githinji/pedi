import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:pedi/core/utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Ensure initialized (you already do this in main.dart)
      final googleSignIn = gsi.GoogleSignIn.instance;

      // Trigger sign-in
      final gsi.GoogleSignInAccount? googleUser = await googleSignIn
          .authenticate();

      if (googleUser == null) {
        logger.i('Google Sign-In canceled by user.');
        return null;
      }

      // Get authentication tokens
      final gsi.GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // Create Firebase credential using the ID Token (accessToken is not needed for Firebase Google Auth)
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Create Firestore profile for new users
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        if (userCredential.user != null) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'uid': userCredential.user!.uid,
                'email': userCredential.user!.email,
                'username':
                    userCredential.user!.displayName ??
                    'user_${userCredential.user!.uid.substring(0, 5)}',
                'createdAt': FieldValue.serverTimestamp(),
              });
        }
      }

      logger.i('Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;
    } on gsi.GoogleSignInException catch (e) {
      if (e.code == gsi.GoogleSignInExceptionCode.canceled) {
        logger.i('Google Sign-In canceled by user.');
        return null;
      }
      logger.e('GoogleSignInException: ${e.code} - ${e.description}');
      rethrow;
    } catch (e, stack) {
      logger.e('Unexpected Google Sign-In Error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register with email, password, and username
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update the display name
    await userCredential.user?.updateDisplayName(username);

    // Save basic user info to Firestore
    if (userCredential.user != null) {
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return userCredential;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await gsi.GoogleSignIn.instance.signOut();
  }
}
