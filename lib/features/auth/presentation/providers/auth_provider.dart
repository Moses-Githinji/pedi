import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// StreamProvider that listens to the auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Simple notifiers for loading and error states
class AuthLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

class AuthErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

final authLoadingProvider = NotifierProvider<AuthLoadingNotifier, bool>(AuthLoadingNotifier.new);
final authErrorProvider = NotifierProvider<AuthErrorNotifier, String?>(AuthErrorNotifier.new);

// Action provider to handle auth logic
final authActionsProvider = Provider((ref) {
  final authService = ref.watch(authServiceProvider);
  
  return AuthActions(ref, authService);
});

class AuthActions {
  final Ref _ref;
  final AuthService _authService;

  AuthActions(this._ref, this._authService);

  Future<void> signIn(String email, String password) async {
    _ref.read(authLoadingProvider.notifier).set(true);
    _ref.read(authErrorProvider.notifier).set(null);
    try {
      await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _ref.read(authErrorProvider.notifier).set(e.toString());
    } finally {
      _ref.read(authLoadingProvider.notifier).set(false);
    }
  }

  Future<void> register(String email, String password, String username) async {
    _ref.read(authLoadingProvider.notifier).set(true);
    _ref.read(authErrorProvider.notifier).set(null);
    try {
      await _authService.registerWithEmailAndPassword(email, password, username);
    } catch (e) {
      _ref.read(authErrorProvider.notifier).set(e.toString());
    } finally {
      _ref.read(authLoadingProvider.notifier).set(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _ref.read(authLoadingProvider.notifier).set(true);
    _ref.read(authErrorProvider.notifier).set(null);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _ref.read(authErrorProvider.notifier).set(e.toString());
    } finally {
      _ref.read(authLoadingProvider.notifier).set(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
