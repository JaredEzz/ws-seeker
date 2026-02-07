/// Create order request DTO
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/order.dart';
import '../models/user.dart';

part 'create_order_request.freezed.dart';
part 'create_order_request.g.dart';

/// Request payload for creating a new order
@freezed
class CreateOrderRequest with _$CreateOrderRequest {
  const factory CreateOrderRequest({
    required ProductLanguage language,
    required List<OrderItemRequest> items,
    required ShippingAddress shippingAddress,
  }) = _CreateOrderRequest;

  factory CreateOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderRequestFromJson(json);
}

/// Individual item in order creation request
@freezed
class OrderItemRequest with _$OrderItemRequest {
  const factory OrderItemRequest({
    required String productId,
    required int quantity,
  }) = _OrderItemRequest;

  factory OrderItemRequest.fromJson(Map<String, dynamic> json) =>
      _$OrderItemRequestFromJson(json);
}
