import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/conversion_record.dart';
import '../models/pdf_to_image_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class LockPdfService {
  const LockPdfService();

  Future<ConversionRecord> lock({
    required PdfSourceFile file,
    required String password,
    ConversionProgressCallback? onProgress,
  }) async {
    final trimmed = password.trim();
    if (trimmed.isEmpty) {
      throw StateError('Enter a password');
    }
    if (trimmed.length < 4) {
      throw StateError('Password must be at least 4 characters');
    }

    onProgress?.call(0, 1);

    final input = File(file.path);
    if (!await input.exists()) {
      throw StateError('PDF file not found');
    }

    late final PdfDocument document;
    try {
      document = PdfDocument(inputBytes: await input.readAsBytes());
    } catch (_) {
      throw StateError(
        'This PDF is already protected or could not be opened',
      );
    }

    try {
      document.security.userPassword = trimmed;
      document.security.ownerPassword = trimmed;
      document.security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
      // Restrict editing / copying when locked with owner password.
      document.security.permissions.clear();
      document.security.permissions.addAll([
        PdfPermissionsFlags.print,
      ]);

      final bytes = await document.save();
      onProgress?.call(1, 1);

      final stamp = DateTime.now();
      final base = p.basenameWithoutExtension(file.name);
      final safeBase = base.isEmpty ? 'document' : base;
      final fileName =
          'LOCKED_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_'
          '${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}_'
          '$safeBase.pdf';
      final output = await ConversionStorage.createOutputFile(fileName);
      await output.writeAsBytes(Uint8List.fromList(bytes), flush: true);

      final stored = ConversionStorage.toStoredPath(output.path);
      final record = ConversionRecord(
        id: stamp.microsecondsSinceEpoch.toString(),
        name: p.basename(output.path),
        path: stored,
        paths: [stored],
        sizeBytes: await output.length(),
        conversionType: ConversionType.lockPdf,
        createdAt: stamp,
        pageCount: document.pages.count,
      );
      return ConversionStorage.saveRecord(record);
    } finally {
      document.dispose();
    }
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
