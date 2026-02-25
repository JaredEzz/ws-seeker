/// Audit log model for tracking user interactions
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

/// Represents an audit log entry
@freezed
class AuditLog with _$AuditLog {
  const factory AuditLog({
    required String id,
    required String userId,
    required String userEmail,
    required String action, // e.g. 'order.created', 'product.updated'
    required String resourceType, // e.g. 'order', 'product', 'invoice'
    required String resourceId,
    Map<String, dynamic>? details,
    required DateTime createdAt,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _$AuditLogFromJson(json);
}
