import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../components/document_source_bottom_sheet.dart';
import '../localization/locale_keys.dart';
import '../models/pdf_to_image_models.dart';
import '../models/sign_pdf_models.dart';
import '../routes/app_routes.dart';

class SignPdfController extends GetxController {
  final selected = Rxn<PdfSourceFile>();
  final isBusy = false.obs;
  final settings = const SignPdfSettings().obs;
  final signaturePath = RxnString();
  final pageCount = 1.obs;
  final _picker = ImagePicker();

  void clearSession() {
    selected.value = null;
    settings.value = const SignPdfSettings();
    signaturePath.value = null;
    pageCount.value = 1;
  }

  static Future<void> startFromHome() async {
    final confirmed = await DocumentSourceBottomSheet.show(
      title: LocaleKeys.addPdfFiles.tr,
    );
    if (confirmed != true) return;

    final controller = Get.isRegistered<SignPdfController>()
        ? Get.find<SignPdfController>()
        : Get.put(SignPdfController(), permanent: true);

    controller.clearSession();

    final picked = await controller.pickPdfFile();
    if (picked == null) return;

    await controller._setSelected(picked);
    Get.toNamed(AppRoutes.signPdf);
  }

  Future<void> _setSelected(PdfSourceFile file) async {
    selected.value = file;
    pageCount.value = await _readPageCount(file.path);
    _syncCustomRangeBounds();
  }

  Future<int> _readPageCount(String path) async {
    try {
      final document = PdfDocument(inputBytes: await File(path).readAsBytes());
      final count = document.pages.count;
      document.dispose();
      return count.clamp(1, 9999);
    } catch (_) {
      return 1;
    }
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
        LocaleKeys.toolSignPdf.tr,
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
    await _setSelected(picked);
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

  void setPosition(SignPdfPosition position) {
    settings.value = settings.value.copyWith(position: position);
  }

  void setRangeMode(SignPdfRangeMode mode) {
    settings.value = settings.value.copyWith(rangeMode: mode);
    _syncCustomRangeBounds();
  }

  void setScale(double scale) {
    settings.value = settings.value.copyWith(scale: scale);
  }

  void setCustomFrom(int value) {
    final total = pageCount.value.clamp(1, 9999);
    final from = value.clamp(1, total);
    final to = settings.value.customTo.clamp(from, total);
    settings.value = settings.value.copyWith(customFrom: from, customTo: to);
  }

  void setCustomTo(int value) {
    final total = pageCount.value.clamp(1, 9999);
    final from = settings.value.customFrom.clamp(1, total);
    final to = value.clamp(from, total);
    settings.value = settings.value.copyWith(customFrom: from, customTo: to);
  }

  void _syncCustomRangeBounds() {
    final total = pageCount.value.clamp(1, 9999);
    final current = settings.value;
    var from = current.customFrom.clamp(1, total);
    var to = current.customTo.clamp(from, total);
    if (current.customTo < 1 || current.customTo > total) {
      to = total;
    }
    settings.value = current.copyWith(customFrom: from, customTo: to);
  }

  Future<void> pickSignatureImage() async {
    try {
      isBusy.value = true;
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      signaturePath.value = file.path;
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolSignPdf.tr,
        LocaleKeys.pickImagesFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }

  void clearSignature() {
    signaturePath.value = null;
  }

  Future<void> openDrawSignature() async {
    final path = await Get.toNamed(AppRoutes.signPdfDraw);
    if (path is String && path.isNotEmpty) {
      signaturePath.value = path;
    }
  }

  void onSignPressed() {
    final file = selected.value;
    if (file == null) {
      Get.snackbar(
        LocaleKeys.toolSignPdf.tr,
        LocaleKeys.signPdfNoFile.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    final sig = signaturePath.value;
    if (sig == null || sig.isEmpty) {
      Get.snackbar(
        LocaleKeys.toolSignPdf.tr,
        LocaleKeys.signPdfSignatureRequired.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    Get.toNamed(
      AppRoutes.pdfProgress,
      arguments: {
        'type': 'sign_pdf',
        'file': file,
        'signaturePath': sig,
        'settings': settings.value,
      },
    );
  }
}

class SignPdfDrawController extends GetxController {
  final strokes = <List<Offset>>[].obs;
  final currentStroke = <Offset>[].obs;
  final isBusy = false.obs;
  Size padSize = Size.zero;

  void onPanStart(DragStartDetails details) {
    currentStroke
      ..clear()
      ..add(details.localPosition);
    currentStroke.refresh();
  }

  void onPanUpdate(DragUpdateDetails details) {
    currentStroke.add(details.localPosition);
    currentStroke.refresh();
  }

  void onPanEnd(DragEndDetails details) {
    if (currentStroke.isNotEmpty) {
      strokes.add(List<Offset>.from(currentStroke));
      currentStroke.clear();
      currentStroke.refresh();
      strokes.refresh();
    }
  }

  void clear() {
    strokes.clear();
    currentStroke.clear();
  }

  bool get hasInk => strokes.isNotEmpty || currentStroke.isNotEmpty;

  Future<void> save() async {
    if (!hasInk) {
      Get.snackbar(
        LocaleKeys.toolSignPdf.tr,
        LocaleKeys.signPdfDrawEmpty.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    if (padSize.width < 1 || padSize.height < 1) return;

    try {
      isBusy.value = true;
      const pixelRatio = 3.0;
      final width = (padSize.width * pixelRatio).round();
      final height = (padSize.height * pixelRatio).round();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(pixelRatio);

      final paint = Paint()
        ..color = const Color(0xFF111111)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final allStrokes = [
        ...strokes,
        if (currentStroke.isNotEmpty) currentStroke.toList(),
      ];
      for (final stroke in allStrokes) {
        if (stroke.length < 2) {
          if (stroke.length == 1) {
            canvas.drawCircle(stroke.first, 1.6, paint);
          }
          continue;
        }
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (var i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;

      final png = data.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final out = File(
        p.join(
          dir.path,
          'signature_draw_${DateTime.now().microsecondsSinceEpoch}.png',
        ),
      );
      await out.writeAsBytes(png, flush: true);
      Get.back(result: out.path);
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolSignPdf.tr,
        LocaleKeys.signPdfDrawFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }
}
