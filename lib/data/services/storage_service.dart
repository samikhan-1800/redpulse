import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class StorageServiceInterface {
  Future<String> uploadProfileImage(String userId, File file);
  Future<void> deleteProfileImage(String userId);
  Future<String> uploadChatImage(String chatId, File file);
}

class StorageService implements StorageServiceInterface {
  final FirebaseFirestore _firestore;

  StorageService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> uploadProfileImage(String userId, File file) async {
    try {
      if (!await file.exists()) {
        throw 'Image file does not exist';
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw 'Image file is empty';
      }

      final base64Image = base64Encode(bytes);

      if (base64Image.length > 800000) {
        throw 'Image is too large. Please select a smaller image';
      }

      await _firestore.collection('users').doc(userId).update({
        'profileImageBase64': base64Image,
        'profileImageUrl': null,
      });

      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      print('Profile image storage error: $e');
      throw 'Failed to save profile image: $e';
    }
  }

  @override
  Future<void> deleteProfileImage(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profileImageBase64': FieldValue.delete(),
        'profileImageUrl': FieldValue.delete(),
      });
    } catch (e) {
      print('Delete profile image error: $e');
    }
  }

  @override
  Future<String> uploadChatImage(String chatId, File file) async {
    throw 'Chat image uploads are currently disabled';
  }
}
