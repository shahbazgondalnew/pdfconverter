import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/conversion_record.dart';
import '../models/pdf_to_image_models.dart';
import '../models/watermark_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class WatermarkPdfService {
  const WatermarkPdfService();

  Future<ConversionRecord> apply({
    required List<PdfPageImage> pages,
    required WatermarkSettings settings,
    ConversionProgressCallback? onProgress,
  }) async {
    if (pages.isEmpty) {
      throw StateError('No pages to convert');
    }
    if (!settings.hasContent) {
      throw StateError('Add watermark text or an image');
    }

    pw.MemoryImage? watermarkImage;
    if (settings.type == WatermarkType.image) {
      final path = settings.imagePath;
      if (path == null) {
        throw StateError('Add watermark text or an image');
      }
      final bytes = await File(path).readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw StateError('Could not decode watermark image');
      }
      const maxSide = 1200;
      if (decoded.width > maxSide || decoded.height > maxSide) {
        decoded = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxSide : null,
          height: decoded.height > decoded.width ? maxSide : null,
        );
      }
      watermarkImage = pw.MemoryImage(
        Uint8List.fromList(img.encodePng(decoded)),
      );
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
      final applyMark = settings.shouldApply(i, total);

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
                if (applyMark)
                  pw.Positioned.fill(
                    child: _buildWatermarkLayer(
                      settings: settings,
                      pageWidth: imageWidth,
                      pageHeight: imageHeight,
                      watermarkImage: watermarkImage,
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
        'WATERMARK_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_'
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
      conversionType: ConversionType.watermarkPdf,
      createdAt: stamp,
      pageCount: total,
    );
    return ConversionStorage.saveRecord(record);
  }

  pw.Widget _buildWatermarkLayer({
    required WatermarkSettings settings,
    required double pageWidth,
    required double pageHeight,
    required pw.MemoryImage? watermarkImage,
  }) {
    final mark = _markWidget(
      settings: settings,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      watermarkImage: watermarkImage,
    );

    if (settings.layout == WatermarkLayout.tiled) {
      const alignments = <pw.Alignment>[
        pw.Alignment.topLeft,
        pw.Alignment.topCenter,
        pw.Alignment.topRight,
        pw.Alignment.centerLeft,
        pw.Alignment.center,
        pw.Alignment.centerRight,
        pw.Alignment.bottomLeft,
        pw.Alignment.bottomCenter,
        pw.Alignment.bottomRight,
      ];
      return pw.Opacity(
        opacity: settings.opacity.clamp(0.05, 1.0),
        child: pw.Stack(
          children: [
            for (final alignment in alignments)
              pw.Positioned.fill(
                child: pw.Align(
                  alignment: alignment,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(28),
                    child: pw.Transform.rotateBox(
                      angle: settings.rotation * math.pi / 180,
                      child: mark,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return pw.Opacity(
      opacity: settings.opacity.clamp(0.05, 1.0),
      child: pw.Align(
        alignment: _alignment(settings.position),
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(36),
          child: pw.Transform.rotateBox(
            angle: settings.rotation * math.pi / 180,
            child: mark,
          ),
        ),
      ),
    );
  }

  pw.Widget _markWidget({
    required WatermarkSettings settings,
    required double pageWidth,
    required double pageHeight,
    required pw.MemoryImage? watermarkImage,
  }) {
    if (settings.type == WatermarkType.image && watermarkImage != null) {
      final targetWidth = pageWidth * settings.imageScale.clamp(0.1, 0.9);
      return pw.SizedBox(
        width: targetWidth,
        child: pw.Image(watermarkImage, fit: pw.BoxFit.contain),
      );
    }

    return pw.Text(
      settings.text.trim(),
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(
        fontSize: settings.fontSize,
        fontWeight:
            settings.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: _pdfColor(settings.colorValue),
      ),
    );
  }

  pw.Alignment _alignment(WatermarkPosition position) {
    switch (position) {
      case WatermarkPosition.center:
        return pw.Alignment.center;
      case WatermarkPosition.topLeft:
        return pw.Alignment.topLeft;
      case WatermarkPosition.topCenter:
        return pw.Alignment.topCenter;
      case WatermarkPosition.topRight:
        return pw.Alignment.topRight;
      case WatermarkPosition.bottomLeft:
        return pw.Alignment.bottomLeft;
      case WatermarkPosition.bottomCenter:
        return pw.Alignment.bottomCenter;
      case WatermarkPosition.bottomRight:
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
