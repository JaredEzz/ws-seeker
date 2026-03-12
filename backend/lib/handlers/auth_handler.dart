import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/audit_service.dart';
import '../services/auth_service.dart';

class AuthHandler {
  final AuthService _authService;
  final AuditService? _auditService;

  AuthHandler(this._authService, {AuditService? auditService})
      : _auditService = auditService;

  Router get router {
    final router = Router();

    // Request a magic link
    router.post('/magic-link', (Request request) async {
      try {
        final payload = jsonDecode(await request.readAsString());
        final email = payload['email'] as String?;

        if (email == null || email.isEmpty) {
          return Response.badRequest(body: jsonEncode({'error': 'Email is required'}));
        }

        await _authService.sendMagicLink(email);

        return Response.ok(
          jsonEncode({'message': 'Magic link sent'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // Verify magic link and get custom token
    router.post('/verify-magic-link', (Request request) async {
      try {
        final payload = jsonDecode(await request.readAsString());
        final token = payload['token'] as String?;
        final email = payload['email'] as String?;

        if (token == null || email == null) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Token and email are required'}),
          );
        }

        final result = await _authService.verifyMagicLink(token, email);

        // Audit log
        _auditService?.log(
          userId: result['uid'] as String? ?? '',
          userEmail: email,
          action: 'auth.login',
          resourceType: 'user',
          resourceId: result['uid'] as String? ?? '',
        );

        return Response.ok(
          jsonEncode(result),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e, st) {
        print('verify-magic-link error: $e');
        print('Stack trace: $st');
        return Response.forbidden(
          jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    return router;
  }
}
