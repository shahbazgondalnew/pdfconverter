import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../localization/locale_keys.dart';

class DocumentSaveService {
  const DocumentSaveService();

  /// Opens the system Files / Downloads save dialog for a PDF or Word file.
  Future<bool> downloadFile({
    required File file,
    required String displayName,
    required String mimeType,
    String snackTitle = LocaleKeys.savePdf,
  }) async {
    if (!await file.exists()) {
      Get.snackbar(
        snackTitle.tr,
        LocaleKeys.fileMissing.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return false;
    }

    try {
      final extension = _extensionOf(file.path, displayName);
      final name = _baseName(displayName, file.path);
      final mime = _mimeType(mimeType, extension);

      final savedPath = await FileSaver.instance.saveAs(
        name: name,
        file: file,
        fileExtension: extension,
        mimeType: mime,
        customMimeType: mime == MimeType.custom ? mimeType : null,
      );

      if (savedPath == null || savedPath.isEmpty) {
        return false;
      }

      Get.snackbar(
        snackTitle.tr,
        LocaleKeys.fileDownloadSuccess.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return true;
    } catch (_) {
      Get.snackbar(
        snackTitle.tr,
        LocaleKeys.fileDownloadFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return false;
    }
  }

  String _extensionOf(String path, String displayName) {
    final fromPath = p.extension(path).replaceFirst('.', '');
    if (fromPath.isNotEmpty) return fromPath;
    final fromName = p.extension(displayName).replaceFirst('.', '');
    if (fromName.isNotEmpty) return fromName;
    return 'pdf';
  }

  String _baseName(String displayName, String path) {
    final raw = displayName.trim().isNotEmpty
        ? displayName.trim()
        : p.basename(path);
    final withoutExt = p.basenameWithoutExtension(raw);
    return withoutExt.isEmpty ? 'document' : withoutExt;
  }

  MimeType _mimeType(String mimeType, String extension) {
    final lowerMime = mimeType.toLowerCase();
    final lowerExt = extension.toLowerCase();
    if (lowerMime.contains('pdf') || lowerExt == 'pdf') {
      return MimeType.pdf;
    }
    if (lowerMime.contains('word') ||
        lowerExt == 'docx' ||
        lowerExt == 'doc') {
      return MimeType.microsoftWord;
    }
    return MimeType.custom;
  }
}
