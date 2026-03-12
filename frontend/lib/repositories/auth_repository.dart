import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<AppUser> impersonateUser(String targetUserId);
  Stream<AppUser?> get userChanges;
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _emailKey = 'pending_magic_link_email';

  /// Cached role from the most recent verifyMagicLink call. Used as fallback
  /// in _fetchUserProfile when Firestore read fails or returns no role,
  /// preventing the race condition where authStateChanges overwrites a
  /// supplier/superUser role with the default wholesaler fallback.
  UserRole? _lastVerifiedRole;

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _fetchUserProfile(user);
  }

  @override
  Future<void> loginWithMagicLink(String email) async {
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

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final customToken = data['token'] as String;

      // 2. Sign in with Firebase Custom Token
      final userCredential = await _firebaseAuth.signInWithCustomToken(customToken);

      final user = userCredential.user;
      if (user == null) throw Exception('Sign in failed');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emailKey);

      // Parse role and address from enriched backend response.
      // Cache the role so _fetchUserProfile can use it as fallback.
      final role = _parseRole(data['role'] as String?, email);
      _lastVerifiedRole = role;
      ShippingAddress? savedAddress;
      if (data['savedAddress'] != null) {
        savedAddress = ShippingAddress.fromJson(
          Map<String, dynamic>.from(data['savedAddress'] as Map),
        );
      }

      return AppUser(
        id: user.uid,
        email: user.email ?? email,
        role: role,
        savedAddress: savedAddress,
        discordName: data['discordName'] as String?,
        phone: data['phone'] as String?,
        preferredPaymentMethod: data['preferredPaymentMethod'] as String?,
        wiseEmail: data['wiseEmail'] as String?,
        venmoHandle: data['venmoHandle'] as String?,
        paypalEmail: data['paypalEmail'] as String?,
        preferredLocale: data['preferredLocale'] as String?,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? DateTime.tryParse(data['updatedAt'] as String? ?? '')
            : null,
      );
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
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _fetchUserProfile(user);
    });
  }

  @override
  Future<AppUser> impersonateUser(String targetUserId) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    final idToken = await currentUser.getIdToken();
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}${ApiRoutes.users}/$targetUserId/impersonate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to impersonate: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final customToken = data['token'] as String;

    // Sign in as the target user
    final userCredential = await _firebaseAuth.signInWithCustomToken(customToken);
    final user = userCredential.user;
    if (user == null) throw Exception('Impersonation sign-in failed');

    final role = _parseRole(data['role'] as String?, user.email);
    _lastVerifiedRole = role;
    ShippingAddress? savedAddress;
    if (data['savedAddress'] != null) {
      savedAddress = ShippingAddress.fromJson(
        Map<String, dynamic>.from(data['savedAddress'] as Map),
      );
    }

    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      role: role,
      savedAddress: savedAddress,
      discordName: data['discordName'] as String?,
      phone: data['phone'] as String?,
      preferredPaymentMethod: data['preferredPaymentMethod'] as String?,
      wiseEmail: data['wiseEmail'] as String?,
      venmoHandle: data['venmoHandle'] as String?,
      paypalEmail: data['paypalEmail'] as String?,
      preferredLocale: data['preferredLocale'] as String?,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'] as String? ?? '')
          : null,
    );
  }

  /// Fetch user profile from Firestore for returning users (app restart).
  /// Falls back to cached verified role if available, otherwise default
  /// wholesaler role, when Firestore read fails.
  Future<AppUser> _fetchUserProfile(User user) async {
    UserRole role = _lastVerifiedRole ?? _parseRole(null, user.email);
    ShippingAddress? savedAddress;
    String? discordName;
    String? phone;
    String? preferredPaymentMethod;
    String? wiseEmail;
    String? venmoHandle;
    String? paypalEmail;
    String? preferredLocale;
    DateTime? updatedAt;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        role = _parseRole(data['role'] as String?, user.email);
        if (data['savedAddress'] != null) {
          savedAddress = ShippingAddress.fromJson(
            Map<String, dynamic>.from(data['savedAddress'] as Map),
          );
        }
        discordName = data['discordName'] as String?;
        phone = data['phone'] as String?;
        preferredPaymentMethod = data['preferredPaymentMethod'] as String?;
        wiseEmail = data['wiseEmail'] as String?;
        venmoHandle = data['venmoHandle'] as String?;
        paypalEmail = data['paypalEmail'] as String?;
        preferredLocale = data['preferredLocale'] as String?;
        final ts = data['updatedAt'];
        if (ts is Timestamp) updatedAt = ts.toDate();
      }
    } catch (e) {
      print('Failed to fetch user profile from Firestore: $e');
    }

    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      role: role,
      savedAddress: savedAddress,
      discordName: discordName,
      phone: phone,
      preferredPaymentMethod: preferredPaymentMethod,
      wiseEmail: wiseEmail,
      venmoHandle: venmoHandle,
      paypalEmail: paypalEmail,
      preferredLocale: preferredLocale,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  /// Parse role string, with admin@croma.com override for backwards compatibility.
  UserRole _parseRole(String? roleStr, String? email) {
    if (email == 'admin@croma.com') return UserRole.superUser;
    return switch (roleStr) {
      'wholesaler' => UserRole.wholesaler,
      'supplier' => UserRole.supplier,
      'super_user' || 'superUser' => UserRole.superUser,
      _ => UserRole.wholesaler,
    };
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
  Future<AppUser> impersonateUser(String targetUserId) async {
    throw UnimplementedError('Impersonation not supported in mock');
  }

  @override
  Stream<AppUser?> get userChanges => _userController.stream;
}
