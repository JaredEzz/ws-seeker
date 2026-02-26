import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Upload a file to Firebase Cloud Storage and return the download URL.
  ///
  /// Files are stored under `proof_of_payment/{orderId}/{filename}`.
  Future<String> uploadProofOfPayment({
    required String orderId,
    required String filename,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref('proof_of_payment/$orderId/$filename');

    final metadata = SettableMetadata(
      contentType: _contentTypeFromFilename(filename),
    );

    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  /// Upload a comment image to Firebase Cloud Storage and return the download URL.
  ///
  /// Files are stored under `comment_images/{orderId}/{timestamp}_{filename}`.
  Future<String> uploadCommentImage({
    required String orderId,
    required String filename,
    required Uint8List bytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('comment_images/$orderId/${timestamp}_$filename');

    final metadata = SettableMetadata(
      contentType: _contentTypeFromFilename(filename),
    );

    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  /// Upload a product image to Firebase Cloud Storage and return the download URL.
  ///
  /// Files are stored under `product_images/{productName}/{filename}`.
  Future<String> uploadProductImage({
    required String productName,
    required String filename,
    required Uint8List bytes,
  }) async {
    final safeName = productName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('product_images/$safeName/${timestamp}_$filename');

    final metadata = SettableMetadata(
      contentType: _contentTypeFromFilename(filename),
    );

    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  String _contentTypeFromFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}
