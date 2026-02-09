import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

abstract interface class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<void> loginWithMagicLink(String email);
  Future<AppUser> verifyMagicLink(String email, String token);
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
  Future<AppUser?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _mapFirebaseUser(user);
  }

  @override
  Future<void> loginWithMagicLink(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${ApiRoutes.magicLink}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send magic link: ${response.body}');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailKey, email);
    } catch (e) {
      print('Failed to send magic link: $e');
      rethrow;
    }
  }

  @override
  Future<String?> retrievePendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  @override
  bool isSignInWithEmailLink(String link) {
    // We now use our custom token system, but we might still receive
    // callback links in the format /#/auth/callback?token=...
    final uri = Uri.parse(link);
    return uri.queryParameters.containsKey('token');
  }

  @override
  Future<AppUser> verifyMagicLink(String email, String tokenOrLink) async {
    try {
      String token = tokenOrLink;
      if (tokenOrLink.contains('token=')) {
        final uri = Uri.parse(tokenOrLink);
        token = uri.queryParameters['token'] ?? tokenOrLink;
      }

      // 1. Verify token with our backend and get Firebase Custom Token
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${ApiRoutes.verifyMagicLink}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to verify magic link: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final customToken = data['token'] as String;

      // 2. Sign in with Firebase Custom Token
      final userCredential = await _firebaseAuth.signInWithCustomToken(customToken);
      
      final user = userCredential.user;
      if (user == null) throw Exception('Sign in failed');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emailKey);

      return _mapFirebaseUser(user);
    } catch (e) {
      print('Verification failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> loginWithGoogle() async {
    // Use redirect instead of popup due to COOP headers required for WASM
    await _firebaseAuth.signInWithRedirect(GoogleAuthProvider());
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
