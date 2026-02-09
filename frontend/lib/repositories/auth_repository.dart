import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

abstract interface class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<void> loginWithMagicLink(String email);
  Future<AppUser> verifyMagicLink(String email, String emailLink);
  Future<void> logout();
  Stream<AppUser?> get userChanges;
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _mapFirebaseUser(user);
  }

  @override
  Future<void> loginWithMagicLink(String email) async {
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://ws-seeker.web.app/login', // Update with your domain
      handleCodeInApp: true,
      androidPackageName: 'com.croma.ws_seeker',
      androidInstallApp: true,
      androidMinimumVersion: '12',
      iOSBundleId: 'com.croma.wsSeeker',
    );

    await _firebaseAuth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
    
    // Save email locally for verification flow (simulated here, but usually stored in shared_preferences)
    // In Web, we might prompt user to re-enter email if opening link on different device.
  }

  @override
  Future<AppUser> verifyMagicLink(String email, String emailLink) async {
    if (_firebaseAuth.isSignInWithEmailLink(emailLink)) {
      final userCredential = await _firebaseAuth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      
      final user = userCredential.user;
      if (user == null) throw Exception('Sign in failed');
      
      return _mapFirebaseUser(user);
    } else {
      throw Exception('Invalid magic link');
    }
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
    final role = user.email == 'kenny@croma.com' 
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
  Future<AppUser> verifyMagicLink(String email, String token) async {
    // Mock implementation ignores email/token specifics
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = AppUser(
      id: 'mock-user-id',
      email: 'kenny@croma.com',
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
