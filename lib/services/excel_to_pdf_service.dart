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

class ExcelToPdfService {
  const ExcelToPdfService();

  /// Parses Excel/CSV into editable sheet/page chunks.
  static Future<List<WordPage>> parsePages({
    required String path,
    required String documentId,
  }) async {
    final ext = p.extension(path).toLowerCase();
    final sheets = await _extractSheets(path, ext);
    final pages = <WordPage>[];
    var pageIndex = 0;

    for (final sheet in sheets) {
      final chunks = _chunkRows(sheet.rows);
      for (var i = 0; i < chunks.length; i++) {
        final title = chunks.length == 1
            ? sheet.name
            : '${sheet.name} (${i + 1}/${chunks.length})';
        pages.add(
          WordPage(
            id: '$documentId-p${pageIndex++}',
            index: pageIndex - 1,
            title: title,
            rows: chunks[i],
          ),
        );
      }
    }

    if (pages.isEmpty) {
      pages.add(
        WordPage(
          id: '$documentId-p0',
          index: 0,
          title: 'Sheet1',
          rows: const [
            ['(Empty spreadsheet)'],
          ],
        ),
      );
    }
    return pages;
  }

  Future<ConversionRecord> convert({
    required List<SelectedDocument> documents,
    required PdfPageSettings settings,
    ConversionProgressCallback? onProgress,
  }) async {
    if (documents.isEmpty) {
      throw StateError('No Excel files to convert');
    }

    final workItems = <({SelectedDocument doc, WordPage page})>[];
    for (final doc in documents) {
      for (final page in doc.pages) {
        workItems.add((doc: doc, page: page));
      }
    }
    if (workItems.isEmpty) {
      throw StateError('No Excel pages to convert');
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
      final rows = item.page.rows;
      final headerLabel = item.page.title ?? item.doc.name;

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
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(
              '${item.doc.name} · $headerLabel',
              style: pw.TextStyle(
                fontSize: 9,
                color: mutedText,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          build: (context) {
            if (rows.isEmpty) {
              return [
                pw.Text(
                  '(Empty sheet)',
                  style: pw.TextStyle(fontSize: layout.fontSize, color: mutedText),
                ),
              ];
            }

            final maxCols = rows
                .map((row) => row.length)
                .fold<int>(0, (prev, length) => length > prev ? length : prev)
                .clamp(1, 12);

            return [
              pw.TableHelper.fromTextArray(
                headers: List.generate(maxCols, (index) => 'Col ${index + 1}'),
                data: [
                  for (final row in rows)
                    [
                      for (var c = 0; c < maxCols; c++)
                        c < row.length ? row[c] : '',
                    ],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: layout.fontSize - 1,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.red700,
                ),
                cellStyle: pw.TextStyle(
                  fontSize: layout.fontSize - 1,
                  color: pdfText,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.4,
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
        'EXCEL_PDF_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}.pdf';
    final output = await ConversionStorage.createOutputFile(fileName);
    await output.writeAsBytes(await pdf.save(), flush: true);

    final record = ConversionRecord(
      id: stamp.microsecondsSinceEpoch.toString(),
      name: p.basename(output.path),
      path: output.path,
      sizeBytes: await output.length(),
      conversionType: ConversionType.excelToPdf,
      createdAt: stamp,
      pageCount: pdf.document.pdfPageList.pages.length,
    );
    return ConversionStorage.saveRecord(record);
  }

  static _ExcelLayout _layoutFor(ImageFitMode mode) {
    switch (mode) {
      case ImageFitMode.center:
        return const _ExcelLayout(
          margin: pw.EdgeInsets.all(48),
          fontSize: 8,
        );
      case ImageFitMode.contain:
        return const _ExcelLayout(
          margin: pw.EdgeInsets.all(28),
          fontSize: 8,
        );
      case ImageFitMode.cover:
        return const _ExcelLayout(
          margin: pw.EdgeInsets.all(16),
          fontSize: 9,
        );
      case ImageFitMode.fill:
        return const _ExcelLayout(
          margin: pw.EdgeInsets.all(10),
          fontSize: 7.5,
        );
      case ImageFitMode.fitWidth:
        return const _ExcelLayout(
          margin: pw.EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          fontSize: 8.5,
        );
      case ImageFitMode.fitHeight:
        return const _ExcelLayout(
          margin: pw.EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          fontSize: 9,
        );
    }
  }

  static Future<List<({String name, List<List<String>> rows})>> _extractSheets(
    String path,
    String ext,
  ) async {
    if (ext == '.csv') {
      final text = await File(path).readAsString();
      final rows = text
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.split(',').map((cell) => cell.trim()).toList())
          .toList();
      return [(name: 'Sheet1', rows: rows)];
    }

    if (ext == '.xlsx') {
      return _extractFromXlsx(path);
    }

    return [
      (
        name: 'Sheet1',
        rows: [
          ['This file format ($ext) has limited support.'],
          ['Please use .xlsx or .csv for best results.'],
          ['File: ${p.basename(path)}'],
        ],
      ),
    ];
  }

  static Future<List<({String name, List<List<String>> rows})>> _extractFromXlsx(
    String path,
  ) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final shared = <String>[];
    final sharedFile = archive.findFile('xl/sharedStrings.xml');
    if (sharedFile != null) {
      final xml = XmlDocument.parse(
        utf8.decode(sharedFile.content as List<int>),
      );
      for (final item in xml.findAllElements('si')) {
        final texts = item.findAllElements('t').map((t) => t.innerText).join();
        shared.add(texts);
      }
    }

    final sheetNames = <String>[];
    final workbookFile = archive.findFile('xl/workbook.xml');
    if (workbookFile != null) {
      final workbookXml = XmlDocument.parse(
        utf8.decode(workbookFile.content as List<int>),
      );
      for (final sheet in workbookXml.findAllElements('sheet')) {
        final name = sheet.getAttribute('name');
        if (name != null && name.isNotEmpty) {
          sheetNames.add(name);
        }
      }
    }

    final sheetFiles = archive.files
        .where(
          (file) =>
              file.name.startsWith('xl/worksheets/sheet') &&
              file.name.endsWith('.xml'),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (sheetFiles.isEmpty) {
      throw StateError('Invalid Excel file');
    }

    final sheets = <({String name, List<List<String>> rows})>[];
    for (var i = 0; i < sheetFiles.length; i++) {
      final sheetFile = sheetFiles[i];
      final sheetXml = XmlDocument.parse(
        utf8.decode(sheetFile.content as List<int>),
      );
      final rows = <List<String>>[];

      for (final row in sheetXml.findAllElements('row')) {
        final cells = <String>[];
        for (final cell in row.findAllElements('c')) {
          final type = cell.getAttribute('t');
          final value = cell.getElement('v')?.innerText ?? '';
          if (type == 's') {
            final index = int.tryParse(value) ?? -1;
            cells.add(
              index >= 0 && index < shared.length ? shared[index] : '',
            );
          } else {
            cells.add(value);
          }
        }
        if (cells.any((cell) => cell.trim().isNotEmpty)) {
          rows.add(cells);
        }
      }

      final name = i < sheetNames.length ? sheetNames[i] : 'Sheet${i + 1}';
      if (rows.isEmpty) {
        sheets.add((name: name, rows: const [['(Empty sheet)']]));
      } else {
        sheets.add((name: name, rows: rows));
      }
    }

    return sheets;
  }

  static List<List<List<String>>> _chunkRows(List<List<String>> rows) {
    if (rows.isEmpty) {
      return [
        [
          ['(Empty sheet)'],
        ],
      ];
    }

    const maxRows = 40;
    if (rows.length <= maxRows) {
      return [rows];
    }

    final chunks = <List<List<String>>>[];
    for (var i = 0; i < rows.length; i += maxRows) {
      final end = (i + maxRows < rows.length) ? i + maxRows : rows.length;
      chunks.add(rows.sublist(i, end));
    }
    return chunks;
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _ExcelLayout {
  const _ExcelLayout({
    required this.margin,
    required this.fontSize,
  });

  final pw.EdgeInsets margin;
  final double fontSize;
}
