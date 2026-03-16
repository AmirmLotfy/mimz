import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Service for handling profile image capture and upload to Firebase Storage.
class ProfileStorageService {
  static final _auth = FirebaseAuth.instance;
  static final _storage = FirebaseStorage.instance;
  static final _picker = ImagePicker();

  /// Opens the image picker (camera or gallery) and uploads the result.
  ///
  /// Returns the download URL on success, or null if cancelled.
  static Future<({String url, String storagePath})?> pickAndUpload({
    bool fromCamera = false,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final file = File(picked.path);
    final storagePath = 'user-profile-images/$uid/avatar.jpg';

    final ref = _storage.ref(storagePath);
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uid': uid, 'uploadedAt': DateTime.now().toIso8601String()},
    );

    await ref.putFile(file, metadata);
    final url = await ref.getDownloadURL();

    return (url: url, storagePath: storagePath);
  }

  /// Delete the current profile image from storage.
  static Future<void> deleteImage(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {
      // Non-fatal — may not exist
    }
  }
}
