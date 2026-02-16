/// Role-based authorization middleware
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import 'auth_middleware.dart';

/// Middleware that restricts access to specific user roles.
///
/// Must be applied after [authMiddleware] so that the request context
/// contains [AuthContext.userRole].
Middleware requireRole(Set<UserRole> allowedRoles) {
  return (Handler innerHandler) {
    return (Request request) async {
      final role = request.context[AuthContext.userRole] as UserRole?;

      if (role == null) {
        return Response(401,
            body: jsonEncode({'error': 'Unauthorized'}),
            headers: {'Content-Type': 'application/json'});
      }

      if (!allowedRoles.contains(role)) {
        return Response(403,
            body: jsonEncode({
              'error': 'Access denied. Required roles: ${allowedRoles.map((r) => r.name).join(', ')}',
            }),
            headers: {'Content-Type': 'application/json'});
      }

      return innerHandler(request);
    };
  };
}

/// Convenience: only super users
Middleware requireSuperUser() =>
    requireRole({UserRole.superUser});

/// Convenience: super user or supplier (admin roles)
Middleware requireAdmin() =>
    requireRole({UserRole.superUser, UserRole.supplier});
