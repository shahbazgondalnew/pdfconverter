import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/page_number_models.dart';
import '../models/pdf_to_image_models.dart';
import '../routes/app_routes.dart';

class PageNumbersPdfController extends GetxController {
  final pages = <PdfPageImage>[].obs;
  final isBusy = false.obs;
  final settings = PageNumberSettings().obs;

  void clearSession() {
    pages.clear();
    settings.value = const PageNumberSettings();
  }

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<PageNumbersPdfController>()
        ? Get.find<PageNumbersPdfController>()
        : Get.put(PageNumbersPdfController(), permanent: true);

    controller.clearSession();

    final picked = await controller.pickPdfFiles();
    if (picked.isEmpty) return;

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'page_numbers_pdf_render',
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
        LocaleKeys.toolPageNumbers.tr,
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
        'type': 'page_numbers_pdf_render',
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
    _syncCustomRangeBounds();
  }

  void _syncCustomRangeBounds() {
    final total = pages.length.clamp(1, 9999);
    final current = settings.value;
    var from = current.customFrom.clamp(1, total);
    var to = current.customTo.clamp(from, total);
    if (current.customTo < 1 || current.customTo > total) {
      to = total;
    }
    settings.value = current.copyWith(customFrom: from, customTo: to);
  }

  void updateSettings(PageNumberSettings next) {
    settings.value = next;
  }

  void setFormat(PageNumberFormat format) {
    settings.value = settings.value.copyWith(format: format);
  }

  void setPosition(PageNumberPosition position) {
    settings.value = settings.value.copyWith(position: position);
  }

  void setFontSize(double size) {
    settings.value = settings.value.copyWith(fontSize: size);
  }

  void setColor(int colorValue) {
    settings.value = settings.value.copyWith(colorValue: colorValue);
  }

  void setBold(bool bold) {
    settings.value = settings.value.copyWith(bold: bold);
  }

  void setRangeMode(PageNumberRangeMode mode) {
    settings.value = settings.value.copyWith(rangeMode: mode);
    _syncCustomRangeBounds();
  }

  void setCustomFrom(int value) {
    final total = pages.length.clamp(1, 9999);
    final from = value.clamp(1, total);
    final to = settings.value.customTo.clamp(from, total);
    settings.value = settings.value.copyWith(customFrom: from, customTo: to);
  }

  void setCustomTo(int value) {
    final total = pages.length.clamp(1, 9999);
    final from = settings.value.customFrom.clamp(1, total);
    final to = value.clamp(from, total);
    settings.value = settings.value.copyWith(customFrom: from, customTo: to);
  }

  void setStartNumber(int value) {
    settings.value = settings.value.copyWith(startNumber: value.clamp(1, 9999));
  }

  String get previewLabel {
    final total = pages.isEmpty ? 10 : pages.length;
    final index = settings.value.rangeMode == PageNumberRangeMode.skipCover
        ? 1
        : settings.value.rangeMode == PageNumberRangeMode.custom
            ? (settings.value.customFrom - 1).clamp(0, total - 1)
            : 0;
    return settings.value.labelFor(index, total);
  }

  void deletePage(String id) {
    pages.removeWhere((page) => page.id == id);
    _syncCustomRangeBounds();
  }

  void openEditor(String id) {
    Get.toNamed(AppRoutes.pageNumbersPdfEdit, arguments: id);
  }

  void updatePage(PdfPageImage updated) {
    final index = pages.indexWhere((page) => page.id == updated.id);
    if (index != -1) {
      pages[index] = updated;
      pages.refresh();
    }
  }

  PdfPageImage? findPage(String id) {
    return pages.firstWhereOrNull((page) => page.id == id);
  }

  void onApplyPressed() {
    if (pages.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolPageNumbers.tr,
        LocaleKeys.noPagesSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'page_numbers_pdf',
        'pages': pages.toList(),
        'settings': settings.value,
      },
    );
  }
}

class PageNumbersPdfEditController extends GetxController {
  late final String pageId;
  final draft = Rxn<PdfPageImage>();
  final isBusy = false.obs;

  PageNumbersPdfController get _parent => Get.find<PageNumbersPdfController>();

  @override
  void onInit() {
    super.onInit();
    pageId = Get.arguments as String;
    final source = _parent.findPage(pageId);
    if (source != null) {
      draft.value = source.copyWith();
    }
  }

  void rotateLeft() {
    final current = draft.value;
    if (current == null) return;
    draft.value = current.copyWith(rotation: (current.rotation - 90) % 360);
  }

  void rotateRight() {
    final current = draft.value;
    if (current == null) return;
    draft.value = current.copyWith(rotation: (current.rotation + 90) % 360);
  }

  Future<void> crop() async {
    final current = draft.value;
    if (current == null) return;

    try {
      isBusy.value = true;
      final cropped = await ImageCropper().cropImage(
        sourcePath: current.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: LocaleKeys.crop.tr,
            toolbarColor: const Color(0xFFD32F2F),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFD32F2F),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: LocaleKeys.crop.tr,
          ),
        ],
      );

      if (cropped != null) {
        draft.value = current.copyWith(path: cropped.path);
      }
    } catch (_) {
      Get.snackbar(
        LocaleKeys.editImage.tr,
        LocaleKeys.cropFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }

  void save() {
    final current = draft.value;
    if (current != null) {
      _parent.updatePage(current);
    }
    Get.back();
  }
}
