import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

abstract interface class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<void> loginWithMagicLink(String email);
  Future<AppUser> verifyMagicLink(String email, String emailLink);
  Future<String?> retrievePendingEmail();
  bool isSignInWithEmailLink(String link);
  Future<void> loginWithGoogle();
  Future<void> logout();
  Stream<AppUser?> get userChanges;
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static const _emailKey = 'pending_magic_link_email';

  @override
  Future<void> loginWithGoogle() async {
    // Web-specific Google Sign-In
    await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
  }

  @override
  Future<void> logout() async {

    await _firebaseAuth.signOut();
  }

  @override
  Stream<AppUser?> get userChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return _mapFirebaseUser(user);
    });
  }

  AppUser _mapFirebaseUser(User user) {
    // TODO: Fetch role from Firestore "users" collection
    // For now, default to wholesaler unless email is whitelisted
    final role = user.email == 'admin@croma.com' 
        ? UserRole.superUser 
        : UserRole.wholesaler;

    return AppUser(
      id: user.uid,
      email: user.email!,
      role: role,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }
}

class MockAuthRepository implements AuthRepository {
  AppUser? _currentUser;
  final _userController = StreamController<AppUser?>.broadcast();

  @override
  Future<AppUser?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentUser;
  }

  @override
  Future<void> loginWithMagicLink(String email) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<String?> retrievePendingEmail() async => 'admin@croma.com';

  @override
  bool isSignInWithEmailLink(String link) => link == 'mock-token';

  @override
  Future<void> loginWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = AppUser(
      id: 'mock-google-user',
      email: 'user@gmail.com',
      role: UserRole.wholesaler,
      createdAt: DateTime.now(),
    );
    _userController.add(_currentUser);
  }

  @override
  Future<AppUser> verifyMagicLink(String email, String token) async {
    // Mock implementation ignores email/token specifics
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = AppUser(
      id: 'mock-user-id',
      email: 'admin@croma.com',
      role: UserRole.superUser,
      createdAt: DateTime.now(),
    );
    _userController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _userController.add(null);
  }

  @override
  Stream<AppUser?> get userChanges => _userController.stream;
}
