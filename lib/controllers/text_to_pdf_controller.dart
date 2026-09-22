
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../components/text_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/document_models.dart';
import '../models/image_to_pdf_models.dart';
import '../routes/app_routes.dart';
import '../services/text_to_pdf_service.dart';

class TextToPdfController extends GetxController {
  final documents = <SelectedDocument>[].obs;
  final settings = PdfPageSettings().obs;
  final isBusy = false.obs;
  final pasteController = TextEditingController();
  final focusPaste = false.obs;

  static const _extensions = ['txt', 'text', 'md', 'log'];

  @override
  void onClose() {
    pasteController.dispose();
    super.onClose();
  }

  void clearAll() {
    documents.clear();
    pasteController.clear();
    settings.value = PdfPageSettings();
    focusPaste.value = false;
  }

  static Future<void> startFromHome() async {
    final source = await TextSourceBottomSheet.show();
    if (source == null) return;

    final controller = Get.isRegistered<TextToPdfController>()
        ? Get.find<TextToPdfController>()
        : Get.put(TextToPdfController(), permanent: true);

    controller.clearAll();

    if (source == TextSourceOption.files) {
      await controller.pickDocuments();
      if (controller.documents.isEmpty) return;
    } else {
      controller.focusPaste.value = true;
    }

    Get.toNamed(AppRoutes.textToPdf);
  }

  Future<void> addMoreDocuments() async {
    if (isBusy.value) return;
    await pickDocuments();
  }

  Future<void> pickDocuments() async {
    try {
      isBusy.value = true;
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: _extensions,
      );
      if (files.isEmpty) return;

      final stamp = DateTime.now().microsecondsSinceEpoch;
      var index = 0;
      for (final file in files) {
        final path = file.path;
        if (path == null) continue;
        final size = file.lengthSync() ?? await file.length();
        final id = '$stamp-${index++}';
        final pages = await TextToPdfService.parseFile(
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
        LocaleKeys.toolTextToPdf.tr,
        LocaleKeys.pickTextFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }

  void addPastedText() {
    final text = pasteController.text.trim();
    if (text.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolTextToPdf.tr,
        LocaleKeys.pasteTextEmpty.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final id = 'paste-$stamp';
    final pages = TextToPdfService.pagesFromText(
      text: text,
      documentId: id,
      title: LocaleKeys.pastedText.tr,
    );

    documents.add(
      SelectedDocument(
        id: id,
        path: '',
        name: LocaleKeys.pastedText.tr,
        sizeBytes: text.length,
        pages: pages,
      ),
    );
    pasteController.clear();
    documents.refresh();

    Get.snackbar(
      LocaleKeys.toolTextToPdf.tr,
      LocaleKeys.pastedTextAdded.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }

  void deleteDocument(String id) {
    documents.removeWhere((doc) => doc.id == id);
  }

  void openEditor(String id) {
    Get.toNamed(AppRoutes.textEdit, arguments: id);
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
    // Auto-include current paste if user forgot to tap Add.
    final pending = pasteController.text.trim();
    if (pending.isNotEmpty) {
      addPastedText();
    }

    if (documents.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolTextToPdf.tr,
        LocaleKeys.noTextSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    final hasPages = documents.any((doc) => doc.pages.isNotEmpty);
    if (!hasPages) {
      Get.snackbar(
        LocaleKeys.toolTextToPdf.tr,
        LocaleKeys.noPagesLeft.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'text_to_pdf',
        'documents': documents.toList(),
        'settings': settings.value,
      },
    );
  }
}
