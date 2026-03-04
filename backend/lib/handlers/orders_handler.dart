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
import '../services/audit_service.dart';
import '../services/user_service.dart';

class OrdersHandler {
  final OrderService _orderService;
  final CommentService _commentService;
  final EmailService? _emailService;
  final UserService? _userService;
  final AuditService? _auditService;

  OrdersHandler({
    required OrderService orderService,
    required CommentService commentService,
    EmailService? emailService,
    UserService? userService,
    AuditService? auditService,
  })  : _orderService = orderService,
        _commentService = commentService,
        _emailService = emailService,
        _userService = userService,
        _auditService = auditService;

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

    // DELETE /api/orders/<id> - Delete order (superUser only)
    router.delete('/<id>', _deleteOrder);

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

      // Look up user's accountManagerId to stamp on the order
      String? accountManagerId;
      if (_userService != null) {
        final userData = await _userService.getUser(userId);
        accountManagerId = userData?['accountManagerId'] as String?;
      }

      final order = await _orderService.createOrder(
        userId,
        createRequest,
        accountManagerId: accountManagerId,
      );

      // Send order confirmation email (fire-and-forget)
      _sendOrderConfirmationEmail(userId, order);

      // Audit log
      _auditService?.log(
        userId: userId,
        userEmail: request.context[AuthContext.userEmail] as String? ?? '',
        action: 'order.created',
        resourceType: 'order',
        resourceId: order['id'] as String,
        details: {
          'language': createRequest.language.name,
          'itemCount': createRequest.items.length,
          'displayOrderNumber': order['displayOrderNumber'],
        },
      );

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
      final accountManagerParam = params['accountManagerId'];

