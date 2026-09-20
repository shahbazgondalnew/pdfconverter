import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../components/select_images_to_save_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/conversion_record.dart';
import '../models/pdf_to_image_models.dart';
import '../routes/app_routes.dart';
import '../services/conversion_storage.dart';
import '../services/gallery_save_service.dart';
import '../services/pdf_to_image_service.dart';
import 'history_controller.dart';

class PdfToImageController extends GetxController {
  /// Pages shown in the review grid (user can remove from here).
  final pages = <PdfPageImage>[].obs;

  /// Full converted set kept for history even if the user removes pages.
  final allPages = <PdfPageImage>[].obs;
  final isBusy = false.obs;

  /// Hive id of the image-group already stored for this conversion.
  String? historyRecordId;

  /// True when the preview was opened from a history group.
  var openedFromHistory = false;

  void clearPages() {
    pages.clear();
    allPages.clear();
    historyRecordId = null;
    openedFromHistory = false;
  }

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<PdfToImageController>()
        ? Get.find<PdfToImageController>()
        : Get.put(PdfToImageController(), permanent: true);

    controller.clearPages();

    final picked = await controller.pickPdfFiles();
    if (picked.isEmpty) return;

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'pdf_to_image_render',
        'pdfFiles': picked,
      },
    );
  }

  /// Opens the same preview screen used after PDF → Image conversion.
  static Future<void> openFromHistory(ConversionRecord record) async {
    if (!record.isImageGroup) return;

    final files = ConversionStorage.resolveFiles(record)
        .where((file) => file.existsSync())
        .toList();
    if (files.isEmpty) {
      Get.snackbar(
        LocaleKeys.historyTitle.tr,
        LocaleKeys.fileMissing.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      if (Get.isRegistered<HistoryController>()) {
        Get.find<HistoryController>().reload();
      }
      return;
    }

    final controller = Get.isRegistered<PdfToImageController>()
        ? Get.find<PdfToImageController>()
        : Get.put(PdfToImageController(), permanent: true);

    controller.clearPages();
    controller.historyRecordId = record.id;
    controller.openedFromHistory = true;

    final loaded = <PdfPageImage>[];
    for (var i = 0; i < files.length; i++) {
      loaded.add(
        PdfPageImage(
          id: '${record.id}-$i',
          path: files[i].path,
          sourceName: record.name,
          pageNumber: i + 1,
        ),
      );
    }
    controller.setPages(loaded);

    Get.toNamed(AppRoutes.pdfToImage);
  }

  Future<List<PdfSourceFile>> pickPdfFiles() async {
    try {
      isBusy.value = true;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: const ['pdf'],
      );
      if (result == null || result.files.isEmpty) return const [];

      final stamp = DateTime.now().microsecondsSinceEpoch;
      var index = 0;
      final files = <PdfSourceFile>[];
      for (final file in result.files) {
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
        LocaleKeys.toolPdfToImage.tr,
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
        'type': 'pdf_to_image_render',
        'pdfFiles': picked,
        'append': true,
      },
    );
  }

  void setPages(List<PdfPageImage> next, {bool append = false}) {
    if (append) {
      pages.addAll(next);
      allPages.addAll(next);
    } else {
      pages.assignAll(next);
      allPages.assignAll(List<PdfPageImage>.from(next));
    }
  }

  void deletePage(String id) {
    // Remove from review only — history still keeps every converted page.
    pages.removeWhere((page) => page.id == id);
  }

  void openEditor(String id) {
    Get.toNamed(AppRoutes.pdfToImageEdit, arguments: id);
  }

  void updatePage(PdfPageImage updated) {
    final index = pages.indexWhere((page) => page.id == updated.id);
    if (index != -1) {
      pages[index] = updated;
      pages.refresh();
    }

    final allIndex = allPages.indexWhere((page) => page.id == updated.id);
    if (allIndex != -1) {
      allPages[allIndex] = updated;
      allPages.refresh();
    }
  }

  PdfPageImage? findPage(String id) {
    return pages.firstWhereOrNull((page) => page.id == id) ??
        allPages.firstWhereOrNull((page) => page.id == id);
  }

  List<File> _galleryFiles() {
    final source =
        allPages.isNotEmpty ? allPages.toList() : pages.toList();
    return source
        .map((page) => File(page.path))
        .where((file) => file.existsSync())
        .toList();
  }

  /// Stores / refreshes one history group for this conversion (like PDF tools).
  Future<void> persistToHistory() async {
    final toSave =
        allPages.isNotEmpty ? allPages.toList() : pages.toList();
    if (toSave.isEmpty) return;

    final previousId = historyRecordId;
    final record = await const PdfToImageService().saveGroup(pages: toSave);

    // Point preview at the newly stored files before deleting the old group,
    // otherwise opening from history would wipe the images currently on screen.
    final storedFiles = ConversionStorage.resolveFiles(record);
    for (var i = 0; i < allPages.length && i < storedFiles.length; i++) {
      allPages[i] = allPages[i].copyWith(path: storedFiles[i].path);
    }
    for (var i = 0; i < pages.length; i++) {
      final matchIndex =
          allPages.indexWhere((page) => page.id == pages[i].id);
      if (matchIndex != -1) {
        pages[i] = allPages[matchIndex];
      }
    }
    allPages.refresh();
    pages.refresh();

    if (previousId != null && previousId != record.id) {
      await ConversionStorage.deleteRecord(previousId);
    }

    historyRecordId = record.id;
    _reloadHistory();
  }

  void _reloadHistory() {
    if (Get.isRegistered<HistoryController>()) {
      Get.find<HistoryController>().reload();
    }
  }

  Future<void> saveAllToGallery() async {
    final files = _galleryFiles();
    if (files.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolPdfToImage.tr,
        LocaleKeys.noImagesSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    await const GallerySaveService().saveFiles(
      files,
      snackTitle: LocaleKeys.toolPdfToImage,
    );
  }

  Future<void> selectImagesToGallery() async {
    final files = _galleryFiles();
    if (files.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolPdfToImage.tr,
        LocaleKeys.noImagesSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    await SelectImagesToSaveSheet.show(
      files: files,
      snackTitle: LocaleKeys.toolPdfToImage,
    );
  }

  Future<void> onDonePressed() async {
    try {
      isBusy.value = true;
      await persistToHistory();
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolPdfToImage.tr,
        LocaleKeys.conversionFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }

    if (openedFromHistory) {
      openedFromHistory = false;
      Get.back();
      _reloadHistory();
    } else {
      Get.until((route) => route.settings.name == AppRoutes.home);
    }
  }
}

class PdfToImageEditController extends GetxController {
  late final String pageId;
  final draft = Rxn<PdfPageImage>();
  final isBusy = false.obs;

  PdfToImageController get _parent => Get.find<PdfToImageController>();

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
