import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/document_models.dart';
import '../models/image_to_pdf_models.dart';
import '../routes/app_routes.dart';
import '../services/ppt_to_pdf_service.dart';

class PptToPdfController extends GetxController {
  final documents = <SelectedDocument>[].obs;
  final settings = PdfPageSettings().obs;
  final isBusy = false.obs;

  static const _extensions = ['pptx', 'ppt'];

  void clearDocuments() {
    documents.clear();
    settings.value = PdfPageSettings();
  }

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPptFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<PptToPdfController>()
        ? Get.find<PptToPdfController>()
        : Get.put(PptToPdfController(), permanent: true);

    controller.clearDocuments();
    await controller.pickDocuments();
    if (controller.documents.isEmpty) return;
    Get.toNamed(AppRoutes.pptToPdf);
  }

  Future<void> addMoreDocuments() async {
    if (isBusy.value) return;
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPptFiles.tr,
    );
    if (confirmed != true) return;
    await pickDocuments();
  }

  Future<void> pickDocuments() async {
    try {
      isBusy.value = true;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: _extensions,
      );
      if (result == null || result.files.isEmpty) return;

      final stamp = DateTime.now().microsecondsSinceEpoch;
      var index = 0;
      for (final file in result.files) {
        final path = file.path;
        if (path == null) continue;
        final size = file.size > 0 ? file.size : await File(path).length();
        final id = '$stamp-${index++}';
        final pages = await PptToPdfService.parsePages(
          path: path,
          documentId: id,
        );
        documents.add(
          SelectedDocument(
            id: id,
            path: path,
            name: file.name.isNotEmpty ? file.name : p.basename(path),
            sizeBytes: size,
            pages: pages,
          ),
        );
      }
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolPptToPdf.tr,
        LocaleKeys.pickPptFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }

  void deleteDocument(String id) {
    documents.removeWhere((doc) => doc.id == id);
  }

  void openEditor(String id) {
    Get.toNamed(AppRoutes.pptEdit, arguments: id);
  }

  void updateDocument(SelectedDocument updated) {
    final index = documents.indexWhere((doc) => doc.id == updated.id);
    if (index == -1) return;
    if (updated.pages.isEmpty) {
      documents.removeAt(index);
    } else {
      documents[index] = updated;
    }
    documents.refresh();
  }

  SelectedDocument? findDocument(String id) {
    return documents.firstWhereOrNull((doc) => doc.id == id);
  }

  void setFitMode(ImageFitMode mode) {
    settings.value.fitMode = mode;
    settings.refresh();
  }

  void setBackgroundOption(PdfBackgroundOption option) {
    settings.value.backgroundOption = option;
    settings.refresh();
  }

  void setCustomBackground(Color color) {
    settings.value.customBackground = color;
    settings.value.backgroundOption = PdfBackgroundOption.custom;
    settings.refresh();
  }

  void onCreatePdfPressed() {
    if (documents.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolPptToPdf.tr,
        LocaleKeys.noPptSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    final hasPages = documents.any((doc) => doc.pages.isNotEmpty);
    if (!hasPages) {
      Get.snackbar(
        LocaleKeys.toolPptToPdf.tr,
        LocaleKeys.noPagesLeft.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'ppt_to_pdf',
        'documents': documents.toList(),
        'settings': settings.value,
      },
    );
  }
}
