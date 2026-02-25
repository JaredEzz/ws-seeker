/// PDF invoice generation service.
///
/// Generates downloadable PDF invoices matching the
/// CROMA WHOLESALE template format.
library;

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  /// Generate a PDF invoice from invoice data.
  ///
  /// Returns the PDF bytes ready for download or storage.
  Future<Uint8List> generateInvoicePdf(Map<String, dynamic> invoice) async {
    final pdf = pw.Document();

    final orderId = invoice['orderId'] as String? ?? '';
    final displayNumber = invoice['displayInvoiceNumber'] as String? ?? orderId;
    final lineItems = (invoice['lineItems'] as List<dynamic>?) ?? [];
    final subtotal = (invoice['subtotal'] as num?)?.toDouble() ?? 0;
    final markup = (invoice['markup'] as num?)?.toDouble() ?? 0;
    final tariff = (invoice['tariff'] as num?)?.toDouble() ?? 0;
    final airShipping =
        (invoice['airShippingCost'] as num?)?.toDouble() ?? 0;
    final oceanShipping =
        (invoice['oceanShippingCost'] as num?)?.toDouble() ?? 0;
    final total = (invoice['total'] as num?)?.toDouble() ?? 0;
    final dueDate = invoice['dueDate'] as String?;
    final createdAt = invoice['createdAt'];

    String formatDate(dynamic value) {
      if (value is String) {
        try {
          final dt = DateTime.parse(value);
          return '${dt.month}/${dt.day}/${dt.year}';
        } catch (_) {
          return value;
        }
      }
      if (value is Map) {
        final seconds = value['_seconds'] as int? ?? 0;
        final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        return '${dt.month}/${dt.day}/${dt.year}';
      }
      return '';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(displayNumber, formatDate(createdAt), dueDate),
              pw.SizedBox(height: 32),

              // Line items table
              _buildLineItemsTable(lineItems),
              pw.SizedBox(height: 24),

              // Totals
              _buildTotals(
                subtotal: subtotal,
                markup: markup,
                tariff: tariff,
                airShipping: airShipping,
                oceanShipping: oceanShipping,
                total: total,
              ),
              pw.Spacer(),

              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
      String invoiceNumber, String date, String? dueDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CROMA WHOLESALE',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('527 W State Street, Unit 102',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text('Pleasant Grove, UT 84062',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 8),
                _headerRow('Invoice #', invoiceNumber),
                _headerRow('Date', date),
                if (dueDate != null) _headerRow('Due Date', dueDate),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.grey800),
      ],
    );
  }

  pw.Widget _headerRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('$label: ',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildLineItemsTable(List<dynamic> lineItems) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      headers: ['Description', 'Qty', 'Unit Price', 'Total'],
      data: lineItems.map((item) {
        final i = item as Map<String, dynamic>;
        return [
          i['description'] as String? ?? '',
          '${i['quantity'] ?? 0}',
          '\$${(i['unitPrice'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
          '\$${(i['totalPrice'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildTotals({
    required double subtotal,
    required double markup,
    required double tariff,
    required double airShipping,
    required double oceanShipping,
    required double total,
  }) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        child: pw.Column(
          children: [
            _totalRow('SUBTOTAL', subtotal),
            if (markup > 0) _totalRow('Markup (13%)', markup),
            if (tariff > 0) _totalRow('Estimated Tariff', tariff),
            if (airShipping > 0)
              _totalRow('AIR SHIPPING + Tariffs', airShipping),
            if (oceanShipping > 0)
              _totalRow('OCEAN SHIPPING + Tariffs', oceanShipping),
            pw.Divider(thickness: 1.5, color: PdfColors.grey800),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('BALANCE TOTAL',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _totalRow(String label, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text('\$${amount.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Croma Wholesale · 527 W State Street, Unit 102, Pleasant Grove UT 84062',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }
}
