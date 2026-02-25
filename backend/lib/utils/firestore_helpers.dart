/// Utilities for sanitizing Firestore documents before JSON encoding.
library;

import 'package:dart_firebase_admin/firestore.dart';

/// Recursively convert Firestore Timestamp values to ISO 8601 strings
/// so the map is safe to pass to jsonEncode.
Map<String, dynamic> sanitizeDoc(Map<String, dynamic> doc) {
  return doc.map((key, value) => MapEntry(key, _sanitize(value)));
}

dynamic _sanitize(dynamic value) {
  if (value is Timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(
      value.seconds * 1000 + value.nanoseconds ~/ 1000000,
      isUtc: true,
    );
    return dt.toIso8601String();
  }
  if (value is Map<String, dynamic>) {
    return sanitizeDoc(value);
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
  }
  if (value is List) {
    return value.map(_sanitize).toList();
  }
  return value;
}
