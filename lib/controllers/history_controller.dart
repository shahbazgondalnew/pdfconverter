import 'dart:io';

import 'package:flutter/material.dart';
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

  Future<void> openRecord(ConversionRecord record) async {
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
}
