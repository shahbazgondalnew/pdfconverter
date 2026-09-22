import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/pdf_to_image_models.dart';
import '../routes/app_routes.dart';

class SplitPdfController extends GetxController {
  final pages = <PdfPageImage>[].obs;
  final selectedIds = <String>{}.obs;
  final isBusy = false.obs;
  final createdCount = 0.obs;

  /// When true, result Done returns to the split overview.
  var continueAfterResult = false;

  void clearSession() {
    pages.clear();
    selectedIds.clear();
    createdCount.value = 0;
    continueAfterResult = false;
  }

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<SplitPdfController>()
        ? Get.find<SplitPdfController>()
        : Get.put(SplitPdfController(), permanent: true);

    controller.clearSession();

    final picked = await controller.pickPdfFile();
    if (picked == null) return;

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'split_pdf_render',
        'pdfFiles': [picked],
      },
    );
  }

  Future<PdfSourceFile?> pickPdfFile() async {
    try {
      isBusy.value = true;
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (picked == null) return null;

      final path = picked.path;
      if (path == null) return null;

      return PdfSourceFile(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        path: path,
        name: picked.name.isNotEmpty ? picked.name : p.basename(path),
      );
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolSplitPdf.tr,
        LocaleKeys.pickPdfFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return null;
    } finally {
      isBusy.value = false;
    }
  }

  void setPages(List<PdfPageImage> next) {
    pages.assignAll(next);
    selectedIds.clear();
  }

  void deletePage(String id) {
    pages.removeWhere((page) => page.id == id);
    selectedIds.remove(id);
    selectedIds.refresh();
  }

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

  bool isSelected(String id) => selectedIds.contains(id);

  List<PdfPageImage> get selectedPages {
    final ids = selectedIds.toSet();
    return pages.where((page) => ids.contains(page.id)).toList();
  }

  void openEditor(String id) {
    Get.toNamed(AppRoutes.splitPdfEdit, arguments: id);
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

  void onCreatePdfPressed() {
    final chosen = selectedPages;
    if (chosen.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolSplitPdf.tr,
        LocaleKeys.splitSelectPagesHint.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    continueAfterResult = true;
    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'split_pdf',
        'pages': chosen,
      },
    );
  }

  void onSplitFinished() {
    createdCount.value++;
    selectedIds.clear();
  }

  void finishSession() {
    clearSession();
    Get.until((route) => route.settings.name == AppRoutes.home);
  }
}

class SplitPdfEditController extends GetxController {
  late final String pageId;
  final draft = Rxn<PdfPageImage>();
  final isBusy = false.obs;

  SplitPdfController get _parent => Get.find<SplitPdfController>();

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
    if (current == null) return;
    _parent.updatePage(current);
    Get.back();
  }
}
