import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../localization/locale_keys.dart';
import '../models/conversion_record.dart';
import '../routes/app_routes.dart';
import 'image_to_pdf_controller.dart';

class ScanToPdfController extends GetxController {
  final capturedPaths = <String>[].obs;
  final isBusy = false.obs;
  final isCameraReady = false.obs;
  final cameraError = RxnString();

  CameraController? cameraController;
  final _picker = ImagePicker();

  String? get lastCapturedPath =>
      capturedPaths.isEmpty ? null : capturedPaths.last;

  int get captureCount => capturedPaths.length;

  @override
  void onInit() {
    super.onInit();
    _initCamera();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }

  static Future<void> startFromHome() async {
    Get.toNamed(AppRoutes.scanToPdf);
  }

  Future<void> _initCamera() async {
    try {
      isCameraReady.value = false;
      cameraError.value = null;

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        cameraError.value = LocaleKeys.cameraUnavailable.tr;
        return;
      }

      final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();

      // Dispose previous if any (hot restart / re-init).
      await cameraController?.dispose();
      cameraController = controller;
      isCameraReady.value = true;
    } catch (_) {
      cameraError.value = LocaleKeys.cameraUnavailable.tr;
      isCameraReady.value = false;
    }
  }

  Future<void> capture() async {
    final cam = cameraController;
    if (cam == null || !cam.value.isInitialized || isBusy.value) return;
    if (cam.value.isTakingPicture) return;

    try {
      isBusy.value = true;
      final file = await cam.takePicture();
      capturedPaths.add(file.path);
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolScanToPdf.tr,
        LocaleKeys.captureFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> pickFromGallery() async {
    if (isBusy.value) return;
    try {
      isBusy.value = true;
      final files = await _picker.pickMultiImage(imageQuality: 95);
      if (files.isEmpty) return;
      capturedPaths.addAll(files.map((file) => file.path));
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolScanToPdf.tr,
        LocaleKeys.pickImagesFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }

  void removeLastCapture() {
    if (capturedPaths.isEmpty) return;
    capturedPaths.removeLast();
  }

  Future<void> onDone() async {
    if (capturedPaths.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolScanToPdf.tr,
        LocaleKeys.noImagesSelected.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    // Keep a copy — camera controller will dispose when this route pops.
    final paths = List<String>.from(capturedPaths);

    await cameraController?.dispose();
    cameraController = null;
    isCameraReady.value = false;

    ImageToPdfController.startFromScan(
      paths: paths,
      conversionType: ConversionType.scanToPdf,
    );
  }

  void retryCamera() => _initCamera();
}
