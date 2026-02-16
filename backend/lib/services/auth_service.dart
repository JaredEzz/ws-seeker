import 'package:dart_firebase_admin/auth.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shopify_service.dart';
import 'user_service.dart';

class AuthService {
  final Auth _auth;
  final Firestore _firestore;
  final String _resendApiKey;
  final String _fromEmail;
  final String _baseUrl;
  final ShopifyService? _shopifyService;
  final UserService? _userService;

  AuthService(
    FirebaseAdminApp admin,
    this._firestore, {
    required String resendApiKey,
    required String fromEmail,
    required String baseUrl,
    ShopifyService? shopifyService,
    UserService? userService,
  })  : _auth = Auth(admin),
        _resendApiKey = resendApiKey,
        _fromEmail = fromEmail,
        _baseUrl = baseUrl,
        _shopifyService = shopifyService,
        _userService = userService;

  Future<void> sendMagicLink(String email) async {
    final token = const Uuid().v4();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    // Store magic link in Firestore
    await _firestore.collection('magic_links').doc(token).set({
      'email': email,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp,
    });

    final link = '$_baseUrl/#/auth/callback?token=$token&email=$email';

    // Send email via Resend
    await _sendEmail(
      to: email,
      subject: 'Sign in to WS-Seeker',
      html: _buildHtmlTemplate(link),
    );
  }

  Future<Map<String, dynamic>> verifyMagicLink(String token, String email) async {
    final doc = await _firestore.collection('magic_links').doc(token).get();

    if (!doc.exists) {
      throw Exception('Invalid or expired magic link');
    }

    final data = doc.data()!;
    final storedEmail = data['email'] as String;
    final expiresAt = DateTime.parse(data['expiresAt'] as String);

    if (storedEmail != email) {
      throw Exception('Email mismatch');
    }

    if (DateTime.now().isAfter(expiresAt)) {
      await _firestore.collection('magic_links').doc(token).delete();
      throw Exception('Magic link expired');
    }

    // Delete token after use
    await _firestore.collection('magic_links').doc(token).delete();

    // Get or create user
    UserRecord userRecord;
    try {
      userRecord = await _auth.getUserByEmail(email);
    } catch (e) {
      // Create user if they don't exist
      userRecord = await _auth.createUser(
        UserCustomAttributes(email: email, emailVerified: true),
      );
    }

    // Generate Firebase Custom Token
    final customToken = await _auth.createCustomToken(userRecord.uid);

    final result = <String, dynamic>{'token': customToken};

    // Try Shopify sync (non-blocking - failure must not prevent login)
    try {
      if (_shopifyService != null &&
          _userService != null &&
          _shopifyService.isConfigured) {
        final shopifyResult =
            await _shopifyService.getCustomerByEmail(email);
        if (shopifyResult != null) {
          await _userService.updateUserFromShopify(
            userId: userRecord.uid,
            role: shopifyResult.role,
            address: shopifyResult.address,
          );
          result['role'] = shopifyResult.role.name;
          result['savedAddress'] = shopifyResult.address.toJson();
          return result;
        }
      }
    } catch (e) {
      print('Shopify sync failed during login (non-blocking): $e');
    }

    // No Shopify match - read existing Firestore profile for role/address
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userRecord.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (userData['role'] != null) {
          result['role'] = userData['role'];
        }
        if (userData['savedAddress'] != null) {
          result['savedAddress'] = userData['savedAddress'];
        }
      }
    } catch (e) {
      print('Firestore user lookup failed (non-blocking): $e');
    }

    return result;
  }

  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
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
      throw Exception('Failed to send email: ${response.body}');
    }
  }

  String _buildHtmlTemplate(String link) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sign in to WS-Seeker</title>
  <style>
    body {
      font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #f9fafb;
      color: #111827;
      margin: 0;
      padding: 0;
    }
    .wrapper {
      width: 100%;
      table-layout: fixed;
      background-color: #f9fafb;
      padding-bottom: 40px;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #ffffff;
      border: 1px solid #e5e7eb;
      border-radius: 12px;
      margin-top: 40px;
      overflow: hidden;
    }
    .header {
      background-color: #1d4ed8;
      padding: 32px;
      text-align: center;
    }
    .logo-text {
      color: #ffffff;
      font-size: 28px;
      font-weight: 800;
      letter-spacing: -0.025em;
      margin: 0;
    }
    .content {
      padding: 40px 32px;
    }
    h1 {
      font-size: 24px;
      font-weight: 700;
      color: #111827;
      margin-bottom: 16px;
      text-align: center;
    }
    p {
      font-size: 16px;
      line-height: 1.6;
      color: #4b5563;
      margin-bottom: 32px;
      text-align: center;
    }
    .cta-container {
      text-align: center;
      margin-bottom: 32px;
    }
    .button {
      background-color: #2563eb;
      color: #ffffff !important;
      padding: 16px 40px;
      text-decoration: none;
      border-radius: 8px;
      font-weight: 600;
      font-size: 16px;
      display: inline-block;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    }
    .divider {
      border-top: 1px solid #e5e7eb;
      margin: 32px 0;
    }
    .footer {
      padding: 0 32px 40px;
      text-align: center;
      color: #6b7280;
      font-size: 14px;
    }
    .security-note {
      font-size: 12px;
      color: #9ca3af;
      margin-top: 16px;
    }
    .link-fallback {
      word-break: break-all;
      font-size: 13px;
      color: #2563eb;
      margin-top: 12px;
      text-decoration: underline;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="container">
      <div class="header">
        <div class="logo-text">🎯 WS-Seeker</div>
      </div>
      <div class="content">
        <h1>Welcome back!</h1>
        <p>Confirm your email address to securely sign in to your WS-Seeker account. This link will remain active for the next 15 minutes.</p>
        
        <div class="cta-container">
          <a href="$link" class="button">Confirm & Sign In</a>
        </div>

        <p class="security-note">
          If the button doesn't work, you can copy and paste this link into your browser:
          <br>
          <a href="$link" class="link-fallback">$link</a>
        </p>
      </div>
      <div class="footer">
        <p>&copy; ${DateTime.now().year} WS-Seeker. All rights reserved.<br>
        If you didn't request this sign-in link, you can safely ignore this email.</p>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }
}
