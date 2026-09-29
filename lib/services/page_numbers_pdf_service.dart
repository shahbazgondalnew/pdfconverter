import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/conversion_record.dart';
import '../models/page_number_models.dart';
import '../models/pdf_to_image_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class PageNumbersPdfService {
  const PageNumbersPdfService();

  Future<ConversionRecord> apply({
    required List<PdfPageImage> pages,
    required PageNumberSettings settings,
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

      const maxDimension = 2200;
      if (decoded.width > maxDimension || decoded.height > maxDimension) {
        decoded = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxDimension : null,
          height: decoded.height > decoded.width ? maxDimension : null,
        );
      }

      final imageWidth = decoded.width.toDouble();
      final imageHeight = decoded.height.toDouble();
      final jpeg = Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
      final pdfImage = pw.MemoryImage(jpeg);
      final pageFormat = PdfPageFormat(imageWidth, imageHeight);
      final label = settings.labelFor(i, total);

      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Stack(
              children: [
                pw.Positioned.fill(
                  child: pw.Image(pdfImage, fit: pw.BoxFit.fill),
                ),
                if (label.isNotEmpty)
                  pw.Positioned.fill(
                    child: pw.Align(
                      alignment: _alignment(settings.position),
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(28),
                        child: pw.Text(
                          label,
                          style: pw.TextStyle(
                            fontSize: settings.fontSize,
                            fontWeight: settings.bold
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                            color: _pdfColor(settings.colorValue),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );

      onProgress?.call(i + 1, total);
      await Future<void>.delayed(const Duration(milliseconds: 12));
    }

    final stamp = DateTime.now();
    final fileName =
        'PAGE_NUM_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_'
        '${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}.pdf';
    final output = await ConversionStorage.createOutputFile(fileName);
    await output.writeAsBytes(await document.save(), flush: true);

    final stored = ConversionStorage.toStoredPath(output.path);
    final record = ConversionRecord(
      id: stamp.microsecondsSinceEpoch.toString(),
      name: p.basename(output.path),
      path: stored,
      paths: [stored],
      sizeBytes: await output.length(),
      conversionType: ConversionType.pageNumbersPdf,
      createdAt: stamp,
      pageCount: total,
    );
    return ConversionStorage.saveRecord(record);
  }

  pw.Alignment _alignment(PageNumberPosition position) {
    switch (position) {
      case PageNumberPosition.topLeft:
        return pw.Alignment.topLeft;
      case PageNumberPosition.topCenter:
        return pw.Alignment.topCenter;
      case PageNumberPosition.topRight:
        return pw.Alignment.topRight;
      case PageNumberPosition.bottomLeft:
        return pw.Alignment.bottomLeft;
      case PageNumberPosition.bottomCenter:
        return pw.Alignment.bottomCenter;
      case PageNumberPosition.bottomRight:
        return pw.Alignment.bottomRight;
    }
  }

  PdfColor _pdfColor(int argb) {
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;
    return PdfColor(r, g, b);
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
