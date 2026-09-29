import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/conversion_record.dart';
import '../models/pdf_to_image_models.dart';
import '../models/sign_pdf_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class SignPdfService {
  const SignPdfService();

  Future<ConversionRecord> sign({
    required PdfSourceFile file,
    required Uint8List signaturePng,
    required SignPdfSettings settings,
    ConversionProgressCallback? onProgress,
  }) async {
    if (signaturePng.isEmpty) {
      throw StateError('Add a signature first');
    }

    final input = File(file.path);
    if (!await input.exists()) {
      throw StateError('PDF file not found');
    }

    late final PdfDocument document;
    try {
      document = PdfDocument(inputBytes: await input.readAsBytes());
    } catch (_) {
      throw StateError(
        'This PDF is password protected or could not be opened',
      );
    }

    try {
      final bitmap = PdfBitmap(signaturePng);
      final total = document.pages.count;
      if (total == 0) {
        throw StateError('PDF has no pages');
      }

      final decoded = await _decodePngSize(signaturePng);
      final aspect = decoded.height == 0
          ? 0.35
          : decoded.width / decoded.height;

      for (var i = 0; i < total; i++) {
        if (!settings.shouldApply(i, total)) {
          onProgress?.call(i + 1, total);
          continue;
        }

        final page = document.pages[i];
        final pageSize = page.size;
        final margin = 28.0;
        final maxWidth =
            (pageSize.width - margin * 2) * settings.scale.clamp(0.1, 0.6);
        final sigWidth = maxWidth;
        final sigHeight = sigWidth / aspect.clamp(0.5, 4.0);

        final origin = _origin(
          position: settings.position,
          pageWidth: pageSize.width,
          pageHeight: pageSize.height,
          sigWidth: sigWidth,
          sigHeight: sigHeight,
          margin: margin,
        );

        page.graphics.drawImage(
          bitmap,
          Rect.fromLTWH(origin.dx, origin.dy, sigWidth, sigHeight),
        );

        onProgress?.call(i + 1, total);
        await Future<void>.delayed(const Duration(milliseconds: 4));
      }

      final bytes = await document.save();
      final stamp = DateTime.now();
      final base = p.basenameWithoutExtension(file.name);
      final safeBase = base.isEmpty ? 'document' : base;
      final fileName =
          'SIGNED_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_'
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
        conversionType: ConversionType.signPdf,
        createdAt: stamp,
        pageCount: total,
      );
      return ConversionStorage.saveRecord(record);
    } finally {
      document.dispose();
    }
  }

  Offset _origin({
    required SignPdfPosition position,
    required double pageWidth,
    required double pageHeight,
    required double sigWidth,
    required double sigHeight,
    required double margin,
  }) {
    switch (position) {
      case SignPdfPosition.bottomRight:
        return Offset(
          pageWidth - sigWidth - margin,
          pageHeight - sigHeight - margin,
        );
      case SignPdfPosition.bottomLeft:
        return Offset(margin, pageHeight - sigHeight - margin);
      case SignPdfPosition.bottomCenter:
        return Offset(
          (pageWidth - sigWidth) / 2,
          pageHeight - sigHeight - margin,
        );
      case SignPdfPosition.topRight:
        return Offset(pageWidth - sigWidth - margin, margin);
      case SignPdfPosition.topLeft:
        return Offset(margin, margin);
      case SignPdfPosition.center:
        return Offset(
          (pageWidth - sigWidth) / 2,
          (pageHeight - sigHeight) / 2,
        );
    }
  }

  Future<Size> _decodePngSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    return size;
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
