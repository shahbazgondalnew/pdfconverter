
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../components/text_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/document_models.dart';
import '../models/image_to_pdf_models.dart';
import '../routes/app_routes.dart';
import '../services/html_to_pdf_service.dart';

class HtmlToPdfController extends GetxController {
  final documents = <SelectedDocument>[].obs;
  final settings = PdfPageSettings().obs;
  final isBusy = false.obs;
  final pasteController = TextEditingController();
  final focusPaste = false.obs;

  static const _extensions = ['html', 'htm'];

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
    final source = await TextSourceBottomSheet.show(
      titleKey: LocaleKeys.addHtmlContent,
      pasteKey: LocaleKeys.pasteHtml,
    );
    if (source == null) return;

    final controller = Get.isRegistered<HtmlToPdfController>()
        ? Get.find<HtmlToPdfController>()
        : Get.put(HtmlToPdfController(), permanent: true);

    controller.clearAll();

    if (source == TextSourceOption.files) {
      await controller.pickDocuments();
      if (controller.documents.isEmpty) return;
    } else {
      controller.focusPaste.value = true;
    }

    Get.toNamed(AppRoutes.htmlToPdf);
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
        final pages = await HtmlToPdfService.parseFile(
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
        LocaleKeys.toolHtmlToPdf.tr,
        LocaleKeys.pickHtmlFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }

  void addPastedHtml() {
    final html = pasteController.text.trim();
    if (html.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolHtmlToPdf.tr,
        LocaleKeys.pasteHtmlEmpty.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final id = 'html-paste-$stamp';
    final pages = HtmlToPdfService.pagesFromHtml(
      html: html,
      documentId: id,
      title: LocaleKeys.pastedHtml.tr,
    );

    documents.add(
      SelectedDocument(
        id: id,
        path: '',
        name: LocaleKeys.pastedHtml.tr,
        sizeBytes: html.length,
        pages: pages,
      ),
    );
    pasteController.clear();
    documents.refresh();

    Get.snackbar(
      LocaleKeys.toolHtmlToPdf.tr,
      LocaleKeys.pastedHtmlAdded.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }

  void deleteDocument(String id) {
    documents.removeWhere((doc) => doc.id == id);
  }

  void openEditor(String id) {
    Get.toNamed(AppRoutes.htmlEdit, arguments: id);
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
    final pending = pasteController.text.trim();
    if (pending.isNotEmpty) {
      addPastedHtml();
    }

    if (documents.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolHtmlToPdf.tr,
        LocaleKeys.noHtmlSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    final hasPages = documents.any((doc) => doc.pages.isNotEmpty);
    if (!hasPages) {
      Get.snackbar(
        LocaleKeys.toolHtmlToPdf.tr,
        LocaleKeys.noPagesLeft.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'html_to_pdf',
        'documents': documents.toList(),
        'settings': settings.value,
      },
    );
  }
}
