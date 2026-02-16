/// Authentication middleware for protected routes
library;

import 'dart:convert';

import 'package:dart_firebase_admin/auth.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:shelf/shelf.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

/// Context keys for authenticated request data
abstract final class AuthContext {
  static const String userId = 'auth.userId';
  static const String userRole = 'auth.userRole';
  static const String userEmail = 'auth.userEmail';
}

/// Middleware that verifies Firebase ID tokens and attaches user info to context.
///
/// Extracts Bearer token from Authorization header, verifies it with
/// Firebase Admin SDK, looks up user role from Firestore, and attaches
/// userId, role, and email to the request context.
Middleware authMiddleware(Auth auth, Firestore firestore) {
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
        // Verify the Firebase ID token
        final decodedToken = await auth.verifyIdToken(token);
        final uid = decodedToken.uid;

        // Look up user role from Firestore
        final userDoc = await firestore.collection('users').doc(uid).get();
        final role = _parseRole(userDoc.exists ? (userDoc.data()?['role'] as String?) : null);
        final email = decodedToken.email ?? '';

        // Attach auth info to request context
        final updatedRequest = request.change(context: {
          AuthContext.userId: uid,
          AuthContext.userRole: role,
          AuthContext.userEmail: email,
        });

        return innerHandler(updatedRequest);
      } on FirebaseAuthAdminException {
        return Response(401,
            body: jsonEncode({'error': 'Invalid or expired token'}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
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
