import 'package:dart_firebase_admin/auth.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final Auth _auth;
  final Firestore _firestore;
  final String _resendApiKey;
  final String _fromEmail;
  final String _baseUrl;

  AuthService(
    FirebaseAdminApp admin,
    this._firestore, {
    required String resendApiKey,
    required String fromEmail,
    required String baseUrl,
  })  : _auth = Auth(admin),
        _resendApiKey = resendApiKey,
        _fromEmail = fromEmail,
        _baseUrl = baseUrl;

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

  Future<String> verifyMagicLink(String token, String email) async {
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
    return await _auth.createCustomToken(userRecord.uid);
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
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sign in to WS-Seeker</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: #f4f7f9;
      color: #1a1a1a;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 600px;
      margin: 40px auto;
      background: #ffffff;
      border-radius: 8px;
      padding: 40px;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    .logo {
      font-size: 24px;
      font-weight: bold;
      color: #2563eb;
      margin-bottom: 24px;
      text-align: center;
    }
    h1 {
      font-size: 20px;
      margin-bottom: 16px;
      text-align: center;
    }
    p {
      line-height: 1.6;
      margin-bottom: 24px;
      text-align: center;
    }
    .button-container {
      text-align: center;
      margin-bottom: 24px;
    }
    .button {
      background-color: #2563eb;
      color: #ffffff !important;
      padding: 12px 32px;
      text-decoration: none;
      border-radius: 6px;
      font-weight: 600;
      display: inline-block;
    }
    .footer {
      font-size: 12px;
      color: #6b7280;
      text-align: center;
      margin-top: 40px;
    }
    .link-alt {
      word-break: break-all;
      font-size: 12px;
      color: #9ca3af;
      margin-top: 24px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">WS-Seeker</div>
    <h1>Verify your email</h1>
    <p>Click the button below to sign in to your WS-Seeker account. This link will expire in 15 minutes.</p>
    <div class="button-container">
      <a href="$link" class="button">Sign In to WS-Seeker</a>
    </div>
    <p>If you didn't request this email, you can safely ignore it.</p>
    <div class="footer">
      &copy; ${DateTime.now().year} WS-Seeker. All rights reserved.
    </div>
    <div class="link-alt">
      If the button doesn't work, copy and paste this link into your browser:<br>
      $link
    </div>
  </div>
</body>
</html>
''';
  }
}
