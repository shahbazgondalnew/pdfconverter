import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/conversion_record.dart';
import '../models/image_to_pdf_models.dart';
import 'conversion_storage.dart';

typedef ConversionProgressCallback = void Function(int completed, int total);

class ImageToPdfService {
  const ImageToPdfService();

  Future<ConversionRecord> convert({
    required List<SelectedImage> images,
    required PdfPageSettings settings,
    ConversionProgressCallback? onProgress,
  }) async {
    if (images.isEmpty) {
      throw StateError('No images to convert');
    }

    final document = pw.Document();
    final total = images.length;
    final bg = settings.backgroundColor;
    final pdfBg = PdfColor(bg.r, bg.g, bg.b, bg.a);

    for (var i = 0; i < images.length; i++) {
      final selected = images[i];
      final bytes = await File(selected.path).readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw StateError('Could not decode image ${selected.path}');
      }

      if (selected.rotation % 360 != 0) {
        decoded = img.copyRotate(decoded, angle: selected.rotation);
      }

      if (decoded.width > 2000 || decoded.height > 2000) {
        decoded = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? 2000 : null,
          height: decoded.height > decoded.width ? 2000 : null,
        );
      }

      final imageWidth = decoded.width.toDouble();
      final imageHeight = decoded.height.toDouble();
      final jpeg = Uint8List.fromList(img.encodeJpg(decoded, quality: 88));
      final pdfImage = pw.MemoryImage(jpeg);
      final fitMode = settings.fitMode;

      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Container(
              width: double.infinity,
              height: double.infinity,
              color: pdfBg,
              alignment: pw.Alignment.center,
              child: _buildFittedImage(
                pdfImage,
                fitMode,
                imageWidth,
                imageHeight,
              ),
            );
          },
        ),
      );

      onProgress?.call(i + 1, total);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    final stamp = DateTime.now();
    final fileName =
        'IMG_PDF_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}.pdf';
    final output = await ConversionStorage.createOutputFile(fileName);
    final pdfBytes = await document.save();
    await output.writeAsBytes(pdfBytes, flush: true);

    final record = ConversionRecord(
      id: stamp.microsecondsSinceEpoch.toString(),
      name: p.basename(output.path),
      path: output.path,
      sizeBytes: await output.length(),
      conversionType: ConversionType.imageToPdf,
      createdAt: stamp,
      pageCount: total,
    );

    return ConversionStorage.saveRecord(record);
  }

  pw.Widget _buildFittedImage(
    pw.MemoryImage image,
    ImageFitMode fitMode,
    double imageWidth,
    double imageHeight,
  ) {
    final pageWidth = PdfPageFormat.a4.width;
    final pageHeight = PdfPageFormat.a4.height;

    switch (fitMode) {
      case ImageFitMode.center:
        return pw.Image(
          image,
          width: imageWidth.clamp(0, pageWidth),
          height: imageHeight.clamp(0, pageHeight),
          fit: pw.BoxFit.none,
        );
      case ImageFitMode.contain:
        return pw.Image(image, fit: pw.BoxFit.contain);
      case ImageFitMode.cover:
        return pw.SizedBox(
          width: pageWidth,
          height: pageHeight,
          child: pw.Image(image, fit: pw.BoxFit.cover),
        );
      case ImageFitMode.fill:
        return pw.SizedBox(
          width: pageWidth,
          height: pageHeight,
          child: pw.Image(image, fit: pw.BoxFit.fill),
        );
      case ImageFitMode.fitWidth:
        return pw.Image(image, fit: pw.BoxFit.fitWidth);
      case ImageFitMode.fitHeight:
        return pw.Image(image, fit: pw.BoxFit.fitHeight);
    }
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
