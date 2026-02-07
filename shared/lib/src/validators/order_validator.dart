/// Order validation utilities
library;

import '../models/order.dart';
import '../requests/create_order_request.dart';

/// Order validation result
class OrderValidationResult {
  const OrderValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  final bool isValid;
  final List<String> errors;

  factory OrderValidationResult.valid() =>
      const OrderValidationResult(isValid: true);

  factory OrderValidationResult.invalid(List<String> errors) =>
      OrderValidationResult(isValid: false, errors: errors);
}

/// Order validation interface
abstract interface class OrderValidator {
  /// Validate a create order request
  OrderValidationResult validateCreateRequest(CreateOrderRequest request);
  
  /// Validate order items
  OrderValidationResult validateItems(List<OrderItemRequest> items);
}

/// Default order validator
class DefaultOrderValidator implements OrderValidator {
  const DefaultOrderValidator();

  @override
  OrderValidationResult validateCreateRequest(CreateOrderRequest request) {
    final errors = <String>[];

    // Validate items
    final itemsResult = validateItems(request.items);
    if (!itemsResult.isValid) {
      errors.addAll(itemsResult.errors);
    }

    // At least one item required
    if (request.items.isEmpty) {
      errors.add('Order must contain at least one item');
    }

    if (errors.isEmpty) {
      return OrderValidationResult.valid();
    }

    return OrderValidationResult.invalid(errors);
  }

  @override
  OrderValidationResult validateItems(List<OrderItemRequest> items) {
    final errors = <String>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      
      if (item.productId.trim().isEmpty) {
        errors.add('Item ${i + 1}: Product ID is required');
      }

      if (item.quantity <= 0) {
        errors.add('Item ${i + 1}: Quantity must be greater than 0');
      }

      if (item.quantity > 10000) {
        errors.add('Item ${i + 1}: Quantity exceeds maximum (10,000)');
      }
    }

    if (errors.isEmpty) {
      return OrderValidationResult.valid();
    }

    return OrderValidationResult.invalid(errors);
  }
}
