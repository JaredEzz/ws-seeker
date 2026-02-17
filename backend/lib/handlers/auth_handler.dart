import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';

class AuthHandler {
  final AuthService _authService;

  AuthHandler(this._authService);

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

        // TODO: Remove skipEmail support when ready for production
        final skipEmail = payload['skipEmail'] == true;
        final link = await _authService.sendMagicLink(email, skipEmail: skipEmail);

        return Response.ok(
          jsonEncode({
            'message': skipEmail ? 'Magic link generated' : 'Magic link sent',
            if (link != null) 'link': link,
          }),
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
