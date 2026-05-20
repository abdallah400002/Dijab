import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> _uploadViaHttpOnWeb(
    String base64Image,
    String productId,
    String fileName,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be signed in to upload images');
    }
    final token = await user.getIdToken();
    final projectId = Firebase.app().options.projectId;
    if (projectId == null || projectId.isEmpty) {
      throw Exception('Firebase project ID not found');
    }
    final url = Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/uploadTryOnImageHttp',
    );
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'base64Image': base64Image,
        'productId': productId,
        'fileName': fileName,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.statusCode} ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body.containsKey('error')) {
      final err = body['error'] as Map<String, dynamic>;
      throw Exception('Upload failed: ${err['message'] ?? err}');
    }
    final urlStr = body['url'] as String?;
    if (urlStr == null || urlStr.isEmpty) {
      throw Exception('Upload failed: no URL in response');
    }
    return urlStr;
  }

  Future<String> uploadProductImageFromBytes(
    Uint8List imageBytes,
    String fileName,
    String productId, {
    int quality = 85,
  }) async {
    try {
      Uint8List bytesToUpload = imageBytes;

      // On web: use raw HTTP to call Cloud Function (avoids cloud_functions &
      // firebase_storage Int64/dart2js issues).
      if (kIsWeb) {
        final base64 = base64Encode(bytesToUpload);
        return _uploadViaHttpOnWeb(base64, productId, fileName);
      }

      // Native: use firebase_storage directly.
      if (!kIsWeb) {
        final compressedBytes = await FlutterImageCompress.compressWithList(
          imageBytes,
          quality: quality,
          minWidth: 1920,
          minHeight: 1080,
        );
        bytesToUpload = compressedBytes;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage
          .ref()
          .child('products')
          .child(productId)
          .child('_${timestamp}_$fileName');

      await ref.putData(bytesToUpload, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading image from bytes: $e');
    }
  }

  // Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Error deleting image: $e');
    }
  }
}
