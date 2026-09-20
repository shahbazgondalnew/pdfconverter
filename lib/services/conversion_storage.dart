import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/conversion_record.dart';

/// App-private storage for converted files + Hive metadata.
/// Cleared when the app is uninstalled or app data is cleared.
///
/// Paths are stored as **filenames only** (relative to [filesDirectory]).
/// Absolute iOS container paths change between runs/rebuilds, so they must
/// never be persisted.
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
    await _migrateAbsolutePaths();
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

  /// Portable path for Hive — filename only under [filesDirectory].
  static String toStoredPath(String absoluteOrRelativePath) {
    return p.basename(absoluteOrRelativePath);
  }

  /// Resolves a stored (or legacy absolute) path against the current
  /// documents container. Fixes iOS UUID path changes across runs.
  static File resolveFile(String storedPath) {
    _ensureReady();
    final fileName = p.basename(storedPath);
    return File(p.join(_filesDir!.path, fileName));
  }

  /// Absolute path for open/share APIs.
  static String resolvePath(String storedPath) {
    return resolveFile(storedPath).path;
  }

  static Future<File> createOutputFile(String fileName) async {
    _ensureReady();
    final safeName = fileName.replaceAll(RegExp(r'[^\w\-. ]'), '_');
    final path = p.join(_filesDir!.path, safeName);
    return File(path);
  }

  static Future<ConversionRecord> saveRecord(ConversionRecord record) async {
    _ensureReady();
    final portable = record.copyWith(path: toStoredPath(record.path));
    await _box!.put(portable.id, portable.toMap());
    return portable;
  }

  static List<ConversionRecord> getAllRecords() {
    if (!isReady) return const [];
    final records = _box!.values
        .whereType<Map>()
        .map((map) => ConversionRecord.fromMap(map))
        .map(
          (record) => record.copyWith(path: toStoredPath(record.path)),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  static Future<void> deleteRecord(String id) async {
    _ensureReady();
    final raw = _box!.get(id);
    if (raw is Map) {
      final record = ConversionRecord.fromMap(raw);
      final file = resolveFile(record.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _box!.delete(id);
  }

  static Future<void> clearAll() async {
    _ensureReady();
    for (final record in getAllRecords()) {
      final file = resolveFile(record.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _box!.clear();
  }

  /// Rewrite any Hive entries that still store absolute container paths.
  static Future<void> _migrateAbsolutePaths() async {
    if (_box == null) return;
    for (final key in _box!.keys.toList()) {
      final raw = _box!.get(key);
      if (raw is! Map) continue;
      final path = raw['path'] as String?;
      if (path == null || path.isEmpty) continue;
      if (!p.isAbsolute(path)) continue;

      final updated = Map<dynamic, dynamic>.from(raw);
      updated['path'] = toStoredPath(path);
      await _box!.put(key, updated);
    }
  }
}
