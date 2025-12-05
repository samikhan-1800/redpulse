import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Storage service for uploading images
abstract class StorageServiceInterface {
  Future<String> uploadProfileImage(String userId, File file);
  Future<void> deleteProfileImage(String userId);
  Future<String> uploadChatImage(String chatId, File file);
}

/// Firebase Storage Service Implementation
class StorageService implements StorageServiceInterface {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadProfileImage(String userId, File file) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');

      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload profile image: $e';
    }
  }

  @override
  Future<void> deleteProfileImage(String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      await ref.delete();
    } catch (e) {
      // Image might not exist, ignore error
    }
  }

  @override
  Future<String> uploadChatImage(String chatId, File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('chat_images/$chatId/$fileName');

      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload chat image: $e';
    }
  }
}
