import 'package:flutter/foundation.dart';
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
import '../services/merge_pdf_service.dart';
import '../services/pdf_to_image_service.dart';
import '../services/pdf_to_word_service.dart';
import '../services/ppt_to_pdf_service.dart';
import '../services/text_to_pdf_service.dart';
import '../services/word_to_pdf_service.dart';
import 'compress_pdf_controller.dart';
import 'delete_pages_pdf_controller.dart';
import 'extract_pages_controller.dart';
import 'history_controller.dart';
import 'merge_pdf_controller.dart';
import 'pdf_to_image_controller.dart';
import 'reorder_pdf_controller.dart';
import 'rotate_pdf_controller.dart';
import 'split_pdf_controller.dart';

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
        case 'pdf_to_word':
          titleKey.value = LocaleKeys.convertingWord;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final documents =
              List<SelectedDocument>.from(args['documents'] as List);
          // Page-level progress is reported from the WebView converter.
          total.value = documents.fold<int>(
            0,
            (sum, doc) => sum + (doc.pageCount > 0 ? doc.pageCount : 1),
          );
          completed.value = 0;
          final wordRecord = await const PdfToWordService().convertDocuments(
            documents: documents,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
          completed.value = total.value;
          _finishWithResult(wordRecord);
          return;
        case 'merge_pdf_render':
          titleKey.value = LocaleKeys.convertingImages;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          await _renderMergePdfPages(args);
          return;
        case 'merge_pdf':
          titleKey.value = LocaleKeys.mergingPdf;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final mergePages = List<PdfPageImage>.from(args['pages'] as List);
          total.value = mergePages.length;
          completed.value = 0;
          final mergeRecord = await const MergePdfService().merge(
            pages: mergePages,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
          completed.value = total.value;
          _finishWithResult(mergeRecord);
          return;
        case 'split_pdf_render':
          titleKey.value = LocaleKeys.convertingImages;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          await _renderSplitPdfPages(args);
          return;
        case 'split_pdf':
          titleKey.value = LocaleKeys.splittingPdf;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final splitPages = List<PdfPageImage>.from(args['pages'] as List);
          total.value = splitPages.length;
          completed.value = 0;
          final splitRecord = await const SplitPdfService().split(
            pages: splitPages,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
          completed.value = total.value;
          if (Get.isRegistered<SplitPdfController>()) {
            Get.find<SplitPdfController>().onSplitFinished();
          }
          _finishWithResult(splitRecord);
          return;
        case 'compress_pdf_render':
          titleKey.value = LocaleKeys.convertingImages;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          await _renderCompressPdfPages(args);
          return;
        case 'compress_pdf':
          titleKey.value = LocaleKeys.compressingPdf;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final compressPages =
              List<PdfPageImage>.from(args['pages'] as List);
          final level = args['level'] as PdfCompressLevel? ??
              PdfCompressLevel.medium;
          total.value = compressPages.length;
          completed.value = 0;
          final compressRecord = await const CompressPdfService().compress(
            pages: compressPages,
            level: level,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
          completed.value = total.value;
          _finishWithResult(compressRecord);
          return;
        case 'rotate_pdf_render':
          titleKey.value = LocaleKeys.convertingImages;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          await _renderRotatePdfPages(args);
          return;
        case 'rotate_pdf':
          titleKey.value = LocaleKeys.rotatingPdf;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final rotatePages = List<PdfPageImage>.from(args['pages'] as List);
          total.value = rotatePages.length;
          completed.value = 0;
          final rotateRecord = await const RotatePdfService().rotate(
            pages: rotatePages,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
          completed.value = total.value;
          _finishWithResult(rotateRecord);
          return;
        case 'reorder_pdf_render':
          titleKey.value = LocaleKeys.convertingImages;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          await _renderReorderPdfPages(args);
          return;
        case 'reorder_pdf':
          titleKey.value = LocaleKeys.reorderingPdf;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final reorderPages = List<PdfPageImage>.from(args['pages'] as List);
          total.value = reorderPages.length;
          completed.value = 0;
          final reorderRecord = await const ReorderPdfService().reorder(
            pages: reorderPages,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
          completed.value = total.value;
          _finishWithResult(reorderRecord);
          return;
        case 'delete_pages_pdf_render':
          titleKey.value = LocaleKeys.convertingImages;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          await _renderDeletePagesPdf(args);
          return;
        case 'delete_pages_pdf':
          titleKey.value = LocaleKeys.deletingPagesPdf;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final keepPages = List<PdfPageImage>.from(args['pages'] as List);
          total.value = keepPages.length;
          completed.value = 0;
          final deleteRecord = await const DeletePagesPdfService().deletePages(
            pages: keepPages,
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
          completed.value = total.value;
          _finishWithResult(deleteRecord);
          return;
        case 'extract_pages_render':
          titleKey.value = LocaleKeys.convertingImages;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          await _renderExtractPages(args);
          return;
        case 'extract_pages':
          titleKey.value = LocaleKeys.extractingPages;
          progressLabel.value = LocaleKeys.conversionProgressPages;
          final extractPages = List<PdfPageImage>.from(args['pages'] as List);
          final format = args['format'] as ExtractImageFormat? ??
              ExtractImageFormat.png;
          total.value = extractPages.length;
          completed.value = 0;
          final extractRecord = await const PdfToImageService().saveGroup(
            pages: extractPages,
            conversionType: ConversionType.extractPages,
            format: format,
            namePrefix: 'EXTRACT',
            onProgress: (done, all) {
              completed.value = done;
              total.value = all;
            },
          );
          completed.value = total.value;
          _finishWithResult(extractRecord);
          return;
        default:
          titleKey.value = LocaleKeys.convertingPdf;
          final record = await _convertToPdf(type, args);
          _finishWithResult(record);
      }
    } catch (e, st) {
      debugPrint('Conversion error ($type): $e\n$st');
      final detail = e.toString();
      errorMessage.value = detail.contains('StateError')
          ? detail.replaceFirst('Bad state: ', '')
          : LocaleKeys.conversionFailed.tr;
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

  Future<void> _renderMergePdfPages(Map args) async {
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

    final controller = Get.isRegistered<MergePdfController>()
        ? Get.find<MergePdfController>()
        : Get.put(MergePdfController(), permanent: true);
    controller.setPages(rendered, append: append);

    if (append) {
      Get.back();
    } else {
      Get.offNamed(AppRoutes.mergePdf);
    }
  }

  Future<void> _renderSplitPdfPages(Map args) async {
    final files = List<PdfSourceFile>.from(args['pdfFiles'] as List);
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

    final controller = Get.isRegistered<SplitPdfController>()
        ? Get.find<SplitPdfController>()
        : Get.put(SplitPdfController(), permanent: true);
    controller.setPages(rendered);

    Get.offNamed(AppRoutes.splitPdf);
  }

  Future<void> _renderCompressPdfPages(Map args) async {
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

    final controller = Get.isRegistered<CompressPdfController>()
        ? Get.find<CompressPdfController>()
        : Get.put(CompressPdfController(), permanent: true);
    controller.setPages(rendered, append: append);

    if (append) {
      Get.back();
    } else {
      Get.offNamed(AppRoutes.compressPdf);
    }
  }

  Future<void> _renderRotatePdfPages(Map args) async {
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

    final controller = Get.isRegistered<RotatePdfController>()
        ? Get.find<RotatePdfController>()
        : Get.put(RotatePdfController(), permanent: true);
    controller.setPages(rendered, append: append);

    if (append) {
      Get.back();
    } else {
      Get.offNamed(AppRoutes.rotatePdf);
    }
  }

  Future<void> _renderReorderPdfPages(Map args) async {
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

    final controller = Get.isRegistered<ReorderPdfController>()
        ? Get.find<ReorderPdfController>()
        : Get.put(ReorderPdfController(), permanent: true);
    controller.setPages(rendered, append: append);

    if (append) {
      Get.back();
    } else {
      Get.offNamed(AppRoutes.reorderPdf);
    }
  }

  Future<void> _renderDeletePagesPdf(Map args) async {
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

    final controller = Get.isRegistered<DeletePagesPdfController>()
        ? Get.find<DeletePagesPdfController>()
        : Get.put(DeletePagesPdfController(), permanent: true);
    controller.setPages(rendered, append: append);

    if (append) {
      Get.back();
    } else {
      Get.offNamed(AppRoutes.deletePagesPdf);
    }
  }

  Future<void> _renderExtractPages(Map args) async {
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

    final controller = Get.isRegistered<ExtractPagesController>()
        ? Get.find<ExtractPagesController>()
        : Get.put(ExtractPagesController(), permanent: true);
    controller.setPages(rendered, append: append);

    if (append) {
      Get.back();
    } else {
      Get.offNamed(AppRoutes.extractPages);
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
    // Always refresh history so the new conversion appears like other tools.
    if (Get.isRegistered<HistoryController>()) {
      Get.find<HistoryController>().reload();
    } else {
      Get.put(HistoryController(), permanent: true).reload();
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
