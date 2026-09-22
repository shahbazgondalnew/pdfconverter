import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../components/select_images_to_save_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/conversion_record.dart';
import '../routes/app_routes.dart';
import '../services/conversion_storage.dart';
import '../services/gallery_save_service.dart';
import '../theme/app_colors.dart';
import 'pdf_to_image_controller.dart';

class HistoryController extends GetxController {
  final records = <ConversionRecord>[].obs;

  bool get hasConversions => records.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  void reload() {
    records.assignAll(ConversionStorage.getAllRecords());
  }

  Future<void> clearHistory() async {
    await ConversionStorage.clearAll();
    reload();
  }

  Future<void> deleteRecord(ConversionRecord record) async {
    await ConversionStorage.deleteRecord(record.id);
    reload();
  }

  Future<void> shareRecord(ConversionRecord record) async {
    if (record.isImageGroup) {
      final files = ConversionStorage.resolveFiles(record);
      final existing = <XFile>[];
      for (final file in files) {
        if (await file.exists()) {
          existing.add(
            XFile(
              file.path,
              mimeType: 'image/png',
              name: file.uri.pathSegments.last,
            ),
          );
        }
      }
      if (existing.isEmpty) {
        Get.snackbar(
          LocaleKeys.historyTitle.tr,
          LocaleKeys.fileMissing.tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
        reload();
        return;
      }
      await SharePlus.instance.share(
        ShareParams(files: existing, subject: record.name),
      );
      return;
    }

    final absolutePath = ConversionStorage.resolvePath(record.path);
    final file = File(absolutePath);
    if (!await file.exists()) {
      Get.snackbar(
        LocaleKeys.historyTitle.tr,
        LocaleKeys.fileMissing.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      reload();
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            absolutePath,
            mimeType: record.shareMimeType,
            name: record.name,
          ),
        ],
        subject: record.name,
      ),
    );
  }

  List<File> _existingImageFiles(ConversionRecord record) {
    return ConversionStorage.resolveFiles(record)
        .where((file) => file.existsSync())
        .toList();
  }

  Future<void> saveAllImagesToGallery(ConversionRecord record) async {
    if (!record.isImageGroup) return;
    final files = _existingImageFiles(record);
    final ok = await const GallerySaveService().saveFiles(
      files,
      snackTitle: LocaleKeys.historyTitle,
    );
    if (!ok && files.isEmpty) reload();
  }

  Future<void> selectImagesToSave(ConversionRecord record) async {
    if (!record.isImageGroup) return;
    final files = _existingImageFiles(record);
    if (files.isEmpty) {
      Get.snackbar(
        LocaleKeys.historyTitle.tr,
        LocaleKeys.fileMissing.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      reload();
      return;
    }
    await SelectImagesToSaveSheet.show(
      files: files,
      snackTitle: LocaleKeys.historyTitle,
    );
  }

  Future<void> promptSaveToGallery(ConversionRecord record) async {
    if (!record.isImageGroup) return;
    final isDark = Get.isDarkMode;

    final choice = await Get.bottomSheet<String>(
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.saveToGallery.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.brand),
                title: Text(LocaleKeys.saveAllImages.tr),
                onTap: () => Get.back(result: 'all'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.checklist_rounded, color: AppColors.brand),
                title: Text(LocaleKeys.selectImages.tr),
                onTap: () => Get.back(result: 'select'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );

    if (choice == 'all') {
      await saveAllImagesToGallery(record);
    } else if (choice == 'select') {
      await selectImagesToSave(record);
    }
  }

  Future<void> openRecord(ConversionRecord record) async {
    if (record.isImageGroup) {
      await PdfToImageController.openFromHistory(record);
      return;
    }

    final absolutePath = ConversionStorage.resolvePath(record.path);
    final file = File(absolutePath);
    if (!await file.exists()) {
      Get.snackbar(
        LocaleKeys.historyTitle.tr,
        LocaleKeys.fileMissing.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      reload();
      return;
    }

    // Same result screen used after conversion (share / open / save).
    Get.toNamed(AppRoutes.pdfResult, arguments: record);
  }
}
