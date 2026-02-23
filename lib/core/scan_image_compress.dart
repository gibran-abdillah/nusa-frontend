import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compresses an image file for scan upload: resize to max 1280px and JPEG quality 85.
/// Reduces upload size (e.g. 2MB+ → ~200–400KB) with little impact on food recognition.
/// Returns null if compression fails (caller can fall back to original).
Future<Uint8List?> compressImageForScan(String filePath) async {
  try {
    final bytes = await FlutterImageCompress.compressWithFile(
      filePath,
      minWidth: 1280,
      minHeight: 1280,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    return bytes;
  } catch (_) {
    return null;
  }
}
