import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/conversion_record.dart';
import '../models/pdf_to_image_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class UnlockPdfService {
  const UnlockPdfService();

  Future<ConversionRecord> unlock({
    required PdfSourceFile file,
    required String password,
    ConversionProgressCallback? onProgress,
  }) async {
    final trimmed = password.trim();
    if (trimmed.isEmpty) {
      throw StateError('Enter the PDF password');
    }

    onProgress?.call(0, 1);

    final input = File(file.path);
    if (!await input.exists()) {
      throw StateError('PDF file not found');
    }

    final bytes = await input.readAsBytes();

    late final PdfDocument document;
    try {
      document = PdfDocument(inputBytes: bytes, password: trimmed);
    } catch (_) {
      throw StateError('Incorrect password or could not open PDF');
    }

    try {
      document.security.userPassword = '';
      document.security.ownerPassword = '';
      document.security.permissions.addAll([
        PdfPermissionsFlags.print,
        PdfPermissionsFlags.editContent,
        PdfPermissionsFlags.copyContent,
        PdfPermissionsFlags.editAnnotations,
        PdfPermissionsFlags.fillFields,
        PdfPermissionsFlags.assembleDocument,
        PdfPermissionsFlags.fullQualityPrint,
      ]);

      final unlocked = await document.save();
      onProgress?.call(1, 1);

      final stamp = DateTime.now();
      final base = p.basenameWithoutExtension(file.name);
      final safeBase = base.isEmpty ? 'document' : base;
      final fileName =
          'UNLOCKED_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_'
          '${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}_'
          '$safeBase.pdf';
      final output = await ConversionStorage.createOutputFile(fileName);
      await output.writeAsBytes(Uint8List.fromList(unlocked), flush: true);

      final stored = ConversionStorage.toStoredPath(output.path);
      final record = ConversionRecord(
        id: stamp.microsecondsSinceEpoch.toString(),
        name: p.basename(output.path),
        path: stored,
        paths: [stored],
        sizeBytes: await output.length(),
        conversionType: ConversionType.unlockPdf,
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
