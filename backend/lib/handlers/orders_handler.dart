/// Orders API Handler
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import '../middleware/auth_middleware.dart';
import '../services/order_service.dart';
import '../services/comment_service.dart';
import '../services/email_service.dart';
import '../services/user_service.dart';

class OrdersHandler {
  final OrderService _orderService;
  final CommentService _commentService;
  final EmailService? _emailService;
  final UserService? _userService;

  OrdersHandler({
    required OrderService orderService,
    required CommentService commentService,
    EmailService? emailService,
    UserService? userService,
  })  : _orderService = orderService,
        _commentService = commentService,
        _emailService = emailService,
        _userService = userService;

  Router get router {
    final router = Router();

    // POST /api/orders - Create a new order
    router.post('/', _createOrder);

    // GET /api/orders - List orders (filtered by role)
    router.get('/', _listOrders);

    // GET /api/orders/<id> - Get single order
    router.get('/<id>', _getOrder);

    // PATCH /api/orders/<id> - Update order
    router.patch('/<id>', _updateOrder);

    // POST /api/orders/<orderId>/comments - Add comment
    router.post('/<orderId>/comments', _addComment);

    // GET /api/orders/<orderId>/comments - List comments
    router.get('/<orderId>/comments', _getComments);

    return router;
  }

  /// POST /api/orders
  /// Body: CreateOrderRequest JSON
  Future<Response> _createOrder(Request request) async {
    final userId = request.context[AuthContext.userId] as String?;
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final createRequest = CreateOrderRequest.fromJson(data);

      final order = await _orderService.createOrder(userId, createRequest);

      // Send order confirmation email (fire-and-forget)
      _sendOrderConfirmationEmail(userId, order);

      return Response(201,
          body: jsonEncode({'order': order}),
          headers: {'Content-Type': 'application/json'});
    } on ArgumentError catch (e) {
      return Response(400,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to create order: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// GET /api/orders?status=submitted&language=japanese
  Future<Response> _listOrders(Request request) async {
    final userId = request.context[AuthContext.userId] as String?;
    final role = request.context[AuthContext.userRole] as UserRole?;

    if (userId == null || role == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      // Parse optional query filters
      final params = request.url.queryParameters;
      OrderFilter? filter;

      final statusParam = params['status'];
      final languageParam = params['language'];

      if (statusParam != null || languageParam != null) {
        filter = OrderFilter(
          status: statusParam != null ? _parseStatus(statusParam) : null,
          language: languageParam != null ? _parseLanguage(languageParam) : null,
        );
      }

      final orders = await _orderService.getOrders(
        userId: userId,
        role: role,
        filter: filter,
      );

      return Response.ok(
          jsonEncode({'orders': orders}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch orders: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// GET /api/orders/<id>
  Future<Response> _getOrder(Request request, String id) async {
    final userId = request.context[AuthContext.userId] as String?;
    final role = request.context[AuthContext.userRole] as UserRole?;

    if (userId == null || role == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final order = await _orderService.getOrderById(id);
      if (order == null) {
        return Response(404,
            body: jsonEncode({'error': 'Order not found'}),
            headers: {'Content-Type': 'application/json'});
      }

      // Authorization check: wholesalers can only see their own orders
      if (role == UserRole.wholesaler && order['userId'] != userId) {
        return Response(403,
            body: jsonEncode({'error': 'Access denied'}),
            headers: {'Content-Type': 'application/json'});
      }

      // Suppliers can only see Japanese orders
      if (role == UserRole.supplier && order['language'] != 'japanese') {
        return Response(403,
            body: jsonEncode({'error': 'Access denied'}),
            headers: {'Content-Type': 'application/json'});
      }

      return Response.ok(
          jsonEncode({'order': order}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch order: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// PATCH /api/orders/<id>
  /// Body: UpdateOrderRequest JSON
  Future<Response> _updateOrder(Request request, String id) async {
    final userId = request.context[AuthContext.userId] as String?;
    final role = request.context[AuthContext.userRole] as UserRole?;

    if (userId == null || role == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      // Verify order exists and user has access
      final order = await _orderService.getOrderById(id);
      if (order == null) {
        return Response(404,
            body: jsonEncode({'error': 'Order not found'}),
            headers: {'Content-Type': 'application/json'});
      }

      // Wholesalers can only update their own orders (e.g., proof of payment)
      if (role == UserRole.wholesaler && order['userId'] != userId) {
        return Response(403,
            body: jsonEncode({'error': 'Access denied'}),
            headers: {'Content-Type': 'application/json'});
      }

      // Suppliers can only update Japanese orders
      if (role == UserRole.supplier && order['language'] != 'japanese') {
        return Response(403,
            body: jsonEncode({'error': 'Access denied'}),
            headers: {'Content-Type': 'application/json'});
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final updateRequest = UpdateOrderRequest.fromJson(data);

      await _orderService.updateOrder(id, updateRequest);

      // Send status change emails (fire-and-forget)
      if (updateRequest.status != null) {
        _sendStatusChangeEmail(order, updateRequest);
      }

      return Response.ok(
          jsonEncode({'message': 'Order updated'}),
          headers: {'Content-Type': 'application/json'});
    } on StateError catch (e) {
      return Response(400,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } on ArgumentError catch (e) {
      return Response(400,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to update order: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  OrderStatus? _parseStatus(String status) {
    return switch (status) {
      'submitted' => OrderStatus.submitted,
      'awaitingQuote' || 'awaiting_quote' => OrderStatus.awaitingQuote,
      'invoiced' => OrderStatus.invoiced,
      'paymentPending' || 'payment_pending' => OrderStatus.paymentPending,
      'paymentReceived' || 'payment_received' => OrderStatus.paymentReceived,
      'shipped' => OrderStatus.shipped,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      _ => null,
    };
  }

  /// POST /api/orders/<orderId>/comments
  /// Body: { content: string, isInternal?: bool }
  Future<Response> _addComment(Request request, String orderId) async {
    final userId = request.context[AuthContext.userId] as String?;
    final userEmail = request.context[AuthContext.userEmail] as String?;

    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final content = data['content'] as String?;

      if (content == null || content.trim().isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'content is required'}),
            headers: {'Content-Type': 'application/json'});
      }

      final comment = await _commentService.addComment(
        orderId: orderId,
        userId: userId,
        userName: userEmail ?? 'Unknown',
        content: content,
        isInternal: data['isInternal'] as bool? ?? false,
      );

      return Response(201,
          body: jsonEncode({'comment': comment}),
          headers: {'Content-Type': 'application/json'});
    } on ArgumentError catch (e) {
      return Response(400,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to add comment: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// GET /api/orders/<orderId>/comments
  Future<Response> _getComments(Request request, String orderId) async {
    final userId = request.context[AuthContext.userId] as String?;
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final comments = await _commentService.getComments(orderId);

      return Response.ok(
          jsonEncode({'comments': comments}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch comments: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  ProductLanguage? _parseLanguage(String language) {
    final normalized = language.toLowerCase().trim();
    return switch (normalized) {
      'japanese' || 'jp' || 'jpn' || 'japan' => ProductLanguage.japanese,
      'chinese' || 'cn' || 'chn' || 'china' => ProductLanguage.chinese,
      'korean' || 'kr' || 'kor' || 'korea' => ProductLanguage.korean,
      _ => null,
    };
  }

  /// Send order confirmation email (fire-and-forget)
  void _sendOrderConfirmationEmail(
    String userId,
    Map<String, dynamic> order,
  ) async {
    final emailSvc = _emailService;
    final userSvc = _userService;
    if (emailSvc == null || userSvc == null) return;
    try {
      final user = await userSvc.getUser(userId);
      if (user == null) return;
      final email = user['email'] as String?;
      if (email == null) return;

      await emailSvc.sendOrderConfirmation(
        toEmail: email,
        orderId: order['id'] as String,
        displayOrderNumber:
            order['displayOrderNumber'] as String? ?? order['id'] as String,
        customerName: (order['shippingAddress']
                as Map<String, dynamic>?)?['fullName'] as String? ??
            'Customer',
        totalAmount: (order['totalAmount'] as num).toDouble(),
        language: order['language'] as String,
      );
    } catch (e) {
      print('Failed to send order confirmation email: $e');
    }
  }

  /// Send status change emails (fire-and-forget)
  void _sendStatusChangeEmail(
    Map<String, dynamic> order,
    UpdateOrderRequest update,
  ) async {
    final emailSvc = _emailService;
    final userSvc = _userService;
    if (emailSvc == null || userSvc == null) return;
    final newStatus = update.status;
    if (newStatus == null) return;
    try {
      final userId = order['userId'] as String;
      final user = await userSvc.getUser(userId);
      if (user == null) return;
      final email = user['email'] as String?;
      if (email == null) return;

      final orderId = order['id'] as String;
      final displayNumber =
          order['displayOrderNumber'] as String? ?? orderId;
      final customerName = (order['shippingAddress']
              as Map<String, dynamic>?)?['fullName'] as String? ??
          'Customer';

      switch (newStatus) {
        case OrderStatus.invoiced:
          await emailSvc.sendInvoiceNotification(
            toEmail: email,
            orderId: orderId,
            displayOrderNumber: displayNumber,
            customerName: customerName,
            totalAmount: (order['totalAmount'] as num).toDouble(),
            invoiceNumber: order['invoiceId'] as String?,
          );
        case OrderStatus.paymentReceived:
          await emailSvc.sendPaymentReceived(
            toEmail: email,
            displayOrderNumber: displayNumber,
            customerName: customerName,
          );
        case OrderStatus.shipped:
          await emailSvc.sendOrderShipped(
            toEmail: email,
            orderId: orderId,
            displayOrderNumber: displayNumber,
            customerName: customerName,
            trackingNumber: update.trackingNumber ?? order['trackingNumber'] as String?,
            trackingCarrier: update.trackingCarrier ?? order['trackingCarrier'] as String?,
          );
        default:
          break; // No email for other status changes
      }
    } catch (e) {
      print('Failed to send status change email: $e');
    }
  }
}
