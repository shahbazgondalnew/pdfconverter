import 'dart:io';

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/conversion_record.dart';
import '../models/document_models.dart';
import '../models/image_to_pdf_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class HtmlToPdfService {
  const HtmlToPdfService();

  static List<WordPage> pagesFromHtml({
    required String html,
    required String documentId,
    String? title,
  }) {
    final blocks = _extractBlocks(html);
    if (blocks.isEmpty) {
      blocks.add((text: '(Empty HTML)', kind: 'p'));
    }

    final chunks = _chunkBlocks(blocks);
    return [
      for (var i = 0; i < chunks.length; i++)
        WordPage(
          id: '$documentId-p$i',
          index: i,
          title: title,
          paragraphs: chunks[i].map((b) => b.text).toList(),
          blockKinds: chunks[i].map((b) => b.kind).toList(),
        ),
    ];
  }

  static Future<List<WordPage>> parseFile({
    required String path,
    required String documentId,
  }) async {
    final html = await File(path).readAsString();
    return pagesFromHtml(
      html: html,
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
      throw StateError('No HTML content to convert');
    }

    final workItems = <({SelectedDocument doc, WordPage page})>[];
    for (final doc in documents) {
      for (final page in doc.pages) {
        workItems.add((doc: doc, page: page));
      }
    }
    if (workItems.isEmpty) {
      throw StateError('No HTML pages to convert');
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
          maxPages: 50,
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
                  style: pw.TextStyle(
                    fontSize: layout.fontSize,
                    color: mutedText,
                  ),
                ),
              ];
            }

            return [
              for (var j = 0; j < paragraphs.length; j++)
                pw.Padding(
                  padding: pw.EdgeInsets.only(
                    bottom: _gapFor(item.page.kindAt(j), layout.paragraphGap),
                  ),
                  child: pw.Text(
                    _prefixFor(item.page.kindAt(j)) + paragraphs[j],
                    textAlign: layout.align,
                    style: pw.TextStyle(
                      fontSize: _sizeFor(
                        item.page.kindAt(j),
                        layout.fontSize,
                      ),
                      lineSpacing: layout.lineSpacing,
                      fontWeight: _isHeading(item.page.kindAt(j))
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                      color: pdfText,
                      font: item.page.kindAt(j) == 'pre'
                          ? pw.Font.courier()
                          : null,
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
        'HTML_PDF_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}.pdf';
    final output = await ConversionStorage.createOutputFile(fileName);
    await output.writeAsBytes(await pdf.save(), flush: true);

    final record = ConversionRecord(
      id: stamp.microsecondsSinceEpoch.toString(),
      name: p.basename(output.path),
      path: output.path,
      sizeBytes: await output.length(),
      conversionType: ConversionType.htmlToPdf,
      createdAt: stamp,
      pageCount: pdf.document.pdfPageList.pages.length,
    );
    return ConversionStorage.saveRecord(record);
  }

  static List<({String text, String kind})> _extractBlocks(String html) {
    final document = html_parser.parse(html);
    final root = document.body ?? document.documentElement;
    final blocks = <({String text, String kind})>[];
    if (root == null) return blocks;
    _walk(root, blocks);
    return blocks;
  }

  static void _walk(
    dom.Node node,
    List<({String text, String kind})> blocks,
  ) {
    if (node is! dom.Element) {
      return;
    }

    final tag = node.localName?.toLowerCase() ?? '';

    if (tag == 'script' || tag == 'style' || tag == 'noscript') {
      return;
    }

    if (tag == 'br') {
      return;
    }

    if (_isBlockTag(tag)) {
      final text = node.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isNotEmpty) {
        blocks.add((text: text, kind: _kindForTag(tag)));
      }
      return;
    }

    for (final child in node.nodes) {
      if (child is dom.Element) {
        _walk(child, blocks);
      } else if (child is dom.Text) {
        final text = child.text.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (text.isNotEmpty) {
          blocks.add((text: text, kind: 'p'));
        }
      }
    }
  }

  static bool _isBlockTag(String tag) {
    return const {
      'p',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'li',
      'pre',
      'blockquote',
      'td',
      'th',
    }.contains(tag);
  }

  static String _kindForTag(String tag) {
    switch (tag) {
      case 'h1':
        return 'h1';
      case 'h2':
        return 'h2';
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        return 'h3';
      case 'li':
        return 'li';
      case 'pre':
        return 'pre';
      case 'blockquote':
        return 'quote';
      default:
        return 'p';
    }
  }

  static List<List<({String text, String kind})>> _chunkBlocks(
    List<({String text, String kind})> blocks,
  ) {
    const maxBlocks = 28;
    const maxChars = 2200;
    final pages = <List<({String text, String kind})>>[];
    var current = <({String text, String kind})>[];
    var chars = 0;

    for (final block in blocks) {
      final next = chars + block.text.length;
      if (current.isNotEmpty &&
          (current.length >= maxBlocks || next > maxChars)) {
        pages.add(current);
        current = <({String text, String kind})>[];
        chars = 0;
      }
      current.add(block);
      chars += block.text.length;
    }
    if (current.isNotEmpty) {
      pages.add(current);
    }
    return pages;
  }

  static bool _isHeading(String kind) =>
      kind == 'h1' || kind == 'h2' || kind == 'h3';

  static double _sizeFor(String kind, double base) {
    switch (kind) {
      case 'h1':
        return base + 6;
      case 'h2':
        return base + 4;
      case 'h3':
        return base + 2;
      case 'pre':
        return base - 1;
      default:
        return base;
    }
  }

  static double _gapFor(String kind, double base) {
    if (_isHeading(kind)) return base + 4;
    if (kind == 'li') return base * 0.6;
    return base;
  }

  static String _prefixFor(String kind) {
    if (kind == 'li') return '• ';
    if (kind == 'quote') return '> ';
    return '';
  }

  static _HtmlLayout _layoutFor(ImageFitMode mode) {
    switch (mode) {
      case ImageFitMode.center:
        return const _HtmlLayout(
          margin: pw.EdgeInsets.all(56),
          fontSize: 11,
          lineSpacing: 1.5,
          paragraphGap: 10,
          align: pw.TextAlign.center,
        );
      case ImageFitMode.contain:
        return const _HtmlLayout(
          margin: pw.EdgeInsets.all(40),
          fontSize: 12,
          lineSpacing: 1.4,
          paragraphGap: 8,
          align: pw.TextAlign.left,
        );
      case ImageFitMode.cover:
        return const _HtmlLayout(
          margin: pw.EdgeInsets.all(20),
          fontSize: 13,
          lineSpacing: 1.35,
          paragraphGap: 6,
          align: pw.TextAlign.left,
        );
      case ImageFitMode.fill:
        return const _HtmlLayout(
          margin: pw.EdgeInsets.all(12),
          fontSize: 11,
          lineSpacing: 1.25,
          paragraphGap: 4,
          align: pw.TextAlign.justify,
        );
      case ImageFitMode.fitWidth:
        return const _HtmlLayout(
          margin: pw.EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          fontSize: 13,
          lineSpacing: 1.4,
          paragraphGap: 8,
          align: pw.TextAlign.left,
        );
      case ImageFitMode.fitHeight:
        return const _HtmlLayout(
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

class _HtmlLayout {
  const _HtmlLayout({
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
