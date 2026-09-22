import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;

import '../models/conversion_record.dart';
import '../models/document_models.dart';
import '../models/pdf_to_image_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';
import 'pdf_to_image_service.dart';
import 'pdf_to_word_webview_converter.dart';

class PdfToWordService {
  const PdfToWordService();

  /// Quick page count for the review grid (uses pdfx via [PdfToImageService]).
  static Future<List<WordPage>> parsePages({
    required String path,
    required String documentId,
  }) async {
    final count = await const PdfToImageService().pageCount(path);
    final safeCount = count < 1 ? 1 : count;
    return List.generate(
      safeCount,
      (i) => WordPage(
        id: '$documentId-p$i',
        index: i,
        paragraphs: const [''],
      ),
    );
  }

  /// Converts one or more PDFs into a single Word (.docx) file via WebView JS
  /// (pdf.js text extraction + docx generator; image pages for scanned PDFs).
  Future<ConversionRecord> convert({
    required List<PdfSourceFile> pdfFiles,
    ConversionProgressCallback? onProgress,
  }) async {
    if (pdfFiles.isEmpty) {
      throw StateError('No PDF files to convert');
    }

    // Wait until the progress route has an overlay (WebView host needs it).
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final pdfBytes = <Uint8List>[];
    for (final file in pdfFiles) {
      pdfBytes.add(await File(file.path).readAsBytes());
    }

    final result = await PdfToWordWebConverter.convert(
      pdfFiles: pdfBytes,
      onProgress: onProgress,
    );

    final stamp = DateTime.now();
    final fileName =
        'PDF_WORD_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}.docx';
    final output = await ConversionStorage.createOutputFile(fileName);
    await output.writeAsBytes(result.bytes, flush: true);

    final record = ConversionRecord(
      id: stamp.microsecondsSinceEpoch.toString(),
      name: p.basename(output.path),
      path: output.path,
      sizeBytes: await output.length(),
      conversionType: ConversionType.pdfToWord,
      createdAt: stamp,
      pageCount: result.pageCount > 0 ? result.pageCount : pdfFiles.length,
    );
    return ConversionStorage.saveRecord(record);
  }

  Future<ConversionRecord> convertDocuments({
    required List<SelectedDocument> documents,
    ConversionProgressCallback? onProgress,
  }) {
    final files = documents
        .map(
          (doc) => PdfSourceFile(
            id: doc.id,
            path: doc.path,
            name: doc.name,
          ),
        )
        .toList();
    return convert(pdfFiles: files, onProgress: onProgress);
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
