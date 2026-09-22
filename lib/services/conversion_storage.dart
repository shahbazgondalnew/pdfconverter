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
    await purgeOrphanFiles();
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

  static List<File> resolveFiles(ConversionRecord record) {
    return record.allPaths.map(resolveFile).toList();
  }

  static Future<File> createOutputFile(String fileName) async {
    _ensureReady();
    final safeName = fileName.replaceAll(RegExp(r'[^\w\-. ]'), '_');
    final path = p.join(_filesDir!.path, safeName);
    return File(path);
  }

  static Future<ConversionRecord> saveRecord(ConversionRecord record) async {
    _ensureReady();
    final portablePaths =
        record.allPaths.map(toStoredPath).toList(growable: false);
    final portable = record.copyWith(
      path: portablePaths.isNotEmpty ? portablePaths.first : '',
      paths: portablePaths,
    );
    await _box!.put(portable.id, portable.toMap());
    return portable;
  }

  static List<ConversionRecord> getAllRecords() {
    if (!isReady) return const [];
    final records = _box!.values
        .whereType<Map>()
        .map((map) => ConversionRecord.fromMap(map))
        .map((record) {
          final paths = record.allPaths.map(toStoredPath).toList();
          return record.copyWith(
            path: paths.isNotEmpty ? paths.first : toStoredPath(record.path),
            paths: paths,
          );
        })
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  static Set<String> _referencedFileNames() {
    final names = <String>{};
    for (final record in getAllRecords()) {
      for (final stored in record.allPaths) {
        final name = p.basename(stored);
        if (name.isNotEmpty) names.add(name);
      }
    }
    return names;
  }

  static Future<void> _deleteFileQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup; ignore locked/missing files.
    }
  }

  /// Deletes every file in [filesDirectory] that is not referenced by Hive.
  static Future<void> purgeOrphanFiles() async {
    if (!isReady) return;
    final referenced = _referencedFileNames();
    await for (final entity in _filesDir!.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!referenced.contains(name)) {
        await _deleteFileQuietly(entity);
      }
    }
  }

  static Future<void> deleteRecord(String id) async {
    _ensureReady();
    final raw = _box!.get(id);
    if (raw is Map) {
      final record = ConversionRecord.fromMap(raw);
      for (final stored in record.allPaths) {
        await _deleteFileQuietly(resolveFile(stored));
      }
    }
    await _box!.delete(id);
    await purgeOrphanFiles();
  }

  static Future<void> deleteRecords(Iterable<String> ids) async {
    _ensureReady();
    for (final id in ids) {
      final raw = _box!.get(id);
      if (raw is Map) {
        final record = ConversionRecord.fromMap(raw);
        for (final stored in record.allPaths) {
          await _deleteFileQuietly(resolveFile(stored));
        }
      }
      await _box!.delete(id);
    }
    await purgeOrphanFiles();
  }

  static Future<void> clearAll() async {
    _ensureReady();
    await _box!.clear();
    // Wipe the whole conversions folder so no orphaned temps remain.
    if (await _filesDir!.exists()) {
      await for (final entity in _filesDir!.list(followLinks: false)) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    } else {
      await _filesDir!.create(recursive: true);
    }
  }

  /// Rewrite any Hive entries that still store absolute container paths.
  static Future<void> _migrateAbsolutePaths() async {
    if (_box == null) return;
    for (final key in _box!.keys.toList()) {
      final raw = _box!.get(key);
      if (raw is! Map) continue;
      final updated = Map<dynamic, dynamic>.from(raw);
      var changed = false;

      final path = updated['path'] as String?;
      if (path != null && path.isNotEmpty && p.isAbsolute(path)) {
        updated['path'] = toStoredPath(path);
        changed = true;
      }

      final paths = updated['paths'];
      if (paths is List) {
        final migrated = paths.map((e) {
          final value = e.toString();
          return p.isAbsolute(value) ? toStoredPath(value) : value;
        }).toList();
        if (migrated.join('|') != paths.map((e) => e.toString()).join('|')) {
          updated['paths'] = migrated;
          changed = true;
        }
      }

      if (changed) {
        await _box!.put(key, updated);
      }
    }
  }
}