      if (statusParam != null || languageParam != null || accountManagerParam != null) {
        filter = OrderFilter(
          status: statusParam != null ? _parseStatus(statusParam) : null,
          language: languageParam != null ? _parseLanguage(languageParam) : null,
          accountManagerId: accountManagerParam,
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

      await _orderService.updateOrder(id, updateRequest,
          isAdmin: role != UserRole.wholesaler);

      // Send status change emails (fire-and-forget)
      if (updateRequest.status != null) {
        _sendStatusChangeEmail(order, updateRequest);
      }

      // Audit log
      final auditDetails = <String, dynamic>{
        if (updateRequest.status != null)
          'statusChange': '${order['status']} -> ${updateRequest.status!.name}',
        if (updateRequest.trackingNumber != null)
          'trackingNumber': updateRequest.trackingNumber,
        if (order['displayOrderNumber'] != null)
          'displayOrderNumber': order['displayOrderNumber'],
      };

      // Proof of payment: distinguish upload from removal
      if (updateRequest.proofOfPaymentUrl != null) {
        if (updateRequest.proofOfPaymentUrl!.isEmpty) {
          // Removal — store the old URL so it's accessible from the audit log
          auditDetails['proofOfPaymentRemoved'] = true;
          final oldUrl = order['proofOfPaymentUrl'] as String?;
          if (oldUrl != null) {
            auditDetails['proofOfPaymentUrl'] = oldUrl;
          }
        } else {
          // Upload — store the new URL
          auditDetails['proofOfPaymentUploaded'] = true;
          auditDetails['proofOfPaymentUrl'] = updateRequest.proofOfPaymentUrl;
        }
      }

      _auditService?.log(
        userId: userId,
        userEmail: request.context[AuthContext.userEmail] as String? ?? '',
        action: 'order.updated',
        resourceType: 'order',
        resourceId: id,
        details: auditDetails,
      );

      // Send payment proof notification (fire-and-forget)
      if (updateRequest.proofOfPaymentUrl != null &&
          updateRequest.proofOfPaymentUrl!.isNotEmpty) {
        _sendPaymentProofNotificationEmail(order);
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

  /// DELETE /api/orders/<id>
  /// Requires superUser role
  Future<Response> _deleteOrder(Request request, String id) async {
    final userId = request.context[AuthContext.userId] as String?;
    final role = request.context[AuthContext.userRole] as UserRole?;

    if (userId == null || role == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    if (role != UserRole.superUser) {
      return Response(403,
          body: jsonEncode({'error': 'Only super users can delete orders'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      await _orderService.deleteOrder(id);

      // Audit log
      _auditService?.log(
        userId: userId,
        userEmail: request.context[AuthContext.userEmail] as String? ?? '',
        action: 'order.deleted',
        resourceType: 'order',
        resourceId: id,
      );

      return Response.ok(
          jsonEncode({'message': 'Order deleted'}),
          headers: {'Content-Type': 'application/json'});
    } on ArgumentError catch (e) {
      return Response(404,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to delete order: $e'}),
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
      final content = data['content'] as String? ?? '';
      final imageUrl = data['imageUrl'] as String?;

      if (content.trim().isEmpty && (imageUrl == null || imageUrl.trim().isEmpty)) {
        return Response(400,
            body: jsonEncode({'error': 'content or imageUrl is required'}),
            headers: {'Content-Type': 'application/json'});
      }

      final comment = await _commentService.addComment(
        orderId: orderId,
        userId: userId,
        userName: userEmail ?? 'Unknown',
        content: content,
        imageUrl: imageUrl,
        isInternal: data['isInternal'] as bool? ?? false,
      );

      // Audit log
      _auditService?.log(
        userId: userId,
        userEmail: userEmail ?? '',
        action: 'comment.created',
        resourceType: 'order',
        resourceId: orderId,
        details: {'commentId': comment['id']},
      );

      // Send comment notification email (fire-and-forget)
      final commenterRole =
          request.context[AuthContext.userRole] as UserRole? ??
              UserRole.wholesaler;
      _sendCommentNotificationEmail(
        orderId: orderId,
        commenterRole: commenterRole,
        commenterName: userEmail ?? 'Unknown',
        content: content,
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

  /// Send comment notification email (fire-and-forget)
  void _sendCommentNotificationEmail({
    required String orderId,
    required UserRole commenterRole,
    required String commenterName,
    required String content,
  }) async {
    final emailSvc = _emailService;
    final userSvc = _userService;
    if (emailSvc == null || userSvc == null) return;
    try {
      final order = await _orderService.getOrderById(orderId);
      if (order == null) return;

      final displayNumber =
          order['displayOrderNumber'] as String? ?? orderId;
      final preview =
          content.length > 200 ? '${content.substring(0, 200)}...' : content;
      final isJapanese = order['language'] == 'japanese';

      List<String> recipientEmails;
      if (commenterRole == UserRole.wholesaler) {
        // Customer commented → notify admins
        recipientEmails =
            await userSvc.getAdminEmails(includeSuppliers: isJapanese);
        // Also add account manager if set
        final amId = order['accountManagerId'] as String?;
        if (amId != null) {
          final am = await userSvc.getUser(amId);
          final amEmail = am?['email'] as String?;
          if (amEmail != null) recipientEmails.add(amEmail);
        }
        recipientEmails = recipientEmails.toSet().toList();
      } else {
        // Admin/supplier commented → notify customer
        final customerId = order['userId'] as String;
        final customer = await userSvc.getUser(customerId);
        final email = customer?['email'] as String?;
        recipientEmails = email != null ? [email] : [];
      }

      for (final email in recipientEmails) {
        await emailSvc.sendCommentNotification(
          toEmail: email,
          orderId: orderId,
          displayOrderNumber: displayNumber,
          commenterName: commenterName,
          commentPreview: preview,
        );
      }
    } catch (e) {
      print('Failed to send comment notification: $e');
    }
  }

  /// Send payment proof uploaded notification (fire-and-forget)
  void _sendPaymentProofNotificationEmail(Map<String, dynamic> order) async {
    final emailSvc = _emailService;
    final userSvc = _userService;
    if (emailSvc == null || userSvc == null) return;
    try {
      final orderId = order['id'] as String;
      final displayNumber =
          order['displayOrderNumber'] as String? ?? orderId;
      final customerId = order['userId'] as String;
      final customer = await userSvc.getUser(customerId);
      final customerName = customer?['email'] as String? ?? 'Customer';
      final isJapanese = order['language'] == 'japanese';

      var recipientEmails =
          await userSvc.getAdminEmails(includeSuppliers: isJapanese);
      final amId = order['accountManagerId'] as String?;
      if (amId != null) {
        final am = await userSvc.getUser(amId);
        final amEmail = am?['email'] as String?;
        if (amEmail != null) recipientEmails.add(amEmail);
      }
      recipientEmails = recipientEmails.toSet().toList();

      for (final email in recipientEmails) {
        await emailSvc.sendPaymentProofUploaded(
          toEmail: email,
          orderId: orderId,
          displayOrderNumber: displayNumber,
          customerName: customerName,
        );
      }
    } catch (e) {
      print('Failed to send payment proof notification: $e');
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
        case OrderStatus.awaitingQuote:
          await emailSvc.sendStatusChangeNotification(
            toEmail: email,
            orderId: orderId,
            displayOrderNumber: displayNumber,
            customerName: customerName,
            heading: 'Order Under Review',
            message:
                'Your order <strong>$displayNumber</strong> is being reviewed. We\'ll send you a quote soon.',
          );
        case OrderStatus.invoiced:
          await emailSvc.sendInvoiceNotification(
            toEmail: email,
            orderId: orderId,
            displayOrderNumber: displayNumber,
            customerName: customerName,
            totalAmount: (order['totalAmount'] as num).toDouble(),
            invoiceNumber: order['invoiceId'] as String?,
          );
        case OrderStatus.paymentPending:
          await emailSvc.sendStatusChangeNotification(
            toEmail: email,
            orderId: orderId,
            displayOrderNumber: displayNumber,
            customerName: customerName,
            heading: 'Payment Pending',
            message:
                'Your invoice for order <strong>$displayNumber</strong> is ready for payment. Please submit payment at your earliest convenience.',
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
        case OrderStatus.delivered:
          await emailSvc.sendStatusChangeNotification(
            toEmail: email,
            orderId: orderId,
            displayOrderNumber: displayNumber,
            customerName: customerName,
            heading: 'Order Delivered',
            message:
                'Your order <strong>$displayNumber</strong> has been delivered. Thank you for your business!',
          );
        case OrderStatus.cancelled:
          await emailSvc.sendStatusChangeNotification(
            toEmail: email,
            orderId: orderId,
            displayOrderNumber: displayNumber,
            customerName: customerName,
            heading: 'Order Cancelled',
            message:
                'Your order <strong>$displayNumber</strong> has been cancelled. Please contact us if you have questions.',
          );
        default:
          break; // No email for other status changes (e.g., submitted)
      }
    } catch (e) {
      print('Failed to send status change email: $e');
    }
  }
}
