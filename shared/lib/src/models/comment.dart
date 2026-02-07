/// Comment model for order communications
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

/// Represents a comment on an order
@freezed
class OrderComment with _$OrderComment {
  const factory OrderComment({
    required String id,
    required String orderId,
    required String userId,
    required String userName,
    required String content,
    @Default(false) bool isInternal,
    required DateTime createdAt,
  }) = _OrderComment;

  factory OrderComment.fromJson(Map<String, dynamic> json) =>
      _$OrderCommentFromJson(json);
}
