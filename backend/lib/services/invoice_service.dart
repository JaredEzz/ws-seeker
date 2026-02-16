/// Invoice Service for Firestore operations
library;

import 'package:dart_firebase_admin/firestore.dart';

class InvoiceService {
  final Firestore _firestore;

  InvoiceService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _invoicesRef =>
      _firestore.collection('invoices');

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  /// Generate an invoice from an order
  ///
  /// Creates line items from order items, copies pricing breakdown,
  /// writes to invoices/ collection, and links back to the order.
  Future<Map<String, dynamic>> generateInvoice(String orderId) async {
    // Fetch the order
    final orderDoc = await _ordersRef.doc(orderId).get();
    if (!orderDoc.exists) {
      throw ArgumentError('Order not found: $orderId');
    }

    final orderData = orderDoc.data()!;

    // Check if invoice already exists for this order
    final existingInvoice = await _invoicesRef
        .where('orderId', WhereFilter.equal, orderId)
        .get();
    if (existingInvoice.docs.isNotEmpty) {
      throw StateError('Invoice already exists for order $orderId');
    }

    // Build line items from order items
    final orderItems = orderData['items'] as List<dynamic>;
    final lineItems = orderItems.map((item) {
      final i = item as Map<String, dynamic>;
      return {
        'description': i['productName'] as String,
        'quantity': i['quantity'] as int,
        'unitPrice': (i['unitPrice'] as num).toDouble(),
        'totalPrice': (i['totalPrice'] as num).toDouble(),
      };
    }).toList();

    final now = DateTime.now().toUtc();
    final invoiceData = {
      'orderId': orderId,
      'lineItems': lineItems,
      'subtotal': (orderData['subtotal'] as num).toDouble(),
      'markup': (orderData['markup'] as num).toDouble(),
      'tariff': (orderData['estimatedTariff'] as num).toDouble(),
      'total': (orderData['totalAmount'] as num).toDouble(),
      'status': 'draft',
      'createdAt': FieldValue.serverTimestamp,
    };

    // Create invoice document
    final docRef = await _invoicesRef.add(invoiceData);

    // Link invoice back to order and update order status
    await _ordersRef.doc(orderId).update({
      'invoiceId': docRef.id,
      'status': 'invoiced',
      'updatedAt': FieldValue.serverTimestamp,
    });

    return {
      'id': docRef.id,
      ...invoiceData,
      'createdAt': now.toIso8601String(),
    };
  }

  /// Get a single invoice by ID
  Future<Map<String, dynamic>?> getInvoiceById(String invoiceId) async {
    final doc = await _invoicesRef.doc(invoiceId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  /// List invoices with optional status filter
  Future<List<Map<String, dynamic>>> listInvoices({String? status}) async {
    Query<Map<String, dynamic>> query = _invoicesRef;

    if (status != null) {
      query = query.where('status', WhereFilter.equal, status);
    }

    query = query.orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Update invoice status
  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    final updates = <String, dynamic>{
      'status': status,
    };

    if (status == 'sent') {
      updates['sentAt'] = FieldValue.serverTimestamp;
    } else if (status == 'paid') {
      updates['paidAt'] = FieldValue.serverTimestamp;
    }

    await _invoicesRef.doc(invoiceId).update(updates);
  }
}
