import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

abstract interface class OrderRepository {
  Future<List<Order>> getOrders({OrderFilter? filter});
  Future<Order> getOrderById(String id);
  Future<Order> createOrder(CreateOrderRequest request);
  Future<void> updateOrder(String id, UpdateOrderRequest request);
  Stream<List<OrderComment>> watchComments(String orderId);
  Future<void> addComment(String orderId, String content);
}

/// HTTP-based order repository that calls the backend API
class HttpOrderRepository implements OrderRepository {
  final String _baseUrl;

  HttpOrderRepository({String? baseUrl})
      : _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  /// Get the current user's Firebase ID token for Authorization header
  Future<Map<String, String>> get _authHeaders async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<Order>> getOrders({OrderFilter? filter}) async {
    final queryParams = <String, String>{};
    if (filter?.status != null) {
      queryParams['status'] = filter!.status!.name;
    }
    if (filter?.language != null) {
      queryParams['language'] = filter!.language!.name;
    }

    final uri = Uri.parse('$_baseUrl${ApiRoutes.orders}')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(uri, headers: await _authHeaders);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch orders: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final ordersJson = data['orders'] as List<dynamic>;

    return ordersJson
        .map((json) => _orderFromMap(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Order> getOrderById(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl${ApiRoutes.orders}/$id'),
      headers: await _authHeaders,
    );

    if (response.statusCode == 404) {
      throw Exception('Order not found');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch order: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _orderFromMap(data['order'] as Map<String, dynamic>);
  }

  @override
  Future<Order> createOrder(CreateOrderRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl${ApiRoutes.orders}'),
      headers: await _authHeaders,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create order: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _orderFromMap(data['order'] as Map<String, dynamic>);
  }

  @override
  Future<void> updateOrder(String id, UpdateOrderRequest request) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl${ApiRoutes.orders}/$id'),
      headers: await _authHeaders,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update order: ${response.body}');
    }
  }

  @override
  Stream<List<OrderComment>> watchComments(String orderId) {
    // Poll-based implementation since we're using HTTP, not Firestore streams
    return Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => _fetchComments(orderId))
        .distinct();
  }

  @override
  Future<void> addComment(String orderId, String content) async {
    final response = await http.post(
      Uri.parse('$_baseUrl${ApiRoutes.orders}/$orderId/comments'),
      headers: await _authHeaders,
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add comment: ${response.body}');
    }
  }

  Future<List<OrderComment>> _fetchComments(String orderId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl${ApiRoutes.orders}/$orderId/comments'),
      headers: await _authHeaders,
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final commentsJson = data['comments'] as List<dynamic>;

    return commentsJson
        .map((json) => _commentFromMap(json as Map<String, dynamic>))
        .toList();
  }

