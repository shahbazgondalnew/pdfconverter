import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/pdf_to_image_models.dart';
import '../routes/app_routes.dart';
import '../services/pdf_to_image_service.dart';

class ExtractPagesController extends GetxController {
  final pages = <PdfPageImage>[].obs;
  final selectedIds = <String>{}.obs;
  final selectedFormat = ExtractImageFormat.png.obs;
  final isBusy = false.obs;

  void clearSession() {
    pages.clear();
    selectedIds.clear();
    selectedFormat.value = ExtractImageFormat.png;
  }

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<ExtractPagesController>()
        ? Get.find<ExtractPagesController>()
        : Get.put(ExtractPagesController(), permanent: true);

    controller.clearSession();

    final picked = await controller.pickPdfFiles();
    if (picked.isEmpty) return;

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'extract_pages_render',
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
        LocaleKeys.toolExtractPages.tr,
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
        'type': 'extract_pages_render',
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
      selectedIds.clear();
    }
  }

  bool isSelected(String id) => selectedIds.contains(id);

  void toggleSelect(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    selectedIds.refresh();
  }

  void selectAll() {
    selectedIds
      ..clear()
      ..addAll(pages.map((page) => page.id));
    selectedIds.refresh();
  }

  void deselectAll() {
    selectedIds.clear();
  }

  void setFormat(ExtractImageFormat format) {
    selectedFormat.value = format;
  }

  List<PdfPageImage> get selectedPages {
    final ids = selectedIds.toSet();
    return pages.where((page) => ids.contains(page.id)).toList();
  }

  void onExtractPressed() {
    final chosen = selectedPages;
    if (chosen.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolExtractPages.tr,
        LocaleKeys.extractPagesSelectHint.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'extract_pages',
        'pages': chosen,
        'format': selectedFormat.value,
      },
    );
  }
}
