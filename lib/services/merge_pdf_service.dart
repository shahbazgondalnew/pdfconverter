import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/conversion_record.dart';
import '../models/pdf_to_image_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

enum PdfCompressLevel {
  low,
  medium,
  high;

  /// Higher = smaller file / lower quality.
  int get jpegQuality {
    switch (this) {
      case PdfCompressLevel.low:
        return 75;
      case PdfCompressLevel.medium:
        return 55;
      case PdfCompressLevel.high:
        return 35;
    }
  }

  int get maxDimension {
    switch (this) {
      case PdfCompressLevel.low:
        return 1600;
      case PdfCompressLevel.medium:
        return 1200;
      case PdfCompressLevel.high:
        return 900;
    }
  }
}

/// Builds a PDF from ordered page images (merge / split / compress).
class PagesToPdfService {
  const PagesToPdfService();

  Future<ConversionRecord> create({
    required List<PdfPageImage> pages,
    required ConversionType conversionType,
    required String filePrefix,
    int jpegQuality = 90,
    int maxDimension = 2400,
    ConversionProgressCallback? onProgress,
  }) async {
    if (pages.isEmpty) {
      throw StateError('No pages to convert');
    }

    final document = pw.Document();
    final total = pages.length;

    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final bytes = await File(page.path).readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw StateError('Could not decode page ${page.path}');
      }

      if (page.rotation % 360 != 0) {
        decoded = img.copyRotate(decoded, angle: page.rotation);
      }

      if (decoded.width > maxDimension || decoded.height > maxDimension) {
        decoded = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxDimension : null,
          height: decoded.height > decoded.width ? maxDimension : null,
        );
      }

      final imageWidth = decoded.width.toDouble();
      final imageHeight = decoded.height.toDouble();
      final jpeg =
          Uint8List.fromList(img.encodeJpg(decoded, quality: jpegQuality));
      final pdfImage = pw.MemoryImage(jpeg);
      final pageFormat = PdfPageFormat(imageWidth, imageHeight);

      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Image(pdfImage, fit: pw.BoxFit.fill);
          },
        ),
      );

      onProgress?.call(i + 1, total);
      await Future<void>.delayed(const Duration(milliseconds: 12));
    }

    final stamp = DateTime.now();
    final fileName =
        '${filePrefix}_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}.pdf';
    final output = await ConversionStorage.createOutputFile(fileName);
    final pdfBytes = await document.save();
    await output.writeAsBytes(pdfBytes, flush: true);

    final stored = ConversionStorage.toStoredPath(output.path);
    final record = ConversionRecord(
      id: stamp.microsecondsSinceEpoch.toString(),
      name: p.basename(output.path),
      path: stored,
      paths: [stored],
      sizeBytes: await output.length(),
      conversionType: conversionType,
      createdAt: stamp,
      pageCount: total,
    );
    return ConversionStorage.saveRecord(record);
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class MergePdfService {
  const MergePdfService();

  Future<ConversionRecord> merge({
    required List<PdfPageImage> pages,
    ConversionProgressCallback? onProgress,
  }) {
    return const PagesToPdfService().create(
      pages: pages,
      conversionType: ConversionType.mergePdf,
      filePrefix: 'MERGE_PDF',
      onProgress: onProgress,
    );
  }
}

class SplitPdfService {
  const SplitPdfService();

  Future<ConversionRecord> split({
    required List<PdfPageImage> pages,
    ConversionProgressCallback? onProgress,
  }) {
    return const PagesToPdfService().create(
      pages: pages,
      conversionType: ConversionType.splitPdf,
      filePrefix: 'SPLIT_PDF',
      onProgress: onProgress,
    );
  }
}

class CompressPdfService {
  const CompressPdfService();

  Future<ConversionRecord> compress({
    required List<PdfPageImage> pages,
    required PdfCompressLevel level,
    ConversionProgressCallback? onProgress,
  }) {
    return const PagesToPdfService().create(
      pages: pages,
      conversionType: ConversionType.compressPdf,
      filePrefix: 'COMPRESS_PDF',
      jpegQuality: level.jpegQuality,
      maxDimension: level.maxDimension,
      onProgress: onProgress,
    );
  }
}

class RotatePdfService {
  const RotatePdfService();

  Future<ConversionRecord> rotate({
    required List<PdfPageImage> pages,
    ConversionProgressCallback? onProgress,
  }) {
    return const PagesToPdfService().create(
      pages: pages,
      conversionType: ConversionType.rotatePdf,
      filePrefix: 'ROTATE_PDF',
      onProgress: onProgress,
    );
  }
}

class ReorderPdfService {
  const ReorderPdfService();

  Future<ConversionRecord> reorder({
    required List<PdfPageImage> pages,
    ConversionProgressCallback? onProgress,
  }) {
    return const PagesToPdfService().create(
      pages: pages,
      conversionType: ConversionType.reorderPdf,
      filePrefix: 'REORDER_PDF',
      onProgress: onProgress,
    );
  }
}

class DeletePagesPdfService {
  const DeletePagesPdfService();

  Future<ConversionRecord> deletePages({
    required List<PdfPageImage> pages,
    ConversionProgressCallback? onProgress,
  }) {
    return const PagesToPdfService().create(
      pages: pages,
      conversionType: ConversionType.deletePagesPdf,
      filePrefix: 'DELETE_PAGES_PDF',
      onProgress: onProgress,
    );
  }
}
