import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../models/conversion_record.dart';
import '../models/image_to_pdf_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class PngToJpgService {
  const PngToJpgService();

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
      final bytes = await File(image.path).readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw StateError('Could not decode image ${image.path}');
      }

      if (image.rotation % 360 != 0) {
        decoded = img.copyRotate(decoded, angle: image.rotation);
      }

      // JPG has no alpha — flatten transparent pixels onto white.
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

      final encoded = Uint8List.fromList(
        img.encodeJpg(decoded, quality: jpgQuality),
      );

      final base = p.basenameWithoutExtension(image.path);
      final safeBase = base.isEmpty ? 'image' : base;
      final fileName =
          'PNG_JPG_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_'
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
          'PNG_JPG_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}',
      path: storedPaths.first,
      paths: storedPaths,
      sizeBytes: totalBytes,
      conversionType: ConversionType.pngToJpg,
      createdAt: stamp,
      pageCount: storedPaths.length,
    );
    return ConversionStorage.saveRecord(record);
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
