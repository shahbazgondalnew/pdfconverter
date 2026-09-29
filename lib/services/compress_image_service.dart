import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../models/conversion_record.dart';
import '../models/image_to_pdf_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

enum ImageCompressLevel {
  low,
  medium,
  high;

  /// Higher = smaller file / lower quality.
  int get jpegQuality {
    switch (this) {
      case ImageCompressLevel.low:
        return 75;
      case ImageCompressLevel.medium:
        return 55;
      case ImageCompressLevel.high:
        return 35;
    }
  }

  int get maxDimension {
    switch (this) {
      case ImageCompressLevel.low:
        return 1920;
      case ImageCompressLevel.medium:
        return 1440;
      case ImageCompressLevel.high:
        return 1080;
    }
  }
}

class CompressImageService {
  const CompressImageService();

  Future<ConversionRecord> convert({
    required List<SelectedImage> images,
    ImageCompressLevel level = ImageCompressLevel.medium,
    ConversionProgressCallback? onProgress,
  }) async {
    if (images.isEmpty) {
      throw StateError('No images to compress');
    }

    final stamp = DateTime.now();
    final storedPaths = <String>[];
    var totalBytes = 0;
    final total = images.length;

    for (var i = 0; i < images.length; i++) {
      final image = images[i];
      final encoded = await _compress(image, level);

      final base = p.basenameWithoutExtension(image.path);
      final safeBase = base.isEmpty ? 'image' : base;
      final fileName =
          'COMPRESS_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_'
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
          'COMPRESS_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}',
      path: storedPaths.first,
      paths: storedPaths,
      sizeBytes: totalBytes,
      conversionType: ConversionType.compressImage,
      createdAt: stamp,
      pageCount: storedPaths.length,
    );
    return ConversionStorage.saveRecord(record);
  }

  Future<Uint8List> _compress(
    SelectedImage image,
    ImageCompressLevel level,
  ) async {
    final rotation = image.rotation % 360;
    final lower = image.path.toLowerCase();
    final isHeic = lower.endsWith('.heic') || lower.endsWith('.heif');

    if (isHeic) {
      final compressed = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: level.jpegQuality,
        format: CompressFormat.jpeg,
        rotate: rotation,
        minWidth: level.maxDimension,
        minHeight: level.maxDimension,
        keepExif: false,
      );
      if (compressed == null) {
        throw StateError('Could not compress ${image.path}');
      }
      return compressed;
    }

    final bytes = await File(image.path).readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) {
      final compressed = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: level.jpegQuality,
        format: CompressFormat.jpeg,
        rotate: rotation,
        minWidth: level.maxDimension,
        minHeight: level.maxDimension,
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

    final maxSide = level.maxDimension;
    if (decoded.width > maxSide || decoded.height > maxSide) {
      decoded = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxSide : null,
        height: decoded.height > decoded.width ? maxSide : null,
      );
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

    return Uint8List.fromList(
      img.encodeJpg(decoded, quality: level.jpegQuality),
    );
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
