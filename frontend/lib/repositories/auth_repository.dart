import 'package:ws_seeker_shared/ws_seeker_shared.dart';

abstract interface class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<void> loginWithMagicLink(String email);
  Future<AppUser> verifyMagicLink(String token);
  Future<void> logout();
  Stream<AppUser?> get userChanges;
}

class MockAuthRepository implements AuthRepository {
  AppUser? _currentUser;
  final _userController = StreamController<AppUser?>.broadcast();

  @override
  Future<AppUser?> getCurrentUser() async {
    // TODO: Check Firebase Auth current user and fetch Firestore profile
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentUser;
  }

  @override
  Future<void> loginWithMagicLink(String email) async {
    // TODO: Call backend Cloud Run endpoint POST /auth/magic-link
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, this sends an email. In mock, we do nothing.
  }

  @override
  Future<AppUser> verifyMagicLink(String token) async {
    // TODO: Call Firebase Auth signInWithEmailLink and fetch Firestore profile
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = AppUser(
      id: 'mock-user-id',
      email: 'taylor@croma.com',
      role: UserRole.superUser,
      createdAt: DateTime.now(),
    );
    _userController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    // TODO: Call Firebase Auth signOut
    _currentUser = null;
    _userController.add(null);
  }

  @override
  Stream<AppUser?> get userChanges => _userController.stream;
}

import 'dart:async';
