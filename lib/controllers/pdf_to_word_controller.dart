
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/document_models.dart';
import '../routes/app_routes.dart';
import '../services/pdf_to_word_service.dart';

class PdfToWordController extends GetxController {
  final documents = <SelectedDocument>[].obs;
  final isBusy = false.obs;

  void clearDocuments() => documents.clear();

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<PdfToWordController>()
        ? Get.find<PdfToWordController>()
        : Get.put(PdfToWordController(), permanent: true);

    controller.clearDocuments();
    await controller.pickDocuments();
    if (controller.documents.isEmpty) return;
    Get.toNamed(AppRoutes.pdfToWord);
  }

  Future<void> addMoreDocuments() async {
    if (isBusy.value) return;
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;
    await pickDocuments();
  }

  Future<void> pickDocuments() async {
    try {
      isBusy.value = true;
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: const ['pdf'],
      );
      if (files.isEmpty) return;

      final stamp = DateTime.now().microsecondsSinceEpoch;
      var index = 0;
      for (final file in files) {
        final path = file.path;
        if (path == null) continue;
        final size = file.lengthSync() ?? await file.length();
        final id = '$stamp-${index++}';
        final pages = await PdfToWordService.parsePages(
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
        LocaleKeys.toolPdfToWord.tr,
        LocaleKeys.pickPdfFailed.tr,
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

  void onCreateWordPressed() {
    if (documents.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolPdfToWord.tr,
        LocaleKeys.noPdfSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'pdf_to_word',
        'documents': documents.toList(),
      },
    );
  }
}
