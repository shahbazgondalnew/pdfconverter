import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/pdf_to_image_models.dart';
import '../routes/app_routes.dart';

class DeletePagesPdfController extends GetxController {
  final pages = <PdfPageImage>[].obs;

  /// Page ids marked for deletion.
  final markedIds = <String>{}.obs;
  final isBusy = false.obs;

  void clearSession() {
    pages.clear();
    markedIds.clear();
  }

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<DeletePagesPdfController>()
        ? Get.find<DeletePagesPdfController>()
        : Get.put(DeletePagesPdfController(), permanent: true);

    controller.clearSession();

    final picked = await controller.pickPdfFiles();
    if (picked.isEmpty) return;

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'delete_pages_pdf_render',
        'pdfFiles': picked,
      },
    );
  }

  Future<List<PdfSourceFile>> pickPdfFiles() async {
    try {
      isBusy.value = true;
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: const ['pdf'],
      );
      if (picked.isEmpty) return const [];

      final stamp = DateTime.now().microsecondsSinceEpoch;
      var index = 0;
      final files = <PdfSourceFile>[];
      for (final file in picked) {
        final path = file.path;
        if (path == null) continue;
        files.add(
          PdfSourceFile(
            id: '$stamp-${index++}',
            path: path,
            name: file.name.isNotEmpty ? file.name : p.basename(path),
          ),
        );
      }
      return files;
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolDeletePages.tr,
        LocaleKeys.pickPdfFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return const [];
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> addMorePdfs() async {
    if (isBusy.value) return;
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final picked = await pickPdfFiles();
    if (picked.isEmpty) return;

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'delete_pages_pdf_render',
        'pdfFiles': picked,
        'append': true,
      },
    );
  }

  void setPages(List<PdfPageImage> next, {bool append = false}) {
    if (append) {
      pages.addAll(next);
    } else {
      pages.assignAll(next);
      markedIds.clear();
    }
  }

  bool isMarked(String id) => markedIds.contains(id);

  void toggleMark(String id) {
    if (markedIds.contains(id)) {
      markedIds.remove(id);
    } else {
      markedIds.add(id);
    }
    markedIds.refresh();
  }

  void markAll() {
    markedIds
      ..clear()
      ..addAll(pages.map((page) => page.id));
    markedIds.refresh();
  }

  void clearMarks() {
    markedIds.clear();
  }

  void deleteMarked() {
    if (markedIds.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolDeletePages.tr,
        LocaleKeys.deletePagesSelectHint.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    final remaining = pages.length - markedIds.length;
    if (remaining <= 0) {
      Get.snackbar(
        LocaleKeys.toolDeletePages.tr,
        LocaleKeys.deletePagesKeepOne.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    pages.removeWhere((page) => markedIds.contains(page.id));
    markedIds.clear();
  }

  void deletePage(String id) {
    if (pages.length <= 1) {
      Get.snackbar(
        LocaleKeys.toolDeletePages.tr,
        LocaleKeys.deletePagesKeepOne.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    pages.removeWhere((page) => page.id == id);
    markedIds.remove(id);
    markedIds.refresh();
  }

  List<PdfPageImage> get remainingPages => pages.toList();

  void onSavePressed() {
    // If pages are still marked, apply deletion first (keep at least one).
    if (markedIds.isNotEmpty) {
      final remaining = pages.length - markedIds.length;
      if (remaining <= 0) {
        Get.snackbar(
          LocaleKeys.toolDeletePages.tr,
          LocaleKeys.deletePagesKeepOne.tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
        return;
      }
      pages.removeWhere((page) => markedIds.contains(page.id));
      markedIds.clear();
    }

    if (pages.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolDeletePages.tr,
        LocaleKeys.noPagesSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'delete_pages_pdf',
        'pages': pages.toList(),
      },
    );
  }
}
