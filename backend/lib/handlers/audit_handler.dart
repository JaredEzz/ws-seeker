/// Audit Logs API Handler
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import '../middleware/auth_middleware.dart';
import '../services/audit_service.dart';

class AuditHandler {
  final AuditService _auditService;

  AuditHandler({required AuditService auditService})
      : _auditService = auditService;

  Router get router {
    final router = Router();

    // GET /api/audit-logs - List audit logs with filters
    router.get('/', _listAuditLogs);

    return router;
  }

  /// GET /api/audit-logs?action=order.created&resourceType=order&search=...&limit=50&offset=0
  Future<Response> _listAuditLogs(Request request) async {
    final role = request.context[AuthContext.userRole] as UserRole?;

    // Only superUser can access audit logs
    if (role != UserRole.superUser) {
      return Response(403,
          body: jsonEncode({'error': 'Only super users can access audit logs'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final params = request.url.queryParameters;

      final result = await _auditService.query(
        action: params['action'],
        resourceType: params['resourceType'],
        resourceId: params['resourceId'],
        userId: params['userId'],
        search: params['search'],
        startDate: params['startDate'] != null
            ? DateTime.tryParse(params['startDate']!)
            : null,
        endDate: params['endDate'] != null
            ? DateTime.tryParse(params['endDate']!)
            : null,
        limit: int.tryParse(params['limit'] ?? '') ?? 50,
        offset: int.tryParse(params['offset'] ?? '') ?? 0,
      );

      return Response.ok(
        jsonEncode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch audit logs: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
