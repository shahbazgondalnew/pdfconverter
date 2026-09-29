import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../components/image_source_bottom_sheet.dart';
import '../components/image_source_picker.dart';
import '../localization/locale_keys.dart';
import '../models/image_to_pdf_models.dart';
import '../routes/app_routes.dart';

class JpgToPngController extends GetxController {
  final images = <SelectedImage>[].obs;
  final isBusy = false.obs;
  final _picker = ImagePicker();

  void clearSession() {
    images.clear();
  }

  static Future<void> startFromHome() async {
    final source = await ImageSourceBottomSheet.show();
    if (source == null) return;

    final controller = Get.isRegistered<JpgToPngController>()
        ? Get.find<JpgToPngController>()
        : Get.put(JpgToPngController(), permanent: true);

    controller.clearSession();
    await controller.pickFromSource(source);

    if (controller.images.isEmpty) return;
    Get.toNamed(AppRoutes.jpgToPng);
  }

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
        LocaleKeys.toolJpgToPng.tr,
        LocaleKeys.pickImagesFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> _pickFromGallery() async {
    final files = await _picker.pickMultiImage(imageQuality: 100);
    if (files.isEmpty) return;
    addImagePaths(files.map((file) => file.path));
  }

  Future<void> _pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    if (file == null) return;
    addImagePaths([file.path]);
  }

  Future<void> _pickFromFiles() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
    );
    if (files.isEmpty) return;
    final paths = files
        .where((file) => file.path != null)
        .map((file) => file.path!);
    addImagePaths(paths);
  }

  void addImagePaths(Iterable<String> paths) {
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
    Get.toNamed(AppRoutes.jpgToPngEdit, arguments: id);
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

  void onConvertPressed() {
    if (images.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolJpgToPng.tr,
        LocaleKeys.noImagesSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'jpg_to_png',
        'images': images.toList(),
      },
    );
  }
}

class JpgToPngEditController extends GetxController {
  late final String imageId;
  final draft = Rxn<SelectedImage>();
  final isBusy = false.obs;

  JpgToPngController get _parent => Get.find<JpgToPngController>();

  @override
  void onInit() {
    super.onInit();
    imageId = Get.arguments as String;
    final source = _parent.findImage(imageId);
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
    _parent.updateImage(current);
    Get.back();
  }
}
