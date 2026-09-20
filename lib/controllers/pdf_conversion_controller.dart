import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../models/conversion_record.dart';
import '../models/document_models.dart';
import '../models/image_to_pdf_models.dart';
import '../routes/app_routes.dart';
import '../services/excel_to_pdf_service.dart';
import '../services/html_to_pdf_service.dart';
import '../services/image_to_pdf_service.dart';
import '../services/ppt_to_pdf_service.dart';
import '../services/text_to_pdf_service.dart';
import '../services/word_to_pdf_service.dart';
import 'history_controller.dart';

class PdfProgressController extends GetxController {
  final total = 0.obs;
  final completed = 0.obs;
  final isWorking = true.obs;
  final errorMessage = RxnString();
  final progressLabel = LocaleKeys.conversionProgress.obs;

  double get progress {
    if (total.value == 0) return 0;
    return completed.value / total.value;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is! Map) {
      errorMessage.value = LocaleKeys.conversionFailed.tr;
      isWorking.value = false;
      return;
    }

    final type = args['type'] as String? ?? 'image_to_pdf';
    _start(type, args);
  }

  Future<void> _start(String type, Map args) async {
    try {
      late final ConversionRecord record;

      switch (type) {
        case 'word_to_pdf':
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final documents =
              List<SelectedDocument>.from(args['documents'] as List);
          final settings = args['settings'] as PdfPageSettings? ??
              PdfPageSettings();
          final pageTotal = documents.fold<int>(
            0,
            (sum, doc) => sum + doc.pageCount,
          );
          total.value = pageTotal > 0 ? pageTotal : documents.length;
          record = await const WordToPdfService().convert(
            documents: documents,
            settings: settings,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
        case 'excel_to_pdf':
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final documents =
              List<SelectedDocument>.from(args['documents'] as List);
          final settings = args['settings'] as PdfPageSettings? ??
              PdfPageSettings();
          final pageTotal = documents.fold<int>(
            0,
            (sum, doc) => sum + doc.pageCount,
          );
          total.value = pageTotal > 0 ? pageTotal : documents.length;
          record = await const ExcelToPdfService().convert(
            documents: documents,
            settings: settings,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
        case 'text_to_pdf':
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final documents =
              List<SelectedDocument>.from(args['documents'] as List);
          final settings = args['settings'] as PdfPageSettings? ??
              PdfPageSettings();
          final pageTotal = documents.fold<int>(
            0,
            (sum, doc) => sum + doc.pageCount,
          );
          total.value = pageTotal > 0 ? pageTotal : documents.length;
          record = await const TextToPdfService().convert(
            documents: documents,
            settings: settings,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
        case 'html_to_pdf':
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final documents =
              List<SelectedDocument>.from(args['documents'] as List);
          final settings = args['settings'] as PdfPageSettings? ??
              PdfPageSettings();
          final pageTotal = documents.fold<int>(
            0,
            (sum, doc) => sum + doc.pageCount,
          );
          total.value = pageTotal > 0 ? pageTotal : documents.length;
          record = await const HtmlToPdfService().convert(
            documents: documents,
            settings: settings,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
        case 'ppt_to_pdf':
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final pptDocs =
              List<SelectedDocument>.from(args['documents'] as List);
          final pptSettings = args['settings'] as PdfPageSettings? ??
              PdfPageSettings();
          final pptTotal = pptDocs.fold<int>(
            0,
            (sum, doc) => sum + doc.pageCount,
          );
          total.value = pptTotal > 0 ? pptTotal : pptDocs.length;
          record = await const PptToPdfService().convert(
            documents: pptDocs,
            settings: pptSettings,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
        case 'scan_to_pdf':
          progressLabel.value = LocaleKeys.conversionProgress;
          final scanImages = List<SelectedImage>.from(args['images'] as List);
          final scanSettings = args['settings'] as PdfPageSettings;
          total.value = scanImages.length;
          record = await const ImageToPdfService().convert(
            images: scanImages,
            settings: scanSettings,
            conversionType: ConversionType.scanToPdf,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
        case 'image_to_pdf':
        default:
          progressLabel.value = LocaleKeys.conversionProgress;
          final images = List<SelectedImage>.from(args['images'] as List);
          final settings = args['settings'] as PdfPageSettings;
          total.value = images.length;
          record = await const ImageToPdfService().convert(
            images: images,
            settings: settings,
            conversionType: ConversionType.imageToPdf,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
      }

      if (Get.isRegistered<HistoryController>()) {
        Get.find<HistoryController>().reload();
      }

      Get.offNamed(AppRoutes.pdfResult, arguments: record);
    } catch (_) {
      errorMessage.value = LocaleKeys.conversionFailed.tr;
      isWorking.value = false;
    }
  }
}

class PdfResultController extends GetxController {
  late final ConversionRecord record;

  @override
  void onInit() {
    super.onInit();
    record = Get.arguments as ConversionRecord;
  }
}