  /// Parse order from backend response map
  Order _orderFromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      userId: map['userId'] as String,
      language: ProductLanguage.values.firstWhere(
        (l) => l.name == map['language'],
      ),
      items: (map['items'] as List<dynamic>)
          .map((item) => OrderItem(
                productId: item['productId'] as String,
                productName: item['productName'] as String,
                quantity: item['quantity'] as int,
                unitPrice: (item['unitPrice'] as num).toDouble(),
                totalPrice: (item['totalPrice'] as num).toDouble(),
              ))
          .toList(),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == map['status'],
      ),
      shippingAddress: ShippingAddress(
        fullName: map['shippingAddress']['fullName'] as String,
        addressLine1: map['shippingAddress']['addressLine1'] as String,
        addressLine2: map['shippingAddress']['addressLine2'] as String?,
        city: map['shippingAddress']['city'] as String,
        state: map['shippingAddress']['state'] as String,
        postalCode: map['shippingAddress']['postalCode'] as String,
        country: map['shippingAddress']['country'] as String,
        phone: map['shippingAddress']['phone'] as String?,
      ),
      subtotal: (map['subtotal'] as num).toDouble(),
      markup: (map['markup'] as num).toDouble(),
      estimatedTariff: (map['estimatedTariff'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      invoiceId: map['invoiceId'] as String?,
      invoiceUrl: map['invoiceUrl'] as String?,
      trackingNumber: map['trackingNumber'] as String?,
      trackingCarrier: map['trackingCarrier'] as String?,
      proofOfPaymentUrl: map['proofOfPaymentUrl'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  OrderComment _commentFromMap(Map<String, dynamic> map) {
    return OrderComment(
      id: map['id'] as String,
      orderId: map['orderId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      content: map['content'] as String,
      isInternal: map['isInternal'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is String) return DateTime.parse(value);
    if (value is Map) {
      // Firestore Timestamp format
      final seconds = value['_seconds'] as int? ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return DateTime.now();
  }
}

class MockOrderRepository implements OrderRepository {
  final List<Order> _mockOrders = [
    Order(
      id: 'ORD-001',
      userId: 'user-1',
      language: ProductLanguage.japanese,
      items: [
        const OrderItem(
          productId: 'p1',
          productName: 'VMAX Rising Booster Box',
          quantity: 10,
          unitPrice: 50.0,
          totalPrice: 500.0,
        ),
      ],
      status: OrderStatus.submitted,
      shippingAddress: const ShippingAddress(
        fullName: 'John Doe',
        addressLine1: '123 Poke Lane',
        city: 'Pallet Town',
        state: 'Kanto',
        postalCode: '12345',
        country: 'Japan',
      ),
      subtotal: 500.0,
      markup: 0.0,
      estimatedTariff: 35.0,
      totalAmount: 535.0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Order(
      id: 'ORD-002',
      userId: 'user-2',
      language: ProductLanguage.chinese,
      items: [
        const OrderItem(
          productId: 'p2',
          productName: 'Shiny Star V Box',
          quantity: 5,
          unitPrice: 60.0,
          totalPrice: 300.0,
        ),
      ],
      status: OrderStatus.invoiced,
      shippingAddress: const ShippingAddress(
        fullName: 'Jane Smith',
        addressLine1: '456 Card St',
        city: 'Shanghai',
        state: 'SH',
        postalCode: '200000',
        country: 'China',
      ),
      subtotal: 300.0,
      markup: 39.0, // 13% of 300
      estimatedTariff: 0.0,
      totalAmount: 339.0,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<Order>> getOrders({OrderFilter? filter}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockOrders;
  }

  @override
  Future<Order> getOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockOrders.firstWhere((o) => o.id == id);
  }

  @override
  Future<Order> createOrder(CreateOrderRequest request) async {
    await Future.delayed(const Duration(seconds: 1));
    final newOrder = Order(
      id: 'ORD-${_mockOrders.length + 1}',
      userId: 'mock-user-id',
      language: request.language,
      items: request.items.map((i) => OrderItem(
        productId: i.productId,
        productName: 'Mock Product ${i.productId}',
        quantity: i.quantity,
        unitPrice: 10.0,
        totalPrice: i.quantity * 10.0,
      )).toList(),
      status: OrderStatus.submitted,
      shippingAddress: request.shippingAddress,
      subtotal: 100.0,
      markup: request.language == ProductLanguage.japanese ? 0 : 13.0,
      estimatedTariff: 0,
      totalAmount: 113.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _mockOrders.add(newOrder);
    return newOrder;
  }

  @override
  Future<void> updateOrder(String id, UpdateOrderRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockOrders.indexWhere((o) => o.id == id);
    if (index != -1) {
      final old = _mockOrders[index];
      _mockOrders[index] = old.copyWith(
        status: request.status ?? old.status,
        trackingNumber: request.trackingNumber ?? old.trackingNumber,
        trackingCarrier: request.trackingCarrier ?? old.trackingCarrier,
        proofOfPaymentUrl: request.proofOfPaymentUrl ?? old.proofOfPaymentUrl,
        invoiceId: request.invoiceId ?? old.invoiceId,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Stream<List<OrderComment>> watchComments(String orderId) {
    return Stream.value([
      OrderComment(
        id: 'c1',
        orderId: orderId,
        userId: 'system',
        userName: 'System',
        content: 'Order created',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }

  @override
  Future<void> addComment(String orderId, String content) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
