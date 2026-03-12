/// Users API Handler
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import '../middleware/auth_middleware.dart';
import '../services/audit_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class UsersHandler {
  final UserService _userService;
  final AuditService? _auditService;
  final AuthService? _authService;

  UsersHandler({
    required UserService userService,
    AuditService? auditService,
    AuthService? authService,
  })  : _userService = userService,
        _auditService = auditService,
        _authService = authService;

  Router get router {
    final router = Router();

    // GET /api/users - List all users (superUser only)
    router.get('/', _listUsers);

    // PATCH /api/users/<id>/account-manager - Assign account manager
    router.patch('/<id>/account-manager', _assignAccountManager);

    // POST /api/users/<id>/impersonate - Login as another user (superUser only)
    router.post('/<id>/impersonate', _impersonateUser);

    // GET /api/users/me - Get current user profile
    router.get('/me', _getProfile);

    // PATCH /api/users/me - Update current user profile
    router.patch('/me', _updateProfile);

    return router;
  }

  /// GET /api/users/me
  Future<Response> _getProfile(Request request) async {
    final userId = request.context[AuthContext.userId] as String?;
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final user = await _userService.getUser(userId);
      if (user == null) {
        return Response(404,
            body: jsonEncode({'error': 'User not found'}),
            headers: {'Content-Type': 'application/json'});
      }

      return Response.ok(
          jsonEncode({'user': user}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch profile: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// PATCH /api/users/me
  /// Body: { discordName?, phone?, preferredPaymentMethod?, wiseEmail?, savedAddress? }
  Future<Response> _updateProfile(Request request) async {
    final userId = request.context[AuthContext.userId] as String?;
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      await _userService.updateProfile(userId, data);

      // Audit log
      _auditService?.log(
        userId: userId,
        userEmail: request.context[AuthContext.userEmail] as String? ?? '',
        action: 'user.profileUpdated',
        resourceType: 'user',
        resourceId: userId,
        details: {'fieldsUpdated': data.keys.toList()},
      );

      // Return updated profile
      final user = await _userService.getUser(userId);

      return Response.ok(
          jsonEncode({'user': user}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to update profile: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// GET /api/users - List all users (superUser only)
  Future<Response> _listUsers(Request request) async {
    final role = request.context[AuthContext.userRole] as UserRole?;
    if (role != UserRole.superUser) {
      return Response(403,
          body: jsonEncode({'error': 'Only super users can list users'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final users = await _userService.listUsers();
      return Response.ok(
          jsonEncode({'users': users}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to list users: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// POST /api/users/<id>/impersonate
  /// SuperUser only — generates a Firebase custom token for the target user.
  Future<Response> _impersonateUser(Request request, String id) async {
    final role = request.context[AuthContext.userRole] as UserRole?;
    if (role != UserRole.superUser) {
      return Response(403,
          body: jsonEncode({'error': 'Only super users can impersonate'}),
          headers: {'Content-Type': 'application/json'});
    }

    if (_authService == null) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Auth service not configured'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final targetUser = await _userService.getUser(id);
      if (targetUser == null) {
        return Response(404,
            body: jsonEncode({'error': 'User not found'}),
            headers: {'Content-Type': 'application/json'});
      }

      final customToken = _authService.createCustomToken(id);

      // Audit log
      final userId = request.context[AuthContext.userId] as String?;
      _auditService?.log(
        userId: userId ?? '',
        userEmail: request.context[AuthContext.userEmail] as String? ?? '',
        action: 'user.impersonated',
        resourceType: 'user',
        resourceId: id,
        details: {'targetEmail': targetUser['email']},
      );

      // Return token + user profile data
      final result = <String, dynamic>{
        'token': customToken,
        ...targetUser,
      };

      return Response.ok(
          jsonEncode(result),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to impersonate: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// PATCH /api/users/<id>/account-manager
  /// Body: { accountManagerId: string | null }
  Future<Response> _assignAccountManager(Request request, String id) async {
    final role = request.context[AuthContext.userRole] as UserRole?;
    if (role != UserRole.superUser) {
      return Response(403,
          body: jsonEncode({'error': 'Only super users can assign account managers'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final accountManagerId = data['accountManagerId'] as String?;

      await _userService.assignAccountManager(id, accountManagerId);

      // Audit log
      final userId = request.context[AuthContext.userId] as String?;
      _auditService?.log(
        userId: userId ?? '',
        userEmail: request.context[AuthContext.userEmail] as String? ?? '',
        action: 'user.accountManagerAssigned',
        resourceType: 'user',
        resourceId: id,
        details: {'accountManagerId': accountManagerId},
      );

      return Response.ok(
          jsonEncode({'message': 'Account manager updated'}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to assign account manager: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }
}
