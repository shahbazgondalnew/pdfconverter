import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../models/document_models.dart';
import '../models/image_to_pdf_models.dart';
import 'ppt_to_pdf_controller.dart';

class PptEditController extends GetxController {
  late final String documentId;
  final draft = Rxn<SelectedDocument>();

  PptToPdfController get _parent => Get.find<PptToPdfController>();

  PdfPageSettings get settings => _parent.settings.value;

  @override
  void onInit() {
    super.onInit();
    documentId = Get.arguments as String;
    final source = _parent.findDocument(documentId);
    if (source != null) {
      draft.value = source.copyWith();
    }
  }

  void removePage(String pageId) {
    final current = draft.value;
    if (current == null) return;

    if (current.pages.length <= 1) {
      Get.snackbar(
        LocaleKeys.editPptSlides.tr,
        LocaleKeys.noPagesLeft.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    current.pages.removeWhere((page) => page.id == pageId);
    for (var i = 0; i < current.pages.length; i++) {
      current.pages[i].index = i;
    }
    draft.refresh();
  }

  void save() {
    final current = draft.value;
    if (current == null) return;
    _parent.updateDocument(current);
    Get.back();
  }
}
