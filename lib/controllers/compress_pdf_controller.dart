import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/pdf_to_image_models.dart';
import '../routes/app_routes.dart';
import '../services/merge_pdf_service.dart';

class CompressPdfController extends GetxController {
  final pages = <PdfPageImage>[].obs;
  final isBusy = false.obs;
  final compressLevel = PdfCompressLevel.medium.obs;

  void clearPages() {
    pages.clear();
    compressLevel.value = PdfCompressLevel.medium;
  }

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<CompressPdfController>()
        ? Get.find<CompressPdfController>()
        : Get.put(CompressPdfController(), permanent: true);

    controller.clearPages();

    final picked = await controller.pickPdfFiles();
    if (picked.isEmpty) return;

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'compress_pdf_render',
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
        LocaleKeys.toolCompressPdf.tr,
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
        'type': 'compress_pdf_render',
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

  void setCompressLevel(PdfCompressLevel level) {
    compressLevel.value = level;
  }

  void deletePage(String id) {
    pages.removeWhere((page) => page.id == id);
  }

  void openEditor(String id) {
    Get.toNamed(AppRoutes.compressPdfEdit, arguments: id);
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

  void onCompressPressed() {
    if (pages.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolCompressPdf.tr,
        LocaleKeys.noPagesSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'compress_pdf',
        'pages': pages.toList(),
        'level': compressLevel.value,
      },
    );
  }
}

class CompressPdfEditController extends GetxController {
  late final String pageId;
  final draft = Rxn<PdfPageImage>();
  final isBusy = false.obs;

  CompressPdfController get _parent => Get.find<CompressPdfController>();

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
