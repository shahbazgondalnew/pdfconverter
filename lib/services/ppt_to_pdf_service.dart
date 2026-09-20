import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xml/xml.dart';

import '../models/conversion_record.dart';
import '../models/document_models.dart';
import '../models/image_to_pdf_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class PptToPdfService {
  const PptToPdfService();

  /// Parses a PowerPoint file into editable slides (pages).
  static Future<List<WordPage>> parsePages({
    required String path,
    required String documentId,
  }) async {
    final ext = p.extension(path).toLowerCase();
    final slides = await _extractSlides(path, ext);
    return [
      for (var i = 0; i < slides.length; i++)
        WordPage(
          id: '$documentId-p$i',
          index: i,
          title: slides[i].title,
          paragraphs: slides[i].paragraphs,
        ),
    ];
  }

  Future<ConversionRecord> convert({
    required List<SelectedDocument> documents,
    required PdfPageSettings settings,
    ConversionProgressCallback? onProgress,
  }) async {
    if (documents.isEmpty) {
      throw StateError('No PowerPoint files to convert');
    }

    final workItems = <({SelectedDocument doc, WordPage page})>[];
    for (final doc in documents) {
      for (final page in doc.pages) {
        workItems.add((doc: doc, page: page));
      }
    }
    if (workItems.isEmpty) {
      throw StateError('No slides to convert');
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
      final slideTitle = item.page.title ?? 'Slide ${i + 1}';

      pdf.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: layout.margin,
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(color: pdfBg),
            ),
          ),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: layout.align == pw.TextAlign.center
                  ? pw.CrossAxisAlignment.center
                  : pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${item.doc.name} · $slideTitle',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: mutedText,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                if (paragraphs.isEmpty)
                  pw.Text(
                    '(Empty slide)',
                    textAlign: layout.align,
                    style: pw.TextStyle(
                      fontSize: layout.fontSize,
                      color: mutedText,
                    ),
                  )
                else
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: layout.align == pw.TextAlign.center
                          ? pw.CrossAxisAlignment.center
                          : pw.CrossAxisAlignment.start,
                      children: [
                        for (var j = 0; j < paragraphs.length; j++)
                          pw.Padding(
                            padding: pw.EdgeInsets.only(
                              bottom: layout.paragraphGap,
                            ),
                            child: pw.Text(
                              paragraphs[j],
                              textAlign: layout.align,
                              style: pw.TextStyle(
                                fontSize: j == 0
                                    ? layout.fontSize + 4
                                    : layout.fontSize,
                                fontWeight: j == 0
                                    ? pw.FontWeight.bold
                                    : pw.FontWeight.normal,
                                lineSpacing: layout.lineSpacing,
                                color: pdfText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      );

      onProgress?.call(i + 1, total);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    final stamp = DateTime.now();
    final fileName =
        'PPT_PDF_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}.pdf';
    final output = await ConversionStorage.createOutputFile(fileName);
    await output.writeAsBytes(await pdf.save(), flush: true);

    final record = ConversionRecord(
      id: stamp.microsecondsSinceEpoch.toString(),
      name: p.basename(output.path),
      path: output.path,
      sizeBytes: await output.length(),
      conversionType: ConversionType.pptToPdf,
      createdAt: stamp,
      pageCount: pdf.document.pdfPageList.pages.length,
    );
    return ConversionStorage.saveRecord(record);
  }

  static Future<List<({String title, List<String> paragraphs})>> _extractSlides(
    String path,
    String ext,
  ) async {
    if (ext == '.pptx') {
      return _extractFromPptx(path);
    }
    return [
      (
        title: 'Slide 1',
        paragraphs: [
          'This file format ($ext) has limited support.',
          'Please use a .pptx PowerPoint file for best results.',
          'File: ${p.basename(path)}',
        ],
      ),
    ];
  }

  static Future<List<({String title, List<String> paragraphs})>>
      _extractFromPptx(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final slideFiles = archive.files
        .where(
          (file) =>
              file.name.startsWith('ppt/slides/slide') &&
              file.name.endsWith('.xml') &&
              !file.name.contains('_rels'),
        )
        .toList()
      ..sort((a, b) {
        final aNum = _slideNumber(a.name);
        final bNum = _slideNumber(b.name);
        return aNum.compareTo(bNum);
      });

    if (slideFiles.isEmpty) {
      throw StateError('Invalid PowerPoint file');
    }

    final slides = <({String title, List<String> paragraphs})>[];
    for (var i = 0; i < slideFiles.length; i++) {
      final slideFile = slideFiles[i];
      final xml = XmlDocument.parse(
        utf8.decode(slideFile.content as List<int>),
      );
      final paragraphs = <String>[];

      for (final textNode in xml.findAllElements('a:t')) {
        final text = textNode.innerText.trim();
        if (text.isNotEmpty) {
          paragraphs.add(text);
        }
      }

      // Deduplicate consecutive identical lines (common in PPT XML).
      final cleaned = <String>[];
      for (final line in paragraphs) {
        if (cleaned.isEmpty || cleaned.last != line) {
          cleaned.add(line);
        }
      }

      slides.add((
        title: 'Slide ${i + 1}',
        paragraphs: cleaned.isEmpty ? ['(Empty slide)'] : cleaned,
      ));
    }

    return slides;
  }

  static int _slideNumber(String name) {
    final match = RegExp(r'slide(\d+)\.xml').firstMatch(name);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static _PptLayout _layoutFor(ImageFitMode mode) {
    switch (mode) {
      case ImageFitMode.center:
        return const _PptLayout(
          margin: pw.EdgeInsets.all(48),
          fontSize: 14,
          lineSpacing: 1.45,
          paragraphGap: 10,
          align: pw.TextAlign.center,
        );
      case ImageFitMode.contain:
        return const _PptLayout(
          margin: pw.EdgeInsets.all(36),
          fontSize: 15,
          lineSpacing: 1.4,
          paragraphGap: 8,
          align: pw.TextAlign.left,
        );
      case ImageFitMode.cover:
        return const _PptLayout(
          margin: pw.EdgeInsets.all(20),
          fontSize: 16,
          lineSpacing: 1.35,
          paragraphGap: 6,
          align: pw.TextAlign.left,
        );
      case ImageFitMode.fill:
        return const _PptLayout(
          margin: pw.EdgeInsets.all(12),
          fontSize: 14,
          lineSpacing: 1.25,
          paragraphGap: 4,
          align: pw.TextAlign.justify,
        );
      case ImageFitMode.fitWidth:
        return const _PptLayout(
          margin: pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          fontSize: 16,
          lineSpacing: 1.4,
          paragraphGap: 8,
          align: pw.TextAlign.left,
        );
      case ImageFitMode.fitHeight:
        return const _PptLayout(
          margin: pw.EdgeInsets.symmetric(horizontal: 36, vertical: 20),
          fontSize: 17,
          lineSpacing: 1.5,
          paragraphGap: 10,
          align: pw.TextAlign.left,
        );
    }
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _PptLayout {
  const _PptLayout({
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
