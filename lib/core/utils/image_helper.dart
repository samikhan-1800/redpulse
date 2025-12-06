import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Helper to display images from URL or base64 data
class ImageHelper {
  /// Check if URL is a base64 data URL
  static bool isBase64Image(String? url) {
    return url?.startsWith('data:image') ?? false;
  }

  /// Decode base64 data URL to bytes
  static Uint8List? decodeBase64Image(String dataUrl) {
    try {
      final base64String = dataUrl.split(',').last;
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  /// Get ImageProvider for URL or base64
  static ImageProvider getImageProvider(String url) {
    if (isBase64Image(url)) {
      final bytes = decodeBase64Image(url);
      return bytes != null
          ? MemoryImage(bytes)
          : const AssetImage('assets/default_avatar.png') as ImageProvider;
    }
    return CachedNetworkImageProvider(url);
  }

  /// Build profile image widget
  static Widget buildProfileImage({
    required String? imageUrl,
    required double size,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, size: size * 0.6, color: Colors.grey[600]),
      );
    }

    if (isBase64Image(imageUrl)) {
      final bytes = decodeBase64Image(imageUrl);
      if (bytes == null) {
        return _buildErrorAvatar(size);
      }
      return ClipOval(
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildErrorAvatar(size),
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: fit,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey[600],
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _buildErrorAvatar(size),
      ),
    );
  }

  static Widget _buildErrorAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, size: size * 0.6, color: Colors.grey[600]),
    );
  }
}
