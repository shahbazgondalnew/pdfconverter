import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/pdf_to_image_models.dart';
import '../routes/app_routes.dart';

class ReorderPdfController extends GetxController {
  final pages = <PdfPageImage>[].obs;
  final isBusy = false.obs;

  void clearPages() {
    pages.clear();
  }

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<ReorderPdfController>()
        ? Get.find<ReorderPdfController>()
        : Get.put(ReorderPdfController(), permanent: true);

    controller.clearPages();

    final picked = await controller.pickPdfFiles();
    if (picked.isEmpty) return;

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'reorder_pdf_render',
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
        LocaleKeys.toolReorderPages.tr,
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
        'type': 'reorder_pdf_render',
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
    }
  }

  void deletePage(String id) {
    pages.removeWhere((page) => page.id == id);
  }

  void onReorderItem(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final item = pages.removeAt(oldIndex);
    pages.insert(newIndex, item);
  }

  void moveUp(int index) {
    if (index <= 0 || index >= pages.length) return;
    final item = pages.removeAt(index);
    pages.insert(index - 1, item);
  }

  void moveDown(int index) {
    if (index < 0 || index >= pages.length - 1) return;
    final item = pages.removeAt(index);
    pages.insert(index + 1, item);
  }

  void moveToStart(int index) {
    if (index <= 0 || index >= pages.length) return;
    final item = pages.removeAt(index);
    pages.insert(0, item);
  }

  void moveToEnd(int index) {
    if (index < 0 || index >= pages.length - 1) return;
    final item = pages.removeAt(index);
    pages.add(item);
  }

  void onSavePressed() {
    if (pages.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolReorderPages.tr,
        LocaleKeys.noPagesSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'reorder_pdf',
        'pages': pages.toList(),
      },
    );
  }
}
