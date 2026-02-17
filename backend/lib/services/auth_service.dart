import 'dart:convert';
import 'dart:io';

import 'package:dart_firebase_admin/auth.dart';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

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

  // TODO: Remove skipEmail parameter when ready for production
  Future<String?> sendMagicLink(String email, {bool skipEmail = false}) async {
    final token = const Uuid().v4();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    // Store magic link in Firestore
    await _firestore.collection('magic_links').doc(token).set({
      'email': email,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp,
    });

    final link = '$_baseUrl/auth/callback?token=$token&email=$email';

    // TODO: Remove skipEmail branch when ready for production
    if (skipEmail) {
      return link;
    }

    // Send email via Resend
    await _sendEmail(
      to: email,
      subject: 'Sign in to WS-Seeker',
      html: _buildHtmlTemplate(link),
    );

    return null;
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
        CreateRequest(email: email, emailVerified: true),
      );
    }

    // Generate Firebase Custom Token
    // (bypass dart_firebase_admin's createCustomToken — its JWT signature is broken)
    final customToken = _createCustomToken(userRecord.uid);

    final result = <String, dynamic>{'token': customToken};

    // Check if user is an admin (superUser/supplier) — they bypass segment check
    var isAdmin = false;
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userRecord.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final role = userData['role'] as String?;
        isAdmin = role == 'super_user' || role == 'supplier';
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

    // Validate Shopify segment membership (skip for admins)
    if (!isAdmin &&
        _shopifyService != null &&
        _shopifyService.isConfigured) {
      final inSegment =
          await _shopifyService.isEmailInSegment(email, 'Appstle - Wholesale Membership');
      if (!inSegment) {
        throw Exception(
            'Access denied. Your email is not associated with a wholesale membership.');
      }
    }

    // Try Shopify sync (non-blocking - failure must not prevent login)
    // Skip for admins so Shopify doesn't overwrite their elevated role.
    try {
      if (!isAdmin &&
          _shopifyService != null &&
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

    return result;
  }

  String _createCustomToken(String uid) {
    final saJson = Platform.environment['FIREBASE_SERVICE_ACCOUNT_JSON'];
    if (saJson == null || saJson.isEmpty) {
      throw Exception('FIREBASE_SERVICE_ACCOUNT_JSON env var is not set');
    }
    final sa = jsonDecode(saJson) as Map<String, dynamic>;
    final privateKeyPem = sa['private_key'] as String;
    final serviceAccountEmail = sa['client_email'] as String;

    final now = DateTime.now();
    final jwt = JWT(
      {
        'uid': uid,
      },
      issuer: serviceAccountEmail,
      subject: serviceAccountEmail,
      audience: Audience.one(
        'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
      ),
    );

    return jwt.sign(
      RSAPrivateKey(privateKeyPem),
      algorithm: JWTAlgorithm.RS256,
      expiresIn: const Duration(hours: 1),
    );
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
  <title>Sign in to Croma TCG</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f4f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f4f5;padding:40px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:8px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,0.08);">
          <!-- Header -->
          <tr>
            <td style="background-color:#18181b;padding:28px 32px;text-align:center;">
              <span style="color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">CROMA TCG</span>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:40px 32px 16px;">
              <h1 style="margin:0 0 12px;font-size:20px;font-weight:600;color:#18181b;">Sign in to your account</h1>
              <p style="margin:0 0 28px;font-size:15px;line-height:1.6;color:#52525b;">Click the button below to securely sign in. This link expires in 15 minutes.</p>
              <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 0 28px;">
                <tr>
                  <td style="background-color:#18181b;border-radius:6px;">
                    <a href="$link" style="display:inline-block;padding:14px 32px;color:#ffffff;font-size:15px;font-weight:600;text-decoration:none;">Sign In</a>
                  </td>
                </tr>
              </table>
              <p style="margin:0;font-size:13px;line-height:1.5;color:#a1a1aa;">If the button doesn't work, copy and paste this link:</p>
              <p style="margin:4px 0 0;font-size:13px;line-height:1.5;word-break:break-all;"><a href="$link" style="color:#3b82f6;text-decoration:underline;">$link</a></p>
            </td>
          </tr>
          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <hr style="border:none;border-top:1px solid #e4e4e7;margin:24px 0;">
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="padding:0 32px 32px;">
              <p style="margin:0;font-size:12px;line-height:1.5;color:#a1a1aa;">If you didn't request this link, you can safely ignore this email.</p>
              <p style="margin:8px 0 0;font-size:12px;color:#d4d4d8;">Croma TCG &middot; Wholesale Portal</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }
}
