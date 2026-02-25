/// Audit logging service backed by PostgreSQL (Neon)
library;

import 'dart:convert';

import 'package:postgres/postgres.dart';

class AuditService {
  final Pool _pool;

  AuditService._({required Pool pool}) : _pool = pool;

  /// Create an AuditService from a connection string.
  /// Returns null if the connection string is empty (graceful degradation).
  static Future<AuditService?> create(String? databaseUrl) async {
    if (databaseUrl == null || databaseUrl.isEmpty) {
      print('AUDIT_DATABASE_URL not set — audit logging disabled');
      return null;
    }

    final endpoint = Endpoint(
      host: Uri.parse(databaseUrl).host,
      port: Uri.parse(databaseUrl).port == 0
          ? 5432
          : Uri.parse(databaseUrl).port,
      database: Uri.parse(databaseUrl).pathSegments.isNotEmpty
          ? Uri.parse(databaseUrl).pathSegments.first
          : 'ws_seeker_audit',
      username: Uri.parse(databaseUrl).userInfo.split(':').first,
      password: Uri.parse(databaseUrl).userInfo.contains(':')
          ? Uri.parse(databaseUrl).userInfo.split(':').last
          : null,
    );

    final sslMode = databaseUrl.contains('sslmode=disable')
        ? SslMode.disable
        : SslMode.require;

    final pool = Pool.withEndpoints(
      [endpoint],
      settings: PoolSettings(
        maxConnectionCount: 5,
        sslMode: sslMode,
      ),
    );

    print('Audit logging enabled (PostgreSQL)');
    return AuditService._(pool: pool);
  }

  /// Log an audit event. Fire-and-forget safe — errors are caught and printed.
  Future<void> log({
    required String userId,
    required String userEmail,
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _pool.execute(
        Sql.named(
          'INSERT INTO audit_logs (user_id, user_email, action, resource_type, resource_id, details) '
          'VALUES (@userId, @userEmail, @action, @resourceType, @resourceId, @details)',
        ),
        parameters: {
          'userId': userId,
          'userEmail': userEmail,
          'action': action,
          'resourceType': resourceType,
          'resourceId': resourceId,
          'details': details != null ? jsonEncode(details) : null,
        },
      );
    } catch (e) {
      print('Audit log error: $e');
    }
  }

  /// Query audit logs with filters and offset-based pagination.
  /// Returns { 'logs': [...], 'total': int }.
  Future<Map<String, dynamic>> query({
    String? action,
    String? resourceType,
    String? resourceId,
    String? userId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final conditions = <String>[];
    final params = <String, dynamic>{};

    if (action != null) {
      conditions.add('action = @action');
      params['action'] = action;
    }
    if (resourceType != null) {
      conditions.add('resource_type = @resourceType');
      params['resourceType'] = resourceType;
    }
    if (resourceId != null) {
      conditions.add('resource_id = @resourceId');
      params['resourceId'] = resourceId;
    }
    if (userId != null) {
      conditions.add('user_id = @userId');
      params['userId'] = userId;
    }
    if (search != null && search.isNotEmpty) {
      conditions.add('(user_email ILIKE @search OR action ILIKE @search OR resource_id ILIKE @search)');
      params['search'] = '%$search%';
    }
    if (startDate != null) {
      conditions.add('created_at >= @startDate');
      params['startDate'] = startDate;
    }
    if (endDate != null) {
      conditions.add('created_at <= @endDate');
      params['endDate'] = endDate;
    }

    final whereClause =
        conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    // Get total count
    final countResult = await _pool.execute(
      Sql.named('SELECT COUNT(*) as cnt FROM audit_logs $whereClause'),
      parameters: params,
    );
    final total = countResult.first.toColumnMap()['cnt'] as int;

    // Get paginated results
    params['limit'] = limit;
    params['offset'] = offset;

    final result = await _pool.execute(
      Sql.named(
        'SELECT id, user_id, user_email, action, resource_type, resource_id, '
        'details, created_at FROM audit_logs $whereClause '
        'ORDER BY created_at DESC LIMIT @limit OFFSET @offset',
      ),
      parameters: params,
    );

    final logs = result.map((row) {
      final map = row.toColumnMap();
      return {
        'id': map['id'].toString(),
        'userId': map['user_id'] as String,
        'userEmail': map['user_email'] as String,
        'action': map['action'] as String,
        'resourceType': map['resource_type'] as String,
        'resourceId': map['resource_id'] as String,
        'details': map['details'] != null
            ? (map['details'] is String
                ? jsonDecode(map['details'] as String)
                : map['details'])
            : null,
        'createdAt': (map['created_at'] as DateTime).toIso8601String(),
      };
    }).toList();

    return {'logs': logs, 'total': total};
  }

  /// Close the connection pool.
  Future<void> close() async {
    await _pool.close();
  }
}
