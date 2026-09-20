import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/document_models.dart';
import '../routes/app_routes.dart';

class ExcelToPdfController extends GetxController {
  final documents = <SelectedDocument>[].obs;
  final isBusy = false.obs;

  static const _extensions = ['xlsx', 'xls', 'csv'];

  void clearDocuments() => documents.clear();

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addExcelFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<ExcelToPdfController>()
        ? Get.find<ExcelToPdfController>()
        : Get.put(ExcelToPdfController());

    controller.clearDocuments();
    await controller.pickDocuments();
    if (controller.documents.isEmpty) return;
    Get.toNamed(AppRoutes.excelToPdf);
  }

  Future<void> addMoreDocuments() async {
    if (isBusy.value) return;
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addExcelFiles.tr,
    );
    if (confirmed != true) return;
    await pickDocuments();
  }

  Future<void> pickDocuments() async {
    try {
      isBusy.value = true;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: _extensions,
      );
      if (result == null || result.files.isEmpty) return;

      final stamp = DateTime.now().microsecondsSinceEpoch;
      var index = 0;
      for (final file in result.files) {
        final path = file.path;
        if (path == null) continue;
        final size = file.size > 0 ? file.size : await File(path).length();
        documents.add(
          SelectedDocument(
            id: '$stamp-${index++}',
            path: path,
            name: file.name.isNotEmpty ? file.name : p.basename(path),
            sizeBytes: size,
          ),
        );
      }
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolExcelToPdf.tr,
        LocaleKeys.pickExcelFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }

  void deleteDocument(String id) {
    documents.removeWhere((doc) => doc.id == id);
  }

  void onCreatePdfPressed() {
    if (documents.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolExcelToPdf.tr,
        LocaleKeys.noExcelSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'excel_to_pdf',
        'documents': documents.toList(),
      },
    );
  }
}
