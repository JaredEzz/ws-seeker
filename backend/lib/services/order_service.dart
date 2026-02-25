/// Order Service for Firestore operations
library;

import 'package:dart_firebase_admin/firestore.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

class OrderService {
  final Firestore _firestore;
  final PriceCalculator _priceCalculator;

  OrderService(this._firestore, {PriceCalculator? priceCalculator})
      : _priceCalculator = priceCalculator ?? const DefaultPriceCalculator();

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _countersRef =>
      _firestore.collection('counters');

  /// Language prefix for display order numbers
  static String _languagePrefix(ProductLanguage language) => switch (language) {
        ProductLanguage.japanese => 'JPN',
        ProductLanguage.chinese => 'CN',
        ProductLanguage.korean => 'KR',
      };

  /// Atomically increment and return the next order number for a language.
  ///
  /// Uses a per-language counter document in `counters/orders_{language}`.
  /// `set` with `FieldValue.increment` is atomic — creates the doc with
  /// count=1 if missing, or increments if it exists.
  Future<int> _nextOrderNumber(ProductLanguage language) async {
    final docRef = _countersRef.doc('orders_${language.name}');
    await docRef.set({'count': const FieldValue.increment(1)});
    final doc = await docRef.get();
    return (doc.data()!['count'] as num).toInt();
  }

  /// Create a new order from a CreateOrderRequest
  ///
  /// Looks up product prices, calculates pricing with markup/tariff,
  /// and writes the order to Firestore.
  Future<Map<String, dynamic>> createOrder(
    String userId,
    CreateOrderRequest request,
  ) async {
    // Validate items not empty
    if (request.items.isEmpty) {
      throw ArgumentError('Order must contain at least one item');
    }
    if (request.items.length > AppConstants.maxOrderItems) {
      throw ArgumentError('Order cannot exceed ${AppConstants.maxOrderItems} items');
    }

    // Look up product details and build order items
    final orderItems = <OrderItem>[];
    for (final itemRequest in request.items) {
      if (itemRequest.quantity <= 0 ||
          itemRequest.quantity > AppConstants.maxItemQuantity) {
        throw ArgumentError(
            'Quantity must be between 1 and ${AppConstants.maxItemQuantity}');
      }

      final productDoc = await _productsRef.doc(itemRequest.productId).get();
      if (!productDoc.exists) {
        throw ArgumentError('Product not found: ${itemRequest.productId}');
      }

      final productData = productDoc.data()!;
      if (productData['isActive'] != true) {
        throw ArgumentError('Product is not available: ${itemRequest.productId}');
      }

      // Resolve unit price: for JPN products with a type, use the type-specific price
      final unitPrice = _resolveUnitPrice(
        productData,
        request.language,
        itemRequest.productType,
      );
      final totalPrice = unitPrice * itemRequest.quantity;

      orderItems.add(OrderItem(
        productId: itemRequest.productId,
        productName: productData['name'] as String,
        quantity: itemRequest.quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        productType: itemRequest.productType,
      ));
    }

    // Calculate pricing
    final pricing = _priceCalculator.calculateFinalPrice(
      items: orderItems,
      language: request.language,
    );

    // Build order document
    final now = DateTime.now().toUtc();
    final orderData = {
      'userId': userId,
      'language': request.language.name,
      'items': orderItems
          .map((item) => {
                'productId': item.productId,
                'productName': item.productName,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'totalPrice': item.totalPrice,
                if (item.productType != null) 'productType': item.productType,
              })
          .toList(),
      'status': OrderStatus.submitted.name,
      'shippingAddress': {
        'fullName': request.shippingAddress.fullName,
        'addressLine1': request.shippingAddress.addressLine1,
        'addressLine2': request.shippingAddress.addressLine2,
        'city': request.shippingAddress.city,
        'state': request.shippingAddress.state,
        'postalCode': request.shippingAddress.postalCode,
        'country': request.shippingAddress.country,
        'phone': request.shippingAddress.phone,
      },
      'subtotal': pricing.subtotal,
      'markup': pricing.markup,
      'estimatedTariff': pricing.estimatedTariff,
      'totalAmount': pricing.total,
      if (request.shippingMethod != null)
        'shippingMethod': request.shippingMethod,
      if (request.paymentMethod != null)
        'paymentMethod': request.paymentMethod,
      if (request.discordName != null)
        'discordName': request.discordName,
      'createdAt': FieldValue.serverTimestamp,
      'updatedAt': FieldValue.serverTimestamp,
    };

    // Generate auto-increment display order number (e.g., CN35, JPN42)
    final orderNum = await _nextOrderNumber(request.language);
    final displayOrderNumber =
        '${_languagePrefix(request.language)}$orderNum';
    orderData['displayOrderNumber'] = displayOrderNumber;

    final docRef = await _ordersRef.add(orderData);

    return {
      'id': docRef.id,
      ...orderData,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
  }

  /// Get orders filtered by user role
  ///
  /// - Wholesaler: sees only own orders
  /// - Supplier: sees only Japanese orders
  /// - Super User: sees all orders
  Future<List<Map<String, dynamic>>> getOrders({
    required String userId,
    required UserRole role,
    OrderFilter? filter,
  }) async {
    Query<Map<String, dynamic>> query = _ordersRef;

    // Role-based filtering
    switch (role) {
      case UserRole.wholesaler:
        query = query.where('userId', WhereFilter.equal, userId);
      case UserRole.supplier:
        query = query.where('language', WhereFilter.equal, 'japanese');
      case UserRole.superUser:
        break; // No filter — sees all
    }

    // Apply optional filters
    if (filter?.status != null) {
      query = query.where('status', WhereFilter.equal, filter!.status!.name);
    }
    if (filter?.language != null) {
      query = query.where('language', WhereFilter.equal, filter!.language!.name);
    }

    query = query.orderBy('createdAt', descending: true);

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get a single order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  /// Update an order (status, tracking, proof of payment)
  ///
  /// Validates status transitions: status can only move forward in the
  /// progression, never backward.
  Future<void> updateOrder(
    String orderId,
    UpdateOrderRequest request,
  ) async {
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists) {
      throw ArgumentError('Order not found: $orderId');
    }

    final currentData = doc.data()!;
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp,
    };

    // Validate and apply status transition
    if (request.status != null) {
      final currentStatus = _parseOrderStatus(currentData['status'] as String);
      _validateStatusTransition(currentStatus, request.status!);
      updates['status'] = request.status!.name;
    }

    if (request.trackingNumber != null) {
      updates['trackingNumber'] = request.trackingNumber;
    }
    if (request.trackingCarrier != null) {
      updates['trackingCarrier'] = request.trackingCarrier;
    }
    if (request.proofOfPaymentUrl != null) {
      updates['proofOfPaymentUrl'] = request.proofOfPaymentUrl;
    }
    if (request.invoiceId != null) {
      updates['invoiceId'] = request.invoiceId;
    }
    if (request.adminNotes != null) {
      updates['adminNotes'] = request.adminNotes;
    }
    if (request.displayOrderNumber != null) {
      updates['displayOrderNumber'] = request.displayOrderNumber;
    }
    if (request.airShippingCost != null) {
      updates['airShippingCost'] = request.airShippingCost;
    }
    if (request.oceanShippingCost != null) {
      updates['oceanShippingCost'] = request.oceanShippingCost;
    }

    await _ordersRef.doc(orderId).update(updates);
  }

