import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../models/conversion_record.dart';
import '../models/image_to_pdf_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class JpgToPngService {
  const JpgToPngService();

  Future<ConversionRecord> convert({
    required List<SelectedImage> images,
    ConversionProgressCallback? onProgress,
  }) async {
    if (images.isEmpty) {
      throw StateError('No images to convert');
    }

    final stamp = DateTime.now();
    final storedPaths = <String>[];
    var totalBytes = 0;
    final total = images.length;

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

      final encoded = Uint8List.fromList(img.encodePng(decoded));

      final base = p.basenameWithoutExtension(image.path);
      final safeBase = base.isEmpty ? 'image' : base;
      final fileName =
          'JPG_PNG_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_'
          '${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}_'
          '${i}_$safeBase.png';
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
          'JPG_PNG_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}',
      path: storedPaths.first,
      paths: storedPaths,
      sizeBytes: totalBytes,
      conversionType: ConversionType.jpgToPng,
      createdAt: stamp,
      pageCount: storedPaths.length,
    );
    return ConversionStorage.saveRecord(record);
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
