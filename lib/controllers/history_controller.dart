import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../localization/locale_keys.dart';
import '../models/conversion_record.dart';
import '../services/conversion_storage.dart';

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
      await Share.shareXFiles(existing, subject: record.name);
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

    await Share.shareXFiles(
      [XFile(absolutePath, mimeType: 'application/pdf', name: record.name)],
      subject: record.name,
    );
  }

  Future<void> saveImagesToGallery(ConversionRecord record) async {
    if (!record.isImageGroup) return;
    try {
      final granted = await Gal.requestAccess();
      if (!granted) {
        Get.snackbar(
          LocaleKeys.historyTitle.tr,
          LocaleKeys.gallerySaveFailed.tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
        return;
      }

      final files = ConversionStorage.resolveFiles(record);
      var saved = 0;
      for (final file in files) {
        if (!await file.exists()) continue;
        await Gal.putImage(file.path, album: 'PDF Converter');
        saved++;
      }

      if (saved == 0) {
        Get.snackbar(
          LocaleKeys.historyTitle.tr,
          LocaleKeys.fileMissing.tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
        reload();
        return;
      }

      Get.snackbar(
        LocaleKeys.historyTitle.tr,
        LocaleKeys.gallerySaveSuccess.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } catch (_) {
      Get.snackbar(
        LocaleKeys.historyTitle.tr,
        LocaleKeys.gallerySaveFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Future<void> openRecord(ConversionRecord record) async {
    if (record.isImageGroup) {
      await _showImageGroupSheet(record);
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

    final result = await OpenFilex.open(absolutePath);
    if (result.type != ResultType.done) {
      Get.snackbar(
        LocaleKeys.historyTitle.tr,
        LocaleKeys.openPdfFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Future<void> _showImageGroupSheet(ConversionRecord record) async {
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
      reload();
      return;
    }

    await Get.bottomSheet(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.72,
          ),
          decoration: BoxDecoration(
            color: Get.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: LocaleKeys.saveToGallery.tr,
                      onPressed: () async {
                        Get.back();
                        await saveImagesToGallery(record);
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                    ),
                    IconButton(
                      tooltip: LocaleKeys.shareImages.tr,
                      onPressed: () async {
                        Get.back();
                        await shareRecord(record);
                      },
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          Get.back();
                          await OpenFilex.open(file.path);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            file,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: Color(0xFFEFEFEF),
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