  /// Validate that a status transition is allowed
  ///
  /// Forward-only progression through the status pipeline, except:
  /// - `cancelled` is allowed from any non-terminal state
  /// - Cannot transition out of `delivered` or `cancelled`
  void _validateStatusTransition(OrderStatus current, OrderStatus next) {
    // Can't transition from terminal states
    if (current == OrderStatus.delivered || current == OrderStatus.cancelled) {
      throw StateError(
          'Invalid status transition: cannot change from terminal status ${current.name}');
    }

    // Cancellation is always allowed from non-terminal states
    if (next == OrderStatus.cancelled) return;

    // Forward-only progression (excluding cancelled which is last in the enum)
    const statusOrder = [
      OrderStatus.submitted,
      OrderStatus.awaitingQuote,
      OrderStatus.invoiced,
      OrderStatus.paymentPending,
      OrderStatus.paymentReceived,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];
    final currentIndex = statusOrder.indexOf(current);
    final nextIndex = statusOrder.indexOf(next);

    if (nextIndex <= currentIndex) {
      throw StateError(
          'Invalid status transition: cannot go from ${current.name} to ${next.name}');
    }
  }

  /// Resolve the unit price for a product, considering JPN product types.
  ///
  /// For Japanese products with a type selector, uses the USD price with tariff
  /// for the given type. Falls back to basePrice.
  double _resolveUnitPrice(
    Map<String, dynamic> productData,
    ProductLanguage language,
    String? productType,
  ) {
    if (language == ProductLanguage.japanese && productType != null) {
      final priceField = switch (productType) {
        'box' => 'boxPriceUsdWithTariff',
        'no_shrink' => 'noShrinkPriceUsdWithTariff',
        'case' => 'casePriceUsdWithTariff',
        _ => null,
      };
      if (priceField != null && productData[priceField] != null) {
        return (productData[priceField] as num).toDouble();
      }
      // Fallback to USD without tariff
      final fallbackField = switch (productType) {
        'box' => 'boxPriceUsd',
        'no_shrink' => 'noShrinkPriceUsd',
        'case' => 'casePriceUsd',
        _ => null,
      };
      if (fallbackField != null && productData[fallbackField] != null) {
        return (productData[fallbackField] as num).toDouble();
      }
    }
    return (productData['basePrice'] as num).toDouble();
  }

  OrderStatus _parseOrderStatus(String status) {
    return switch (status) {
      'submitted' => OrderStatus.submitted,
      'awaitingQuote' => OrderStatus.awaitingQuote,
      'invoiced' => OrderStatus.invoiced,
      'paymentPending' => OrderStatus.paymentPending,
      'paymentReceived' => OrderStatus.paymentReceived,
      'shipped' => OrderStatus.shipped,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      _ => throw StateError('Unknown order status: $status'),
    };
  }
}
