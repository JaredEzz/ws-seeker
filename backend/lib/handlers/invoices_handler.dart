/// Invoices API Handler
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import '../middleware/auth_middleware.dart';
import '../services/invoice_service.dart';

class InvoicesHandler {
  final InvoiceService _invoiceService;

  InvoicesHandler({required InvoiceService invoiceService})
      : _invoiceService = invoiceService;

  Router get router {
    final router = Router();

    // POST /api/invoices/generate/<orderId> - Generate invoice from order
    router.post('/generate/<orderId>', _generateInvoice);

    // GET /api/invoices/<id> - Get invoice by ID
    router.get('/<id>', _getInvoice);

    // GET /api/invoices - List invoices
    router.get('/', _listInvoices);

    // PATCH /api/invoices/<id>/status - Update invoice status
    router.patch('/<id>/status', _updateStatus);

    return router;
  }

  /// POST /api/invoices/generate/<orderId>
  Future<Response> _generateInvoice(Request request, String orderId) async {
    final role = request.context[AuthContext.userRole] as UserRole?;

    // Only super_user and supplier can generate invoices
    if (role != UserRole.superUser && role != UserRole.supplier) {
      return Response(403,
          body: jsonEncode({'error': 'Only admins can generate invoices'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final invoice = await _invoiceService.generateInvoice(orderId);

      return Response(201,
          body: jsonEncode({'invoice': invoice}),
          headers: {'Content-Type': 'application/json'});
    } on StateError catch (e) {
      return Response(409,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } on ArgumentError catch (e) {
      return Response(400,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to generate invoice: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// GET /api/invoices/<id>
  Future<Response> _getInvoice(Request request, String id) async {
    final userId = request.context[AuthContext.userId] as String?;
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final invoice = await _invoiceService.getInvoiceById(id);
      if (invoice == null) {
        return Response(404,
            body: jsonEncode({'error': 'Invoice not found'}),
            headers: {'Content-Type': 'application/json'});
      }

      return Response.ok(
          jsonEncode({'invoice': invoice}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch invoice: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// GET /api/invoices?status=draft
  Future<Response> _listInvoices(Request request) async {
    final role = request.context[AuthContext.userRole] as UserRole?;

    // Only super_user and supplier can list all invoices
    if (role != UserRole.superUser && role != UserRole.supplier) {
      return Response(403,
          body: jsonEncode({'error': 'Access denied'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final status = request.url.queryParameters['status'];
      final invoices = await _invoiceService.listInvoices(status: status);

      return Response.ok(
          jsonEncode({'invoices': invoices}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch invoices: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// PATCH /api/invoices/<id>/status
  /// Body: { status: 'sent' | 'paid' | 'void' }
  Future<Response> _updateStatus(Request request, String id) async {
    final role = request.context[AuthContext.userRole] as UserRole?;

    if (role != UserRole.superUser && role != UserRole.supplier) {
      return Response(403,
          body: jsonEncode({'error': 'Only admins can update invoice status'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status == null) {
        return Response(400,
            body: jsonEncode({'error': 'status is required'}),
            headers: {'Content-Type': 'application/json'});
      }

      await _invoiceService.updateInvoiceStatus(id, status);

      return Response.ok(
          jsonEncode({'message': 'Invoice status updated'}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to update invoice: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }
}
