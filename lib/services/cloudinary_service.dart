// lib/services/cloudinary_service.dart
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Cloudinary image upload service using unsigned upload preset.
/// Works on both mobile (Android/iOS) and web (Chrome).
///
/// Setup (one-time in Cloudinary dashboard):
///  1. Go to Settings → Upload → Upload presets
///  2. Create a preset named "agrivision_unsigned", set Signing Mode = Unsigned
///  3. In the preset settings, make sure the "Folder" field is EMPTY or set to
///     a simple path like "agrivision" (NOT a Windows local path).
///  4. Replace _cloudName below with your actual cloud name
///
class CloudinaryService {
  // ── YOUR CLOUDINARY CREDENTIALS ──────────────────────────────────────────
  static const String _cloudName = 'dl5mu8zse';              // ✅ your cloud name
  static const String _uploadPreset = 'agrivision_unsigned';  // ✅ unsigned preset
  // ─────────────────────────────────────────────────────────────────────────

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads [xFile] to Cloudinary and returns the secure URL.
  ///
  /// Works on both mobile (dart:io) and web using [XFile.readAsBytes()].
  /// NOTE: The "folder" is managed by the Cloudinary preset itself.
  ///       Do NOT pass a local file system path as a folder.
  static Future<String?> uploadImage(XFile xFile) async {
    try {
      // Read bytes — works on both mobile and web
      final bytes = await xFile.readAsBytes();

      // Generate a safe, unique filename (no path separators)
      final ext = _getExtension(xFile.path);
      final safeFilename = '${const Uuid().v4()}.$ext';

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Required: unsigned upload preset
      // NOTE: Folder is configured inside the Cloudinary preset dashboard.
      // Do NOT pass a folder field here — it causes "[400] Invalid folder" errors
      // when the preset has already assigned a folder or the path is invalid.
      request.fields['upload_preset'] = _uploadPreset;

      // Attach file using bytes (works on web + mobile)
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: safeFilename,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        return json['secure_url'] as String?;
      } else {
        final body = await response.stream.bytesToString();
        throw Exception(
            'Cloudinary upload failed [${response.statusCode}]: $body');
      }
    } catch (e) {
      throw Exception('Cloudinary upload error: $e');
    }
  }

  /// Extracts a clean file extension from a path.
  static String _getExtension(String path) {
    try {
      final name = path.replaceAll('\\', '/').split('/').last;
      final parts = name.split('.');
      if (parts.length > 1) return parts.last.toLowerCase();
    } catch (_) {}
    return 'jpg';
  }
}
