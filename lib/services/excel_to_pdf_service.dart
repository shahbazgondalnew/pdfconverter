import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xml/xml.dart';

import '../models/conversion_record.dart';
import '../models/document_models.dart';
import 'conversion_storage.dart';
import 'image_to_pdf_service.dart';

class ExcelToPdfService {
  const ExcelToPdfService();

  Future<ConversionRecord> convert({
    required List<SelectedDocument> documents,
    ConversionProgressCallback? onProgress,
  }) async {
    if (documents.isEmpty) {
      throw StateError('No Excel files to convert');
    }

    final pdf = pw.Document();
    final total = documents.length;
    var pageCount = 0;

    for (var i = 0; i < documents.length; i++) {
      final doc = documents[i];
      final ext = p.extension(doc.path).toLowerCase();
      final rows = await _extractRows(doc.path, ext);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Text(
              doc.name,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          build: (context) {
            if (rows.isEmpty) {
              return [
                pw.Text(
                  '(Empty spreadsheet)',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              ];
            }

            final maxCols = rows
                .map((row) => row.length)
                .fold<int>(0, (prev, length) => length > prev ? length : prev);

            return [
              pw.TableHelper.fromTextArray(
                headers: List.generate(
                  maxCols,
                  (index) => 'Col ${index + 1}',
                ),
                data: [
                  for (final row in rows)
                    [
                      for (var c = 0; c < maxCols; c++)
                        c < row.length ? row[c] : '',
                    ],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.red700,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
              ),
            ];
          },
        ),
      );

      pageCount += 1;
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
      pageCount: pageCount,
    );
    return ConversionStorage.saveRecord(record);
  }

  Future<List<List<String>>> _extractRows(String path, String ext) async {
    if (ext == '.csv') {
      final text = await File(path).readAsString();
      return text
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.split(',').map((cell) => cell.trim()).toList())
          .toList();
    }

    if (ext == '.xlsx') {
      return _extractFromXlsx(path);
    }

    return [
      ['This file format ($ext) has limited support.'],
      ['Please use .xlsx or .csv for best results.'],
      ['File: ${p.basename(path)}'],
    ];
  }

  Future<List<List<String>>> _extractFromXlsx(String path) async {
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

    ArchiveFile? sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
    if (sheetFile == null) {
      for (final file in archive.files) {
        if (file.name.startsWith('xl/worksheets/sheet') &&
            file.name.endsWith('.xml')) {
          sheetFile = file;
          break;
        }
      }
    }

    if (sheetFile == null) {
      throw StateError('Invalid Excel file');
    }

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
          cells.add(index >= 0 && index < shared.length ? shared[index] : '');
        } else {
          cells.add(value);
        }
      }
      if (cells.any((cell) => cell.trim().isNotEmpty)) {
        rows.add(cells);
      }
    }
    return rows;
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
