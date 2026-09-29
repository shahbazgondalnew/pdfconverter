import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/pdf_to_image_models.dart';
import '../models/watermark_models.dart';
import '../routes/app_routes.dart';

class WatermarkPdfController extends GetxController {
  final pages = <PdfPageImage>[].obs;
  final isBusy = false.obs;
  final settings = const WatermarkSettings().obs;
  final textController = TextEditingController(text: 'CONFIDENTIAL');
  final _picker = ImagePicker();

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  void clearSession() {
    pages.clear();
    settings.value = const WatermarkSettings();
    textController.text = settings.value.text;
  }

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<WatermarkPdfController>()
        ? Get.find<WatermarkPdfController>()
        : Get.put(WatermarkPdfController(), permanent: true);

    controller.clearSession();

    final picked = await controller.pickPdfFiles();
    if (picked.isEmpty) return;

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'watermark_pdf_render',
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
        LocaleKeys.toolWatermark.tr,
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
        'type': 'watermark_pdf_render',
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

  void setType(WatermarkType type) {
    settings.value = settings.value.copyWith(type: type);
  }

  void setText(String text) {
    settings.value = settings.value.copyWith(text: text);
  }

  void useTextPreset(String preset) {
    textController.value = TextEditingValue(
      text: preset,
      selection: TextSelection.collapsed(offset: preset.length),
    );
    settings.value = settings.value.copyWith(
      type: WatermarkType.text,
      text: preset,
    );
  }

  Future<void> pickWatermarkImage() async {
    try {
      isBusy.value = true;
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      settings.value = settings.value.copyWith(
        type: WatermarkType.image,
        imagePath: file.path,
      );
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolWatermark.tr,
        LocaleKeys.pickImagesFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }

  void clearWatermarkImage() {
    settings.value = settings.value.copyWith(clearImage: true);
  }

  void setPosition(WatermarkPosition position) {
    settings.value = settings.value.copyWith(position: position);
  }

  void setLayout(WatermarkLayout layout) {
    settings.value = settings.value.copyWith(layout: layout);
  }

  void setOpacity(double opacity) {
    settings.value = settings.value.copyWith(opacity: opacity);
  }

  void setRotation(double rotation) {
    settings.value = settings.value.copyWith(rotation: rotation);
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

  void setImageScale(double scale) {
    settings.value = settings.value.copyWith(imageScale: scale);
  }

  void setRangeMode(WatermarkRangeMode mode) {
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

  void deletePage(String id) {
    pages.removeWhere((page) => page.id == id);
    _syncCustomRangeBounds();
  }

  void openEditor(String id) {
    Get.toNamed(AppRoutes.watermarkPdfEdit, arguments: id);
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
        LocaleKeys.toolWatermark.tr,
        LocaleKeys.noPagesSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    if (!settings.value.hasContent) {
      Get.snackbar(
        LocaleKeys.toolWatermark.tr,
        LocaleKeys.watermarkContentRequired.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'watermark_pdf',
        'pages': pages.toList(),
        'settings': settings.value,
      },
    );
  }
}

class WatermarkPdfEditController extends GetxController {
  late final String pageId;
  final draft = Rxn<PdfPageImage>();
  final isBusy = false.obs;

  WatermarkPdfController get _parent => Get.find<WatermarkPdfController>();

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
