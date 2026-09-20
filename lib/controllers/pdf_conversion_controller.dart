import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../models/conversion_record.dart';
import '../models/document_models.dart';
import '../models/image_to_pdf_models.dart';
import '../models/pdf_to_image_models.dart';
import '../routes/app_routes.dart';
import '../services/excel_to_pdf_service.dart';
import '../services/html_to_pdf_service.dart';
import '../services/image_to_pdf_service.dart';
import '../services/pdf_to_image_service.dart';
import '../services/ppt_to_pdf_service.dart';
import '../services/text_to_pdf_service.dart';
import '../services/word_to_pdf_service.dart';
import 'history_controller.dart';
import 'pdf_to_image_controller.dart';

class PdfProgressController extends GetxController {
  final total = 0.obs;
  final completed = 0.obs;
  final isWorking = true.obs;
  final errorMessage = RxnString();
  final progressLabel = LocaleKeys.conversionProgress.obs;
  final titleKey = LocaleKeys.convertingPdf.obs;

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
      switch (type) {
        case 'pdf_to_image_render':
          titleKey.value = LocaleKeys.convertingImages;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          await _renderPdfToImages(args);
          return;
        case 'pdf_to_image_save':
          titleKey.value = LocaleKeys.savingImages;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final pages = List<PdfPageImage>.from(args['pages'] as List);
          total.value = pages.length;
          completed.value = 0;
          final record = await const PdfToImageService().saveGroup(
            pages: pages,
          );
          completed.value = total.value;
          _finishWithResult(record);
          return;
        default:
          titleKey.value = LocaleKeys.convertingPdf;
          final record = await _convertToPdf(type, args);
          _finishWithResult(record);
      }
    } catch (_) {
      errorMessage.value = LocaleKeys.conversionFailed.tr;
      isWorking.value = false;
    }
  }

  Future<void> _renderPdfToImages(Map args) async {
    final files = List<PdfSourceFile>.from(args['pdfFiles'] as List);
    final append = args['append'] == true;
    final service = const PdfToImageService();

    var totalPages = 0;
    final counts = <int>[];
    for (final file in files) {
      final count = await service.pageCount(file.path);
      counts.add(count);
      totalPages += count;
    }
    if (totalPages == 0) {
      throw StateError('No pages found');
    }

    total.value = totalPages;
    completed.value = 0;

    final rendered = <PdfPageImage>[];
    var offset = 0;
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final pages = await service.renderPdf(
        pdfPath: file.path,
        sourceName: file.name,
        documentId: file.id,
        progressOffset: offset,
        progressTotal: totalPages,
        onProgress: (done, all) {
          completed.value = done;
          total.value = all;
        },
      );
      rendered.addAll(pages);
      offset += counts[i];
    }

    final controller = Get.isRegistered<PdfToImageController>()
        ? Get.find<PdfToImageController>()
        : Get.put(PdfToImageController(), permanent: true);
    controller.setPages(rendered, append: append);

    // Store as one history group as soon as conversion/preview is ready
    // (same idea as PDF tools saving when conversion finishes).
    try {
      await controller.persistToHistory();
    } catch (_) {
      // Preview can still continue; user can retry via Done.
    }

    if (append) {
      // Close progress and return to the existing review screen.
      Get.back();
    } else {
      Get.offNamed(AppRoutes.pdfToImage);
    }
  }

  Future<ConversionRecord> _convertToPdf(String type, Map args) async {
    switch (type) {
      case 'word_to_pdf':
        progressLabel.value = LocaleKeys.conversionProgressPages;
        final documents = List<SelectedDocument>.from(args['documents'] as List);
        final settings =
            args['settings'] as PdfPageSettings? ?? PdfPageSettings();
        final pageTotal = documents.fold<int>(
          0,
          (sum, doc) => sum + doc.pageCount,
        );
        total.value = pageTotal > 0 ? pageTotal : documents.length;
        return const WordToPdfService().convert(
          documents: documents,
          settings: settings,
          onProgress: (done, all) {
            completed.value = done;
            total.value = all;
          },
        );
      case 'excel_to_pdf':
        progressLabel.value = LocaleKeys.conversionProgressPages;
        final documents = List<SelectedDocument>.from(args['documents'] as List);
        final settings =
            args['settings'] as PdfPageSettings? ?? PdfPageSettings();
        final pageTotal = documents.fold<int>(
          0,
          (sum, doc) => sum + doc.pageCount,
        );
        total.value = pageTotal > 0 ? pageTotal : documents.length;
        return const ExcelToPdfService().convert(
          documents: documents,
          settings: settings,
          onProgress: (done, all) {
            completed.value = done;
            total.value = all;
          },
        );
      case 'text_to_pdf':
        progressLabel.value = LocaleKeys.conversionProgressPages;
        final documents = List<SelectedDocument>.from(args['documents'] as List);
        final settings =
            args['settings'] as PdfPageSettings? ?? PdfPageSettings();
        final pageTotal = documents.fold<int>(
          0,
          (sum, doc) => sum + doc.pageCount,
        );
        total.value = pageTotal > 0 ? pageTotal : documents.length;
        return const TextToPdfService().convert(
          documents: documents,
          settings: settings,
          onProgress: (done, all) {
            completed.value = done;
            total.value = all;
          },
        );
      case 'html_to_pdf':
        progressLabel.value = LocaleKeys.conversionProgressPages;
        final documents = List<SelectedDocument>.from(args['documents'] as List);
        final settings =
            args['settings'] as PdfPageSettings? ?? PdfPageSettings();
        final pageTotal = documents.fold<int>(
          0,
          (sum, doc) => sum + doc.pageCount,
        );
        total.value = pageTotal > 0 ? pageTotal : documents.length;
        return const HtmlToPdfService().convert(
          documents: documents,
          settings: settings,
          onProgress: (done, all) {
            completed.value = done;
            total.value = all;
          },
        );
      case 'ppt_to_pdf':
        progressLabel.value = LocaleKeys.conversionProgressPages;
        final pptDocs = List<SelectedDocument>.from(args['documents'] as List);
        final pptSettings =
            args['settings'] as PdfPageSettings? ?? PdfPageSettings();
        final pptTotal = pptDocs.fold<int>(
          0,
          (sum, doc) => sum + doc.pageCount,
        );
        total.value = pptTotal > 0 ? pptTotal : pptDocs.length;
        return const PptToPdfService().convert(
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
        return const ImageToPdfService().convert(
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
        return const ImageToPdfService().convert(
          images: images,
          settings: settings,
          conversionType: ConversionType.imageToPdf,
          onProgress: (done, all) {
            completed.value = done;
            total.value = all;
          },
        );
    }
  }

  void _finishWithResult(ConversionRecord record) {
    if (Get.isRegistered<HistoryController>()) {
      Get.find<HistoryController>().reload();
    }
    Get.offNamed(AppRoutes.pdfResult, arguments: record);
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
