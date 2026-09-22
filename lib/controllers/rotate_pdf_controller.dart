import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/pdf_to_image_models.dart';
import '../routes/app_routes.dart';

class RotatePdfController extends GetxController {
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

    final controller = Get.isRegistered<RotatePdfController>()
        ? Get.find<RotatePdfController>()
        : Get.put(RotatePdfController(), permanent: true);

    controller.clearPages();

    final picked = await controller.pickPdfFiles();
    if (picked.isEmpty) return;

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'rotate_pdf_render',
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
        LocaleKeys.toolRotatePdf.tr,
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
        'type': 'rotate_pdf_render',
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

  void rotatePageLeft(String id) {
    final index = pages.indexWhere((page) => page.id == id);
    if (index == -1) return;
    final page = pages[index];
    pages[index] = page.copyWith(rotation: (page.rotation - 90) % 360);
    pages.refresh();
  }

  void rotatePageRight(String id) {
    final index = pages.indexWhere((page) => page.id == id);
    if (index == -1) return;
    final page = pages[index];
    pages[index] = page.copyWith(rotation: (page.rotation + 90) % 360);
    pages.refresh();
  }

  void rotateAllLeft() {
    if (pages.isEmpty) return;
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      pages[i] = page.copyWith(rotation: (page.rotation - 90) % 360);
    }
    pages.refresh();
  }

  void rotateAllRight() {
    if (pages.isEmpty) return;
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      pages[i] = page.copyWith(rotation: (page.rotation + 90) % 360);
    }
    pages.refresh();
  }

  void onSavePressed() {
    if (pages.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolRotatePdf.tr,
        LocaleKeys.noPagesSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'rotate_pdf',
        'pages': pages.toList(),
      },
    );
  }
}
