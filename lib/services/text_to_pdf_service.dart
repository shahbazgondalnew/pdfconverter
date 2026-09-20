import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/conversion_record.dart';
import '../models/document_models.dart';
import '../models/image_to_pdf_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class TextToPdfService {
  const TextToPdfService();

  static List<WordPage> pagesFromText({
    required String text,
    required String documentId,
    String? title,
  }) {
    final paragraphs = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trimRight())
        .toList();

    // Keep blank lines as paragraph breaks by collapsing runs of empties.
    final cleaned = <String>[];
    for (final line in paragraphs) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        if (cleaned.isNotEmpty && cleaned.last.isNotEmpty) {
          cleaned.add('');
        }
      } else {
        cleaned.add(trimmed);
      }
    }
    while (cleaned.isNotEmpty && cleaned.last.isEmpty) {
      cleaned.removeLast();
    }

    final segments = _chunkParagraphs(
      cleaned.isEmpty ? ['(Empty text)'] : cleaned,
    );
    return [
      for (var i = 0; i < segments.length; i++)
        WordPage(
          id: '$documentId-p$i',
          index: i,
          title: title,
          paragraphs: segments[i].where((line) => line.isNotEmpty).toList(),
        ),
    ];
  }

  static Future<List<WordPage>> parseFile({
    required String path,
    required String documentId,
  }) async {
    final text = await File(path).readAsString();
    return pagesFromText(
      text: text,
      documentId: documentId,
      title: p.basename(path),
    );
  }

  Future<ConversionRecord> convert({
    required List<SelectedDocument> documents,
    required PdfPageSettings settings,
    ConversionProgressCallback? onProgress,
  }) async {
    if (documents.isEmpty) {
      throw StateError('No text content to convert');
    }

    final workItems = <({SelectedDocument doc, WordPage page})>[];
    for (final doc in documents) {
      for (final page in doc.pages) {
        workItems.add((doc: doc, page: page));
      }
    }
    if (workItems.isEmpty) {
      throw StateError('No text pages to convert');
    }

    final pdf = pw.Document();
    final total = workItems.length;
    final bg = settings.backgroundColor;
    final pdfBg = PdfColor(bg.r, bg.g, bg.b, bg.a);
    final textColor = settings.contrastingTextColor;
    final pdfText = PdfColor(textColor.r, textColor.g, textColor.b, textColor.a);
    final layout = _layoutFor(settings.fitMode);
    final mutedText = PdfColor(
      pdfText.red,
      pdfText.green,
      pdfText.blue,
      0.55,
    );

    for (var i = 0; i < workItems.length; i++) {
      final item = workItems[i];
      final paragraphs = item.page.paragraphs;

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: layout.margin,
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(color: pdfBg),
            ),
          ),
          maxPages: 40,
          header: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Text(
              item.page.title ?? item.doc.name,
              style: pw.TextStyle(
                fontSize: 10,
                color: mutedText,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          build: (context) {
            if (paragraphs.isEmpty) {
              return [
                pw.Text(
                  '(Empty page)',
                  textAlign: layout.align,
                  style: pw.TextStyle(
                    fontSize: layout.fontSize,
                    color: mutedText,
                  ),
                ),
              ];
            }
            return [
              for (final line in paragraphs)
                pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: layout.paragraphGap),
                  child: pw.Text(
                    line,
                    textAlign: layout.align,
                    style: pw.TextStyle(
                      fontSize: layout.fontSize,
                      lineSpacing: layout.lineSpacing,
                      color: pdfText,
                    ),
                  ),
                ),
            ];
          },
        ),
      );

      onProgress?.call(i + 1, total);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    final stamp = DateTime.now();
    final fileName =
        'TEXT_PDF_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}.pdf';
    final output = await ConversionStorage.createOutputFile(fileName);
    await output.writeAsBytes(await pdf.save(), flush: true);

    final record = ConversionRecord(
      id: stamp.microsecondsSinceEpoch.toString(),
      name: p.basename(output.path),
      path: output.path,
      sizeBytes: await output.length(),
      conversionType: ConversionType.textToPdf,
      createdAt: stamp,
      pageCount: pdf.document.pdfPageList.pages.length,
    );
    return ConversionStorage.saveRecord(record);
  }

  static List<List<String>> _chunkParagraphs(List<String> paragraphs) {
    const maxParagraphs = 32;
    const maxChars = 2400;
    final pages = <List<String>>[];
    var current = <String>[];
    var chars = 0;

    for (final line in paragraphs) {
      final nextChars = chars + line.length;
      if (current.isNotEmpty &&
          (current.length >= maxParagraphs || nextChars > maxChars)) {
        pages.add(current);
        current = <String>[];
        chars = 0;
      }
      current.add(line);
      chars += line.length;
    }
    if (current.isNotEmpty) {
      pages.add(current);
    }
    return pages.isEmpty
        ? [
            ['(Empty text)'],
          ]
        : pages;
  }

  static _TextLayout _layoutFor(ImageFitMode mode) {
    switch (mode) {
      case ImageFitMode.center:
        return const _TextLayout(
          margin: pw.EdgeInsets.all(56),
          fontSize: 11,
          lineSpacing: 1.5,
          paragraphGap: 10,
          align: pw.TextAlign.center,
        );
      case ImageFitMode.contain:
        return const _TextLayout(
          margin: pw.EdgeInsets.all(40),
          fontSize: 12,
          lineSpacing: 1.4,
          paragraphGap: 8,
          align: pw.TextAlign.left,
        );
      case ImageFitMode.cover:
        return const _TextLayout(
          margin: pw.EdgeInsets.all(20),
          fontSize: 13,
          lineSpacing: 1.35,
          paragraphGap: 6,
          align: pw.TextAlign.left,
        );
      case ImageFitMode.fill:
        return const _TextLayout(
          margin: pw.EdgeInsets.all(12),
          fontSize: 11,
          lineSpacing: 1.25,
          paragraphGap: 4,
          align: pw.TextAlign.justify,
        );
      case ImageFitMode.fitWidth:
        return const _TextLayout(
          margin: pw.EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          fontSize: 13,
          lineSpacing: 1.4,
          paragraphGap: 8,
          align: pw.TextAlign.left,
        );
      case ImageFitMode.fitHeight:
        return const _TextLayout(
          margin: pw.EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          fontSize: 14,
          lineSpacing: 1.55,
          paragraphGap: 10,
          align: pw.TextAlign.left,
        );
    }
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _TextLayout {
  const _TextLayout({
    required this.margin,
    required this.fontSize,
    required this.lineSpacing,
    required this.paragraphGap,
    required this.align,
  });

  final pw.EdgeInsets margin;
  final double fontSize;
  final double lineSpacing;
  final double paragraphGap;
  final pw.TextAlign align;
}
