import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/pdf_to_image_models.dart';
import '../routes/app_routes.dart';

class LockPdfController extends GetxController {
  final selected = Rxn<PdfSourceFile>();
  final isBusy = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirm = true.obs;
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  void onClose() {
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }

  void clearSession() {
    selected.value = null;
    passwordController.clear();
    confirmController.clear();
    obscurePassword.value = true;
    obscureConfirm.value = true;
  }

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<LockPdfController>()
        ? Get.find<LockPdfController>()
        : Get.put(LockPdfController(), permanent: true);

    controller.clearSession();

    final picked = await controller.pickPdfFile();
    if (picked == null) return;

    controller.selected.value = picked;
    Get.toNamed(AppRoutes.lockPdf);
  }

  Future<PdfSourceFile?> pickPdfFile() async {
    try {
      isBusy.value = true;
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: const ['pdf'],
      );
      if (picked.isEmpty) return null;

      final file = picked.first;
      final path = file.path;
      if (path == null) return null;

      return PdfSourceFile(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        path: path,
        name: file.name.isNotEmpty ? file.name : p.basename(path),
      );
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolLockPdf.tr,
        LocaleKeys.pickPdfFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return null;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> changePdf() async {
    if (isBusy.value) return;
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final picked = await pickPdfFile();
    if (picked == null) return;
    selected.value = picked;
  }

  void toggleObscurePassword() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleObscureConfirm() {
    obscureConfirm.value = !obscureConfirm.value;
  }

  String? get fileSizeLabel {
    final file = selected.value;
    if (file == null) return null;
    try {
      final bytes = File(file.path).lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      }
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return null;
    }
  }

  void onLockPressed() {
    final file = selected.value;
    if (file == null) {
      Get.snackbar(
        LocaleKeys.toolLockPdf.tr,
        LocaleKeys.lockPdfNoFile.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    final password = passwordController.text;
    final confirm = confirmController.text;

    if (password.trim().isEmpty) {
      Get.snackbar(
        LocaleKeys.toolLockPdf.tr,
        LocaleKeys.lockPdfPasswordRequired.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    if (password.trim().length < 4) {
      Get.snackbar(
        LocaleKeys.toolLockPdf.tr,
        LocaleKeys.lockPdfPasswordShort.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    if (password != confirm) {
      Get.snackbar(
        LocaleKeys.toolLockPdf.tr,
        LocaleKeys.lockPdfPasswordMismatch.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'lock_pdf',
        'file': file,
        'password': password.trim(),
      },
    );
  }
}
