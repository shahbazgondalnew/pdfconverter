import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../models/conversion_record.dart';
import '../models/image_to_pdf_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class CropImageService {
  const CropImageService();

  Future<ConversionRecord> save({
    required List<SelectedImage> images,
    ConversionProgressCallback? onProgress,
  }) async {
    if (images.isEmpty) {
      throw StateError('No images to save');
    }

    final stamp = DateTime.now();
    final storedPaths = <String>[];
    var totalBytes = 0;
    final total = images.length;

    for (var i = 0; i < images.length; i++) {
      final image = images[i];
      final encoded = await _encode(image);
      final ext = _outputExtension(image.path);

      final base = p.basenameWithoutExtension(image.path);
      final safeBase = base.isEmpty ? 'image' : base;
      final fileName =
          'CROP_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_'
          '${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}_'
          '${i}_$safeBase.$ext';
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
          'CROP_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}',
      path: storedPaths.first,
      paths: storedPaths,
      sizeBytes: totalBytes,
      conversionType: ConversionType.cropImage,
      createdAt: stamp,
      pageCount: storedPaths.length,
    );
    return ConversionStorage.saveRecord(record);
  }

  String _outputExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'png';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'jpg';
    return 'jpg';
  }

  Future<Uint8List> _encode(SelectedImage image) async {
    final rotation = image.rotation % 360;
    final lower = image.path.toLowerCase();
    final preferPng = lower.endsWith('.png') || lower.endsWith('.webp');
    final isHeic = lower.endsWith('.heic') || lower.endsWith('.heif');

    if (isHeic) {
      final compressed = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: 95,
        format: CompressFormat.jpeg,
        rotate: rotation,
        keepExif: false,
      );
      if (compressed == null) {
        throw StateError('Could not process ${image.path}');
      }
      return compressed;
    }

    final bytes = await File(image.path).readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) {
      final compressed = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: 95,
        format: preferPng ? CompressFormat.png : CompressFormat.jpeg,
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

    if (preferPng) {
      return Uint8List.fromList(img.encodePng(decoded));
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

    return Uint8List.fromList(img.encodeJpg(decoded, quality: 95));
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
