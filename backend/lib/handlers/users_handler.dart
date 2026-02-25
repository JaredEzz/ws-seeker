/// Users API Handler
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../middleware/auth_middleware.dart';
import '../services/user_service.dart';

class UsersHandler {
  final UserService _userService;

  UsersHandler({required UserService userService})
      : _userService = userService;

  Router get router {
    final router = Router();

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
}
