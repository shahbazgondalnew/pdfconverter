import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../components/image_source_bottom_sheet.dart';
import '../components/image_source_picker.dart';
import '../localization/locale_keys.dart';
import '../models/image_to_pdf_models.dart';
import '../routes/app_routes.dart';

class ImageToPdfController extends GetxController {
  final images = <SelectedImage>[].obs;
  final settings = PdfPageSettings().obs;
  final isBusy = false.obs;

  final _picker = ImagePicker();

  void clearImages() {
    images.clear();
  }

  /// Opens source bottom sheet, picks images, then navigates if any were added.
  static Future<void> startFromHome() async {
    final source = await ImageSourceBottomSheet.show();
    if (source == null) return;

    final controller = Get.isRegistered<ImageToPdfController>()
        ? Get.find<ImageToPdfController>()
        : Get.put(ImageToPdfController());

    controller.clearImages();
    await controller.pickFromSource(source);

    if (controller.images.isEmpty) return;
    Get.toNamed(AppRoutes.imageToPdf);
  }

  /// Opens source bottom sheet to append more images.
  Future<void> addMoreImages() async {
    if (isBusy.value) return;
    final source = await ImageSourceBottomSheet.show();
    if (source == null) return;
    await pickFromSource(source);
  }

  Future<void> pickFromSource(ImagePickSource source) async {
    try {
      isBusy.value = true;
      switch (source) {
        case ImagePickSource.gallery:
          await _pickFromGallery();
        case ImagePickSource.camera:
          await _pickFromCamera();
        case ImagePickSource.file:
          await _pickFromFiles();
      }
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolImageToPdf.tr,
        LocaleKeys.pickImagesFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> _pickFromGallery() async {
    final files = await _picker.pickMultiImage(imageQuality: 95);
    if (files.isEmpty) return;
    _addPaths(files.map((file) => file.path));
  }

  Future<void> _pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (file == null) return;
    _addPaths([file.path]);
  }

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
    );
    if (result == null || result.files.isEmpty) return;
    final paths = result.files
        .where((file) => file.path != null)
        .map((file) => file.path!);
    _addPaths(paths);
  }

  void _addPaths(Iterable<String> paths) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    var index = 0;
    for (final path in paths) {
      images.add(
        SelectedImage(
          id: '$stamp-${index++}',
          path: path,
        ),
      );
    }
  }

  void deleteImage(String id) {
    images.removeWhere((image) => image.id == id);
  }

  void openEditor(String id) {
    Get.toNamed(AppRoutes.imageEdit, arguments: id);
  }

  void updateImage(SelectedImage updated) {
    final index = images.indexWhere((image) => image.id == updated.id);
    if (index == -1) return;
    images[index] = updated;
    images.refresh();
  }

  SelectedImage? findImage(String id) {
    return images.firstWhereOrNull((image) => image.id == id);
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
    if (images.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolImageToPdf.tr,
        LocaleKeys.noImagesSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.snackbar(
      LocaleKeys.toolImageToPdf.tr,
      LocaleKeys.pdfReadySoon.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
    );
  }
}
