import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';

class GallerySaveService {
  const GallerySaveService();

  Future<bool> saveFiles(
    List<File> files, {
    String snackTitle = LocaleKeys.toolPdfToImage,
  }) async {
    try {
      final granted = await Gal.requestAccess();
      if (!granted) {
        Get.snackbar(
          snackTitle.tr,
          LocaleKeys.gallerySaveFailed.tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
        return false;
      }

      var saved = 0;
      for (final file in files) {
        if (!await file.exists()) continue;
        await Gal.putImage(file.path, album: 'PDF Converter');
        saved++;
      }

      if (saved == 0) {
        Get.snackbar(
          snackTitle.tr,
          LocaleKeys.fileMissing.tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
        return false;
      }

      Get.snackbar(
        snackTitle.tr,
        LocaleKeys.gallerySaveSuccess.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return true;
    } catch (_) {
      Get.snackbar(
        snackTitle.tr,
        LocaleKeys.gallerySaveFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return false;
    }
  }
}
