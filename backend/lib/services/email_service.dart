/// Email notification service for order lifecycle events.
///
/// Sends transactional emails via Resend API for:
/// - Order confirmation (to customer)
/// - Invoice sent (to customer)
/// - Payment received (to customer)
/// - Order shipped (to customer)
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  final String _resendApiKey;
  final String _fromEmail;
  final String _appUrl;

  EmailService({
    required String resendApiKey,
    required String fromEmail,
    required String appUrl,
  })  : _resendApiKey = resendApiKey,
        _fromEmail = fromEmail,
        _appUrl = appUrl;

  /// Send order confirmation to customer
  Future<void> sendOrderConfirmation({
    required String toEmail,
    required String orderId,
    required String displayOrderNumber,
    required String customerName,
    required double totalAmount,
    required String language,
  }) async {
    await _sendEmail(
      to: toEmail,
      subject: 'Order Confirmed — $displayOrderNumber',
      html: _buildTemplate(
        heading: 'Order Confirmed',
        body: '''
        <p>Hi $customerName,</p>
        <p>Your order <strong>$displayOrderNumber</strong> has been submitted successfully.</p>
        <table style="width:100%;border-collapse:collapse;margin:16px 0;">
          <tr style="border-bottom:1px solid #e4e4e7;">
            <td style="padding:8px 0;color:#71717a;">Order Number</td>
            <td style="padding:8px 0;text-align:right;font-weight:600;">$displayOrderNumber</td>
          </tr>
          <tr style="border-bottom:1px solid #e4e4e7;">
            <td style="padding:8px 0;color:#71717a;">Origin</td>
            <td style="padding:8px 0;text-align:right;">${language.toUpperCase()}</td>
          </tr>
          <tr>
            <td style="padding:8px 0;color:#71717a;">Estimated Total</td>
            <td style="padding:8px 0;text-align:right;font-weight:600;">\$${totalAmount.toStringAsFixed(2)}</td>
          </tr>
        </table>
        <p>We'll send you an invoice once your order has been reviewed.</p>
        ''',
        ctaText: 'View Order',
        ctaUrl: '$_appUrl/orders/$orderId',
      ),
    );
  }

  /// Send invoice notification to customer
  Future<void> sendInvoiceNotification({
    required String toEmail,
    required String orderId,
    required String displayOrderNumber,
    required String customerName,
    required double totalAmount,
    required String? invoiceNumber,
  }) async {
    await _sendEmail(
      to: toEmail,
      subject: 'Invoice Ready — ${invoiceNumber ?? displayOrderNumber}',
      html: _buildTemplate(
        heading: 'Invoice Ready',
        body: '''
        <p>Hi $customerName,</p>
        <p>Your invoice for order <strong>$displayOrderNumber</strong> is ready.</p>
        <table style="width:100%;border-collapse:collapse;margin:16px 0;">
          <tr style="border-bottom:1px solid #e4e4e7;">
            <td style="padding:8px 0;color:#71717a;">Invoice</td>
            <td style="padding:8px 0;text-align:right;font-weight:600;">${invoiceNumber ?? displayOrderNumber}</td>
          </tr>
          <tr>
            <td style="padding:8px 0;color:#71717a;">Amount Due</td>
            <td style="padding:8px 0;text-align:right;font-weight:600;">\$${totalAmount.toStringAsFixed(2)}</td>
          </tr>
        </table>
        <p>Please submit your payment and upload proof of payment on the order page.</p>
        ''',
        ctaText: 'View Invoice & Pay',
        ctaUrl: '$_appUrl/orders/$orderId',
      ),
    );
  }

  /// Send payment received confirmation to customer
  Future<void> sendPaymentReceived({
    required String toEmail,
    required String displayOrderNumber,
    required String customerName,
  }) async {
    await _sendEmail(
      to: toEmail,
      subject: 'Payment Received — $displayOrderNumber',
      html: _buildTemplate(
        heading: 'Payment Received',
        body: '''
        <p>Hi $customerName,</p>
        <p>We've received your payment for order <strong>$displayOrderNumber</strong>. Thank you!</p>
        <p>We'll notify you when your order ships.</p>
        ''',
      ),
    );
  }

  /// Send order shipped notification to customer
  Future<void> sendOrderShipped({
    required String toEmail,
    required String orderId,
    required String displayOrderNumber,
    required String customerName,
    String? trackingNumber,
    String? trackingCarrier,
  }) async {
    final trackingInfo = trackingNumber != null
        ? '''
        <table style="width:100%;border-collapse:collapse;margin:16px 0;">
          <tr style="border-bottom:1px solid #e4e4e7;">
            <td style="padding:8px 0;color:#71717a;">Carrier</td>
            <td style="padding:8px 0;text-align:right;">${trackingCarrier ?? 'N/A'}</td>
          </tr>
          <tr>
            <td style="padding:8px 0;color:#71717a;">Tracking Number</td>
            <td style="padding:8px 0;text-align:right;font-weight:600;">$trackingNumber</td>
          </tr>
        </table>
        '''
        : '';

    await _sendEmail(
      to: toEmail,
      subject: 'Order Shipped — $displayOrderNumber',
      html: _buildTemplate(
        heading: 'Order Shipped!',
        body: '''
        <p>Hi $customerName,</p>
        <p>Your order <strong>$displayOrderNumber</strong> has been shipped!</p>
        $trackingInfo
        <p>You can track your order on the order details page.</p>
        ''',
        ctaText: 'Track Order',
        ctaUrl: '$_appUrl/orders/$orderId',
      ),
    );
  }

  /// Send comment notification
  Future<void> sendCommentNotification({
    required String toEmail,
    required String orderId,
    required String displayOrderNumber,
    required String commenterName,
    required String commentPreview,
  }) async {
    await _sendEmail(
      to: toEmail,
      subject: 'New Comment on Order $displayOrderNumber',
      html: _buildTemplate(
        heading: 'New Comment',
        body: '''
        <p><strong>$commenterName</strong> left a comment on order <strong>$displayOrderNumber</strong>:</p>
        <div style="background-color:#f4f4f5;border-left:4px solid #18181b;padding:12px 16px;margin:16px 0;border-radius:0 8px 8px 0;">
          <p style="margin:0;color:#3f3f46;font-style:italic;">$commentPreview</p>
        </div>
        ''',
        ctaText: 'View Order',
        ctaUrl: '$_appUrl/orders/$orderId',
      ),
    );
  }

  /// Send payment proof uploaded notification to admins
  Future<void> sendPaymentProofUploaded({
    required String toEmail,
    required String orderId,
    required String displayOrderNumber,
    required String customerName,
  }) async {
    await _sendEmail(
      to: toEmail,
      subject: 'Payment Proof Uploaded — $displayOrderNumber',
      html: _buildTemplate(
        heading: 'Payment Proof Uploaded',
        body: '''
        <p><strong>$customerName</strong> has uploaded proof of payment for order <strong>$displayOrderNumber</strong>.</p>
        <p>Please review the payment proof and update the order status accordingly.</p>
        ''',
        ctaText: 'Review Order',
        ctaUrl: '$_appUrl/orders/$orderId',
      ),
    );
  }

  /// Send generic status change notification to customer
  Future<void> sendStatusChangeNotification({
    required String toEmail,
    required String orderId,
    required String displayOrderNumber,
    required String customerName,
    required String heading,
    required String message,
  }) async {
    await _sendEmail(
      to: toEmail,
      subject: 'Order Update — $displayOrderNumber',
      html: _buildTemplate(
        heading: heading,
        body: '''
        <p>Hi $customerName,</p>
        <p>$message</p>
        ''',
        ctaText: 'View Order',
        ctaUrl: '$_appUrl/orders/$orderId',
      ),
    );
  }

  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
    if (_resendApiKey.isEmpty) return; // Skip if not configured

    final response = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $_resendApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from': _fromEmail,
        'to': [to],
        'subject': subject,
        'html': html,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      // Log but don't throw — email failure shouldn't block order operations
      print('Email send failed (${response.statusCode}): ${response.body}');
    }
  }

  String _buildTemplate({
    required String heading,
    required String body,
    String? ctaText,
    String? ctaUrl,
  }) {
    final ctaButton = (ctaText != null && ctaUrl != null)
        ? '''
        <div style="text-align:center;margin:24px 0;">
          <a href="$ctaUrl" style="display:inline-block;background-color:#18181b;color:#ffffff;padding:12px 24px;border-radius:8px;text-decoration:none;font-weight:600;font-size:14px;">$ctaText</a>
        </div>
        '''
        : '';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$heading — Croma Wholesale</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f4f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <div style="max-width:560px;margin:40px auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,0.1);">
    <div style="background-color:#18181b;padding:24px;text-align:center;">
      <h1 style="color:#ffffff;margin:0;font-size:20px;font-weight:700;">CROMA WHOLESALE</h1>
    </div>
    <div style="padding:32px 24px;">
      <h2 style="margin:0 0 16px;font-size:22px;color:#18181b;">$heading</h2>
      $body
      $ctaButton
    </div>
    <div style="padding:16px 24px;background-color:#f4f4f5;text-align:center;">
      <p style="margin:0;font-size:12px;color:#71717a;">Croma Wholesale · 527 W State Street, Unit 102, Pleasant Grove UT 84062</p>
    </div>
  </div>
</body>
</html>
''';
  }
}
