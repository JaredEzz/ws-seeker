import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

/// Query parameters for fetching audit logs
class AuditLogQuery {
  final String? action;
  final String? resourceType;
  final String? resourceId;
  final String? search;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const AuditLogQuery({
    this.action,
    this.resourceType,
    this.resourceId,
    this.search,
    this.startDate,
    this.endDate,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Result of an audit log query
class AuditLogPage {
  final List<AuditLog> logs;
  final int total;

  const AuditLogPage({required this.logs, required this.total});
}

abstract interface class AuditLogRepository {
  Future<AuditLogPage> getAuditLogs(AuditLogQuery query);
}

class HttpAuditLogRepository implements AuditLogRepository {
  final String _baseUrl;

  HttpAuditLogRepository({String? baseUrl})
      : _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<Map<String, String>> get _authHeaders async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<AuditLogPage> getAuditLogs(AuditLogQuery query) async {
    final queryParams = <String, String>{};
    if (query.action != null) queryParams['action'] = query.action!;
    if (query.resourceType != null) {
      queryParams['resourceType'] = query.resourceType!;
    }
    if (query.resourceId != null) {
      queryParams['resourceId'] = query.resourceId!;
    }
    if (query.search != null && query.search!.isNotEmpty) {
      queryParams['search'] = query.search!;
    }
    if (query.startDate != null) {
      queryParams['startDate'] = query.startDate!.toIso8601String();
    }
    if (query.endDate != null) {
      queryParams['endDate'] = query.endDate!.toIso8601String();
    }
    queryParams['limit'] = query.limit.toString();
    queryParams['offset'] = query.offset.toString();

    final uri = Uri.parse('$_baseUrl${ApiRoutes.auditLogs}')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _authHeaders);

    if (response.statusCode == 403) {
      throw Exception('Access denied: only super users can view audit logs');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch audit logs: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final logsJson = data['logs'] as List<dynamic>;
    final total = data['total'] as int;

    final logs = logsJson.map((json) {
      final map = json as Map<String, dynamic>;
      return AuditLog(
        id: map['id'] as String,
        userId: map['userId'] as String,
        userEmail: map['userEmail'] as String,
        action: map['action'] as String,
        resourceType: map['resourceType'] as String,
        resourceId: map['resourceId'] as String,
        details: map['details'] != null
            ? Map<String, dynamic>.from(map['details'] as Map)
            : null,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
    }).toList();

    return AuditLogPage(logs: logs, total: total);
  }
}
