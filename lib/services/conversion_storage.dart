import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/conversion_record.dart';

/// App-private storage for converted files + Hive metadata.
/// Cleared when the app is uninstalled or app data is cleared.
class ConversionStorage {
  ConversionStorage._();

  static const _boxName = 'conversion_records';
  static Box<dynamic>? _box;
  static Directory? _filesDir;

  static bool get isReady => _box != null && _filesDir != null;

  static Future<void> init({bool forTest = false}) async {
    if (forTest) {
      final dir = await Directory.systemTemp.createTemp('pdfconverter_hive_');
      Hive.init(dir.path);
      _filesDir = Directory(p.join(dir.path, 'conversions'));
    } else {
      await Hive.initFlutter();
      final docs = await getApplicationDocumentsDirectory();
      _filesDir = Directory(p.join(docs.path, 'conversions'));
    }

    if (!await _filesDir!.exists()) {
      await _filesDir!.create(recursive: true);
    }

    _box = await Hive.openBox(_boxName);
  }

  static Directory get filesDirectory {
    _ensureReady();
    return _filesDir!;
  }

  static void _ensureReady() {
    if (!isReady) {
      throw StateError('ConversionStorage.init() must be called first');
    }
  }

  static Future<File> createOutputFile(String fileName) async {
    _ensureReady();
    final safeName = fileName.replaceAll(RegExp(r'[^\w\-. ]'), '_');
    final path = p.join(_filesDir!.path, safeName);
    return File(path);
  }

  static Future<ConversionRecord> saveRecord(ConversionRecord record) async {
    _ensureReady();
    await _box!.put(record.id, record.toMap());
    return record;
  }

  static List<ConversionRecord> getAllRecords() {
    if (!isReady) return const [];
    final records = _box!.values
        .whereType<Map>()
        .map((map) => ConversionRecord.fromMap(map))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  static Future<void> deleteRecord(String id) async {
    _ensureReady();
    final raw = _box!.get(id);
    if (raw is Map) {
      final record = ConversionRecord.fromMap(raw);
      final file = File(record.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _box!.delete(id);
  }

  static Future<void> clearAll() async {
    _ensureReady();
    for (final record in getAllRecords()) {
      final file = File(record.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _box!.clear();
  }
}
