import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

abstract interface class InvoiceRepository {
  Future<List<Invoice>> getInvoices({String? status});
  Future<Invoice> getInvoiceById(String id);
  Future<Invoice> generateInvoice(String orderId);
  Future<void> updateInvoiceStatus(String id, String status);
}

class HttpInvoiceRepository implements InvoiceRepository {
  final String _baseUrl;

  HttpInvoiceRepository({String? baseUrl})
      : _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

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
  Future<List<Invoice>> getInvoices({String? status}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse('$_baseUrl${ApiRoutes.invoices}')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(uri, headers: await _authHeaders);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch invoices: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final invoicesJson = data['invoices'] as List<dynamic>;

    return invoicesJson
        .map((json) => _invoiceFromMap(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Invoice> getInvoiceById(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl${ApiRoutes.invoices}/$id'),
      headers: await _authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch invoice: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _invoiceFromMap(data['invoice'] as Map<String, dynamic>);
  }

  @override
  Future<Invoice> generateInvoice(String orderId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl${ApiRoutes.invoices}/generate/$orderId'),
      headers: await _authHeaders,
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to generate invoice: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _invoiceFromMap(data['invoice'] as Map<String, dynamic>);
  }

  @override
  Future<void> updateInvoiceStatus(String id, String status) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl${ApiRoutes.invoices}/$id/status'),
      headers: await _authHeaders,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update invoice status: ${response.body}');
    }
  }

  Invoice _invoiceFromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      orderId: map['orderId'] as String,
      lineItems: (map['lineItems'] as List<dynamic>)
          .map((item) => InvoiceLineItem(
                description: item['description'] as String,
                quantity: item['quantity'] as int,
                unitPrice: (item['unitPrice'] as num).toDouble(),
                totalPrice: (item['totalPrice'] as num).toDouble(),
              ))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      markup: (map['markup'] as num).toDouble(),
      tariff: (map['tariff'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      pdfUrl: map['pdfUrl'] as String?,
      displayInvoiceNumber: map['displayInvoiceNumber'] as String?,
      dueDate: map['dueDate'] != null ? _parseDateTime(map['dueDate']) : null,
      airShippingCost: (map['airShippingCost'] as num?)?.toDouble(),
      oceanShippingCost: (map['oceanShippingCost'] as num?)?.toDouble(),
      createdAt: _parseDateTime(map['createdAt']),
      sentAt: map['sentAt'] != null ? _parseDateTime(map['sentAt']) : null,
      paidAt: map['paidAt'] != null ? _parseDateTime(map['paidAt']) : null,
    );
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is String) return DateTime.parse(value);
    if (value is Map) {
      final seconds = value['_seconds'] as int? ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return DateTime.now();
  }
}
