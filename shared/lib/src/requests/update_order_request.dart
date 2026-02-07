/// Update order request DTO
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/order.dart';

part 'update_order_request.freezed.dart';
part 'update_order_request.g.dart';

/// Request payload for updating an order
@freezed
class UpdateOrderRequest with _$UpdateOrderRequest {
  const factory UpdateOrderRequest({
    OrderStatus? status,
    String? trackingNumber,
    String? trackingCarrier,
    String? proofOfPaymentUrl,
    String? invoiceId,
  }) = _UpdateOrderRequest;

  factory UpdateOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateOrderRequestFromJson(json);
}
