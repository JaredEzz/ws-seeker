/// Authentication middleware for protected routes
library;

import 'dart:convert';

import 'package:dart_firebase_admin/firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

/// Context keys for authenticated request data
abstract final class AuthContext {
  static const String userId = 'auth.userId';
  static const String userRole = 'auth.userRole';
  static const String userEmail = 'auth.userEmail';
}

/// Cached Google public keys for Firebase ID token verification.
Map<String, String>? _cachedKeys;
DateTime? _cacheExpiry;

/// Fetch Google's public keys for verifying Firebase ID tokens.
Future<Map<String, String>> _getGooglePublicKeys() async {
  if (_cachedKeys != null &&
      _cacheExpiry != null &&
      DateTime.now().isBefore(_cacheExpiry!)) {
    return _cachedKeys!;
  }

  final response = await http.get(Uri.parse(
    'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com',
  ));

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch Google public keys');
  }

  _cachedKeys = (jsonDecode(response.body) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v as String));

  // Parse Cache-Control max-age for expiry
  final cacheControl = response.headers['cache-control'] ?? '';
  final maxAgeMatch = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
  final maxAge = maxAgeMatch != null
      ? int.parse(maxAgeMatch.group(1)!)
      : 3600;
  _cacheExpiry = DateTime.now().add(Duration(seconds: maxAge));

  return _cachedKeys!;
}

/// Middleware that verifies Firebase ID tokens and attaches user info to context.
///
/// Bypasses dart_firebase_admin's verifyIdToken (which has a null-check bug
/// in DecodedIdToken.fromMap) and verifies directly with dart_jsonwebtoken
/// + Google's public keys.
Middleware authMiddleware(Firestore firestore, {required String projectId}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401,
            body: jsonEncode({'error': 'Missing or invalid Authorization header'}),
            headers: {'Content-Type': 'application/json'});
      }

      final token = authHeader.substring(7); // Strip "Bearer "

      try {
        // Decode header to get the key ID
        final unverified = JWT.decode(token);
        final kid = unverified.header?['kid'] as String?;
        if (kid == null) {
          return Response(401,
              body: jsonEncode({'error': 'Token missing kid header'}),
              headers: {'Content-Type': 'application/json'});
        }

        // Fetch Google's public keys
        final keys = await _getGooglePublicKeys();
        final certPem = keys[kid];
        if (certPem == null) {
          return Response(401,
              body: jsonEncode({'error': 'Token signed with unknown key'}),
              headers: {'Content-Type': 'application/json'});
        }

        // Verify signature and claims
        final jwt = JWT.verify(
          token,
          RSAPublicKey.cert(certPem),
          issuer: 'https://securetoken.google.com/$projectId',
          audience: Audience.one(projectId),
        );

        final payload = jwt.payload as Map<String, dynamic>;
        final uid = payload['sub'] as String?;
        if (uid == null || uid.isEmpty) {
          return Response(401,
              body: jsonEncode({'error': 'Token missing sub claim'}),
              headers: {'Content-Type': 'application/json'});
        }

        final email = payload['email'] as String? ?? '';

        // Look up user role from Firestore
        final userDoc = await firestore.collection('users').doc(uid).get();
        final role = _parseRole(
            userDoc.exists ? (userDoc.data()?['role'] as String?) : null);

        // Attach auth info to request context
        final updatedRequest = request.change(context: {
          AuthContext.userId: uid,
          AuthContext.userRole: role,
          AuthContext.userEmail: email,
        });

        return innerHandler(updatedRequest);
      } on JWTExpiredException {
        return Response(401,
            body: jsonEncode({'error': 'Token expired'}),
            headers: {'Content-Type': 'application/json'});
      } on JWTException catch (e) {
        return Response(401,
            body: jsonEncode({'error': 'Invalid token: $e'}),
            headers: {'Content-Type': 'application/json'});
      } catch (e, stack) {
        print('Auth middleware error: $e');
        print('Auth middleware stack: $stack');
        return Response.internalServerError(
            body: jsonEncode({'error': 'Authentication failed: $e'}),
            headers: {'Content-Type': 'application/json'});
      }
    };
  };
}

/// Parse role string to UserRole enum, defaulting to wholesaler
UserRole _parseRole(String? role) {
  return switch (role) {
    'supplier' => UserRole.supplier,
    'super_user' || 'superUser' => UserRole.superUser,
    _ => UserRole.wholesaler,
  };
}
