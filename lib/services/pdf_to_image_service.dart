import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdfx/pdfx.dart' hide PdfPageImage;

import '../models/conversion_record.dart';
import '../models/pdf_to_image_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

enum ExtractImageFormat {
  png,
  jpeg,
  bmp,
  gif;

  String get extension {
    switch (this) {
      case ExtractImageFormat.png:
        return 'png';
      case ExtractImageFormat.jpeg:
        return 'jpg';
      case ExtractImageFormat.bmp:
        return 'bmp';
      case ExtractImageFormat.gif:
        return 'gif';
    }
  }

  String get label {
    switch (this) {
      case ExtractImageFormat.png:
        return 'PNG';
      case ExtractImageFormat.jpeg:
        return 'JPG';
      case ExtractImageFormat.bmp:
        return 'BMP';
      case ExtractImageFormat.gif:
        return 'GIF';
    }
  }
}

class PdfToImageService {
  const PdfToImageService();

  /// Renders every page of [pdfPath] into PNG files under app storage.
  Future<List<PdfPageImage>> renderPdf({
    required String pdfPath,
    required String sourceName,
    required String documentId,
    ConversionProgressCallback? onProgress,
    int progressOffset = 0,
    int? progressTotal,
  }) async {
    final document = await PdfDocument.openFile(pdfPath);
    final pages = <PdfPageImage>[];
    final total = progressTotal ?? document.pagesCount;

    try {
      for (var i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        try {
          final width = (page.width * 2).clamp(600, 2000).toDouble();
          final height = (page.height * 2).clamp(600, 2800).toDouble();
          final pageImage = await page.render(
            width: width,
            height: height,
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );
          if (pageImage == null) continue;

          final stamp = DateTime.now().microsecondsSinceEpoch;
          final fileName = 'PDF_IMG_${documentId}_p${i}_$stamp.png';
          final output = await ConversionStorage.createOutputFile(fileName);
          await output.writeAsBytes(pageImage.bytes, flush: true);

          pages.add(
            PdfPageImage(
              id: '$documentId-$i-$stamp',
              path: output.path,
              sourceName: sourceName,
              pageNumber: i,
            ),
          );
        } finally {
          await page.close();
        }

        onProgress?.call(progressOffset + i, total);
        await Future<void>.delayed(const Duration(milliseconds: 8));
      }
    } finally {
      await document.close();
    }

    return pages;
  }

  Future<int> pageCount(String pdfPath) async {
    final document = await PdfDocument.openFile(pdfPath);
    try {
      return document.pagesCount;
    } finally {
      await document.close();
    }
  }

  /// Persists selected page images as one history group.
  Future<ConversionRecord> saveGroup({
    required List<PdfPageImage> pages,
    ConversionType conversionType = ConversionType.pdfToImage,
    ExtractImageFormat format = ExtractImageFormat.png,
    String namePrefix = 'PDF_IMAGES',
    ConversionProgressCallback? onProgress,
  }) async {
    if (pages.isEmpty) {
      throw StateError('No images to save');
    }

    final stamp = DateTime.now();
    final storedPaths = <String>[];
    var totalBytes = 0;
    final ext = format.extension;
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

      final encoded = switch (format) {
        ExtractImageFormat.png => img.encodePng(decoded),
        ExtractImageFormat.jpeg => img.encodeJpg(decoded, quality: 92),
        ExtractImageFormat.bmp => img.encodeBmp(decoded),
        ExtractImageFormat.gif => img.encodeGif(decoded),
      };
      final outBytes = Uint8List.fromList(encoded);

      final fileName =
          '${namePrefix}_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_'
          '${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}_$i.$ext';
      final output = await ConversionStorage.createOutputFile(fileName);
      await output.writeAsBytes(outBytes, flush: true);
      storedPaths.add(ConversionStorage.toStoredPath(output.path));
      totalBytes += await output.length();

      onProgress?.call(i + 1, total);
      await Future<void>.delayed(const Duration(milliseconds: 4));
    }

    final record = ConversionRecord(
      id: stamp.microsecondsSinceEpoch.toString(),
      name:
          '${namePrefix}_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}',
      path: storedPaths.first,
      paths: storedPaths,
      sizeBytes: totalBytes,
      conversionType: conversionType,
      createdAt: stamp,
      pageCount: storedPaths.length,
    );
    return ConversionStorage.saveRecord(record);
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
