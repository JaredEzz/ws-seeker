/// Invoice model
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice.freezed.dart';
part 'invoice.g.dart';

/// Invoice status
enum InvoiceStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('sent')
  sent,
  @JsonValue('paid')
  paid,
  @JsonValue('void')
  voided,
}

/// Represents an invoice for an order
@freezed
class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    required String orderId,
    required List<InvoiceLineItem> lineItems,
    required double subtotal,
    required double markup,
    required double tariff,
    required double total,
    required InvoiceStatus status,
    String? pdfUrl,
    required DateTime createdAt,
    DateTime? sentAt,
    DateTime? paidAt,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);
}

/// Individual line item on an invoice
@freezed
class InvoiceLineItem with _$InvoiceLineItem {
  const factory InvoiceLineItem({
    required String description,
    required int quantity,
    required double unitPrice,
    required double totalPrice,
  }) = _InvoiceLineItem;

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceLineItemFromJson(json);
}
