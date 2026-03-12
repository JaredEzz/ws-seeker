/// Seed script: creates Firebase Auth users + Firestore user docs for
/// the core admin/supplier team.
///
/// Usage:
///   dart run bin/seed_users.dart [--dry-run]
///
/// Requires FIREBASE_SERVICE_ACCOUNT_JSON env var or Application Default
/// Credentials.
library;

import 'dart:io';

import 'package:dart_firebase_admin/auth.dart';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';

/// Each account to create.
class _SeedUser {
  final String email;
  final String role; // 'super_user' or 'supplier'
  final String label;
  final String? preferredLocale;

  const _SeedUser({
    required this.email,
    required this.role,
    required this.label,
    this.preferredLocale,
  });
}

const _users = [
  _SeedUser(
    email: 'admin@cromatcg.com',
    role: 'super_user',
    label: 'Dan (admin)',
  ),
  _SeedUser(
    email: 'Taylor@cromatcg.com',
    role: 'super_user',
    label: 'Taylor',
  ),
  _SeedUser(
    email: 'jared@jaredezz.tech',
    role: 'super_user',
    label: 'Jared',
  ),
  _SeedUser(
    email: 'wholesalejpn@cromatcg.com',
    role: 'supplier',
    label: 'JPN Supplier',
    preferredLocale: 'ja',
  ),
];

void main(List<String> args) async {
  final dryRun = args.contains('--dry-run');

  if (dryRun) {
    print('=== DRY RUN — no writes will be made ===\n');
    for (final u in _users) {
      print('  ${u.email} -> ${u.role} (${u.label})'
          '${u.preferredLocale != null ? ' [locale: ${u.preferredLocale}]' : ''}');
    }
    print('\nDry run complete.');
    return;
  }

  // Initialize Firebase Admin
  final serviceAccountJson =
      Platform.environment['FIREBASE_SERVICE_ACCOUNT_JSON'];
  Credential credential;
  if (serviceAccountJson != null && serviceAccountJson.isNotEmpty) {
    final tmpFile = File('/tmp/firebase-sa.json');
    tmpFile.writeAsStringSync(serviceAccountJson);
    credential = Credential.fromServiceAccount(tmpFile);
  } else {
    credential = Credential.fromApplicationDefaultCredentials();
  }

  final admin = FirebaseAdminApp.initializeApp('ws-seeker', credential);
  final auth = Auth(admin);
  final firestore = Firestore(admin);
  final usersRef = firestore.collection('users');

  print('Creating ${_users.length} accounts...\n');

  for (final u in _users) {
    final email = u.email.toLowerCase();

    // 1. Create or get Firebase Auth user
    UserRecord userRecord;
    try {
      userRecord = await auth.getUserByEmail(email);
      print('  [exists] Auth user for $email (uid: ${userRecord.uid})');
    } catch (_) {
      userRecord = await auth.createUser(
        CreateRequest(email: email, emailVerified: true),
      );
      print('  [created] Auth user for $email (uid: ${userRecord.uid})');
    }

    // 2. Create or update Firestore user doc
    final docRef = usersRef.doc(userRecord.uid);
    final doc = await docRef.get();

    final userData = <String, dynamic>{
      'email': email,
      'role': u.role,
      'updatedAt': FieldValue.serverTimestamp,
    };
    if (u.preferredLocale != null) {
      userData['preferredLocale'] = u.preferredLocale;
    }

    if (doc.exists) {
      await docRef.update(userData);
      print('  [updated] Firestore doc for ${u.label} -> role: ${u.role}');
    } else {
      userData['createdAt'] = FieldValue.serverTimestamp;
      await docRef.set(userData);
      print('  [created] Firestore doc for ${u.label} -> role: ${u.role}');
    }
  }

  print('\nDone! All accounts ready.');
  admin.close();
}
