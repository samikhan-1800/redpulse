import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Storage service for uploading images
abstract class StorageServiceInterface {
  Future<String> uploadProfileImage(String userId, File file);
  Future<void> deleteProfileImage(String userId);
  Future<String> uploadChatImage(String chatId, File file);
}

/// Firestore-based Storage Service (no Firebase Storage needed)
/// Stores compressed images as base64 in Firestore
class StorageService implements StorageServiceInterface {
  final FirebaseFirestore _firestore;

  StorageService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> uploadProfileImage(String userId, File file) async {
    try {
      // Verify file exists and is readable
      if (!await file.exists()) {
        throw 'Image file does not exist';
      }

      // Read file as bytes
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw 'Image file is empty';
      }

      // Compress heavily to keep under Firestore limits (max 1MB per document)
      // Image picker already resized to 512x512, so this should be small
      final base64Image = base64Encode(bytes);

      // Check size (base64 is ~33% larger than binary)
      if (base64Image.length > 800000) {
        // ~600KB original
        throw 'Image is too large. Please select a smaller image';
      }

      // Store base64 in Firestore instead of Storage
      await _firestore.collection('users').doc(userId).update({
        'profileImageBase64': base64Image,
        'profileImageUrl': null, // Clear old Storage URL if any
      });

      // Return a data URL that can be used directly
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
      // Image might not exist, ignore error
      print('Delete profile image error: $e');
    }
  }

  @override
  Future<String> uploadChatImage(String chatId, File file) async {
    // For chat images, we'll keep them smaller or use a different approach
    // For now, disable chat image uploads to avoid Storage costs
    throw 'Chat image uploads are currently disabled';
  }
}
