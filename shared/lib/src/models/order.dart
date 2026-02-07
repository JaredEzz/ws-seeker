/// Order model and related types
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// Product language/origin categories
enum ProductLanguage {
  @JsonValue('japanese')
  japanese,
  @JsonValue('chinese')
  chinese,
  @JsonValue('korean')
  korean,
}

/// Order status progression
enum OrderStatus {
  @JsonValue('submitted')
  submitted,
  @JsonValue('invoiced')
  invoiced,
  @JsonValue('payment_pending')
  paymentPending,
  @JsonValue('payment_received')
  paymentReceived,
  @JsonValue('shipped')
  shipped,
  @JsonValue('delivered')
  delivered,
}

/// Represents a wholesale order
@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String userId,
    required ProductLanguage language,
    required List<OrderItem> items,
    required OrderStatus status,
    required ShippingAddress shippingAddress,
    required double subtotal,
    required double markup,
    required double estimatedTariff,
    required double totalAmount,
    String? invoiceId,
    String? invoiceUrl,
    String? trackingNumber,
    String? trackingCarrier,
    String? proofOfPaymentUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

/// Individual item within an order
@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String productId,
    required String productName,
    required int quantity,
    required double unitPrice,
    required double totalPrice,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}

/// Filter options for order queries
@freezed
class OrderFilter with _$OrderFilter {
  const factory OrderFilter({
    DateTime? startDate,
    DateTime? endDate,
    OrderStatus? status,
    ProductLanguage? language,
    @Default(12) int monthsToShow,
  }) = _OrderFilter;

  factory OrderFilter.fromJson(Map<String, dynamic> json) =>
      _$OrderFilterFromJson(json);
}
