import 'package:ws_seeker_shared/ws_seeker_shared.dart';

abstract interface class OrderRepository {
  Future<List<Order>> getOrders({OrderFilter? filter});
  Future<Order> getOrderById(String id);
  Future<Order> createOrder(CreateOrderRequest request);
  Future<void> updateOrder(String id, UpdateOrderRequest request);
  Stream<List<OrderComment>> watchComments(String orderId);
  Future<void> addComment(String orderId, String content);
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
    // TODO: Connect to Firestore collection 'orders'
    // Query by userId and apply filters
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockOrders;
  }

  @override
  Future<Order> getOrderById(String id) async {
    // TODO: Connect to Firestore document 'orders/$id'
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockOrders.firstWhere((o) => o.id == id);
  }

  @override
  Future<Order> createOrder(CreateOrderRequest request) async {
    // TODO: Call backend Cloud Run endpoint POST /api/orders
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
    // TODO: Call backend Cloud Run endpoint PATCH /api/orders/$id
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
    // TODO: Connect to Firestore subcollection 'orders/$orderId/comments'
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
    // TODO: Call backend Cloud Run endpoint POST /api/comments
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
