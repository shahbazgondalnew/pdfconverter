import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/conversion_record.dart';
import '../models/image_to_pdf_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class HeicToJpgService {
  const HeicToJpgService();

  /// Converts HEIC/HEIF into a temporary JPG so preview and crop work.
  static Future<String> prepareForEditing(String path) async {
    final lower = path.toLowerCase();
    if (!lower.endsWith('.heic') && !lower.endsWith('.heif')) {
      return path;
    }

    final tempDir = await getTemporaryDirectory();
    final target = p.join(
      tempDir.path,
      'heic_edit_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      target,
      quality: 95,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (result == null) {
      throw StateError('Could not open HEIC image');
    }
    return result.path;
  }

  Future<ConversionRecord> convert({
    required List<SelectedImage> images,
    int quality = 92,
    ConversionProgressCallback? onProgress,
  }) async {
    if (images.isEmpty) {
      throw StateError('No images to convert');
    }

    final stamp = DateTime.now();
    final storedPaths = <String>[];
    var totalBytes = 0;
    final total = images.length;
    final jpgQuality = quality.clamp(40, 100);

    for (var i = 0; i < images.length; i++) {
      final image = images[i];
      final encoded = await _encodeJpeg(image, jpgQuality);

      final base = p.basenameWithoutExtension(image.path);
      final safeBase = base.isEmpty ? 'image' : base;
      final fileName =
          'HEIC_JPG_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_'
          '${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}_'
          '${i}_$safeBase.jpg';
      final output = await ConversionStorage.createOutputFile(fileName);
      await output.writeAsBytes(encoded, flush: true);
      storedPaths.add(ConversionStorage.toStoredPath(output.path));
      totalBytes += await output.length();

      onProgress?.call(i + 1, total);
      await Future<void>.delayed(const Duration(milliseconds: 8));
    }

    final record = ConversionRecord(
      id: stamp.microsecondsSinceEpoch.toString(),
      name:
          'HEIC_JPG_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}',
      path: storedPaths.first,
      paths: storedPaths,
      sizeBytes: totalBytes,
      conversionType: ConversionType.heicToJpg,
      createdAt: stamp,
      pageCount: storedPaths.length,
    );
    return ConversionStorage.saveRecord(record);
  }

  Future<Uint8List> _encodeJpeg(SelectedImage image, int quality) async {
    final lower = image.path.toLowerCase();
    final isHeic = lower.endsWith('.heic') || lower.endsWith('.heif');
    final rotation = image.rotation % 360;

    // Native codec handles HEIC reliably on iOS/Android.
    if (isHeic) {
      final compressed = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: quality,
        format: CompressFormat.jpeg,
        rotate: rotation,
        keepExif: false,
      );
      if (compressed == null) {
        throw StateError('Could not convert HEIC ${image.path}');
      }
      return compressed;
    }

    final bytes = await File(image.path).readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) {
      final compressed = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: quality,
        format: CompressFormat.jpeg,
        rotate: rotation,
        keepExif: false,
      );
      if (compressed == null) {
        throw StateError('Could not decode image ${image.path}');
      }
      return compressed;
    }

    if (rotation != 0) {
      decoded = img.copyRotate(decoded, angle: rotation);
    }

    if (decoded.numChannels == 4) {
      final flat = img.Image(
        width: decoded.width,
        height: decoded.height,
        numChannels: 3,
      );
      img.fill(flat, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(flat, decoded);
      decoded = flat;
    }

    return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
