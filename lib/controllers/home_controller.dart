import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/compress_pdf_controller.dart';
import '../controllers/delete_pages_pdf_controller.dart';
import '../controllers/extract_pages_controller.dart';
import '../controllers/excel_to_pdf_controller.dart';
import '../controllers/html_to_pdf_controller.dart';
import '../controllers/image_to_pdf_controller.dart';
import '../controllers/merge_pdf_controller.dart';
import '../controllers/pdf_to_image_controller.dart';
import '../controllers/pdf_to_word_controller.dart';
import '../controllers/ppt_to_pdf_controller.dart';
import '../controllers/reorder_pdf_controller.dart';
import '../controllers/rotate_pdf_controller.dart';
import '../controllers/scan_to_pdf_controller.dart';
import '../controllers/split_pdf_controller.dart';
import '../controllers/text_to_pdf_controller.dart';
import '../controllers/word_to_pdf_controller.dart';
import '../localization/locale_keys.dart';
import '../models/tool_models.dart';

class HomeController extends GetxController {
  final sections = const <ToolSection>[
    ToolSection(
      titleKey: LocaleKeys.sectionConvertToPdf,
      tools: [
        ToolItem(
          id: ToolId.imageToPdf,
          titleKey: LocaleKeys.toolImageToPdf,
          icon: Icons.image_outlined,
          color: Color(0xFFE53935),
        ),
        ToolItem(
          id: ToolId.wordToPdf,
          titleKey: LocaleKeys.toolWordToPdf,
          icon: Icons.description_outlined,
          color: Color(0xFF1E88E5),
        ),
        ToolItem(
          id: ToolId.excelToPdf,
          titleKey: LocaleKeys.toolExcelToPdf,
          icon: Icons.table_chart_outlined,
          color: Color(0xFF43A047),
        ),
        ToolItem(
          id: ToolId.textToPdf,
          titleKey: LocaleKeys.toolTextToPdf,
          icon: Icons.notes_outlined,
          color: Color(0xFF8E24AA),
        ),
        ToolItem(
          id: ToolId.pptToPdf,
          titleKey: LocaleKeys.toolPptToPdf,
          icon: Icons.slideshow_outlined,
          color: Color(0xFFE64A19),
        ),
        ToolItem(
          id: ToolId.htmlToPdf,
          titleKey: LocaleKeys.toolHtmlToPdf,
          icon: Icons.code,
          color: Color(0xFF00838F),
        ),
        ToolItem(
          id: ToolId.scanToPdf,
          titleKey: LocaleKeys.toolScanToPdf,
          icon: Icons.document_scanner_outlined,
          color: Color(0xFF6A1B9A),
        ),
      ],
    ),
    ToolSection(
      titleKey: LocaleKeys.sectionConvertFromPdf,
      tools: [
        ToolItem(
          id: ToolId.pdfToImage,
          titleKey: LocaleKeys.toolPdfToImage,
          icon: Icons.photo_library_outlined,
          color: Color(0xFFFB8C00),
        ),
        ToolItem(
          id: ToolId.pdfToWord,
          titleKey: LocaleKeys.toolPdfToWord,
          icon: Icons.article_outlined,
          color: Color(0xFF3949AB),
        ),
        ToolItem(
          id: ToolId.pdfToText,
          titleKey: LocaleKeys.toolPdfToText,
          icon: Icons.text_snippet_outlined,
          color: Color(0xFF00897B),
          comingSoon: true,
        ),
        ToolItem(
          id: ToolId.pdfToExcel,
          titleKey: LocaleKeys.toolPdfToExcel,
          icon: Icons.grid_on_outlined,
          color: Color(0xFF2E7D32),
          comingSoon: true,
        ),
        ToolItem(
          id: ToolId.pdfToPpt,
          titleKey: LocaleKeys.toolPdfToPpt,
          icon: Icons.present_to_all_outlined,
          color: Color(0xFFD84315),
          comingSoon: true,
        ),
        ToolItem(
          id: ToolId.pdfToHtml,
          titleKey: LocaleKeys.toolPdfToHtml,
          icon: Icons.language,
          color: Color(0xFF0277BD),
          comingSoon: true,
        ),
      ],
    ),
    ToolSection(
      titleKey: LocaleKeys.sectionOrganizePdf,
      tools: [
        ToolItem(
          id: ToolId.mergePdf,
          titleKey: LocaleKeys.toolMergePdf,
          icon: Icons.merge_type,
          color: Color(0xFFD81B60),
        ),
        ToolItem(
          id: ToolId.splitPdf,
          titleKey: LocaleKeys.toolSplitPdf,
          icon: Icons.call_split,
          color: Color(0xFF5E35B1),
        ),
        ToolItem(
          id: ToolId.compressPdf,
          titleKey: LocaleKeys.toolCompressPdf,
          icon: Icons.compress,
          color: Color(0xFF00ACC1),
        ),
        ToolItem(
          id: ToolId.rotatePdf,
          titleKey: LocaleKeys.toolRotatePdf,
          icon: Icons.rotate_right,
          color: Color(0xFF6D4C41),
        ),
        ToolItem(
          id: ToolId.reorderPages,
          titleKey: LocaleKeys.toolReorderPages,
          icon: Icons.swap_vert,
          color: Color(0xFFAD1457),
        ),
        ToolItem(
          id: ToolId.deletePages,
          titleKey: LocaleKeys.toolDeletePages,
          icon: Icons.delete_outline,
          color: Color(0xFFC62828),
        ),
        ToolItem(
          id: ToolId.extractPages,
          titleKey: LocaleKeys.toolExtractPages,
          icon: Icons.content_cut,
          color: Color(0xFF4527A0),
        ),
        ToolItem(
          id: ToolId.pageNumbers,
          titleKey: LocaleKeys.toolPageNumbers,
          icon: Icons.format_list_numbered,
          color: Color(0xFF1565C0),
          comingSoon: true,
        ),
        ToolItem(
          id: ToolId.watermark,
          titleKey: LocaleKeys.toolWatermark,
          icon: Icons.branding_watermark_outlined,
          color: Color(0xFF455A64),
          comingSoon: true,
        ),
      ],
    ),
    ToolSection(
      titleKey: LocaleKeys.sectionImageTools,
      tools: [
        ToolItem(
          id: ToolId.pngToJpg,
          titleKey: LocaleKeys.toolPngToJpg,
          icon: Icons.swap_horiz,
          color: Color(0xFFF4511E),
          comingSoon: true,
        ),
        ToolItem(
          id: ToolId.jpgToPng,
          titleKey: LocaleKeys.toolJpgToPng,
          icon: Icons.image_aspect_ratio,
          color: Color(0xFF7CB342),
          comingSoon: true,
        ),
        ToolItem(
          id: ToolId.webpToPng,
          titleKey: LocaleKeys.toolWebpToPng,
          icon: Icons.transform,
          color: Color(0xFF546E7A),
          comingSoon: true,
        ),
        ToolItem(
          id: ToolId.heicToJpg,
          titleKey: LocaleKeys.toolHeicToJpg,
          icon: Icons.photo_camera_back_outlined,
          color: Color(0xFFEF6C00),
          comingSoon: true,
        ),
        ToolItem(
          id: ToolId.compressImage,
          titleKey: LocaleKeys.toolCompressImage,
          icon: Icons.photo_size_select_large,
          color: Color(0xFF009688),
          comingSoon: true,
        ),
        ToolItem(
          id: ToolId.cropImage,
          titleKey: LocaleKeys.toolCropImage,
          icon: Icons.crop,
          color: Color(0xFF7B1FA2),
          comingSoon: true,
        ),
      ],
    ),
    ToolSection(
      titleKey: LocaleKeys.sectionProtectPdf,
      tools: [
        ToolItem(
          id: ToolId.lockPdf,
          titleKey: LocaleKeys.toolLockPdf,
          icon: Icons.lock_outline,
          color: Color(0xFFC62828),
          comingSoon: true,
        ),
        ToolItem(
          id: ToolId.unlockPdf,
          titleKey: LocaleKeys.toolUnlockPdf,
          icon: Icons.lock_open,
          color: Color(0xFF2E7D32),
          comingSoon: true,
        ),
        ToolItem(
          id: ToolId.signPdf,
          titleKey: LocaleKeys.toolSignPdf,
          icon: Icons.draw_outlined,
          color: Color(0xFF283593),
          comingSoon: true,
        ),
      ],
    ),
  ];

  void onToolTap(ToolItem tool) {
    if (tool.comingSoon) {
      Get.snackbar(
        tool.titleKey.tr,
        LocaleKeys.toolComingSoon.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    switch (tool.id) {
      case ToolId.imageToPdf:
        ImageToPdfController.startFromHome();
        return;
      case ToolId.wordToPdf:
        WordToPdfController.startFromHome();
        return;
      case ToolId.excelToPdf:
        ExcelToPdfController.startFromHome();
        return;
      case ToolId.textToPdf:
        TextToPdfController.startFromHome();
        return;
      case ToolId.htmlToPdf:
        HtmlToPdfController.startFromHome();
        return;
      case ToolId.pptToPdf:
        PptToPdfController.startFromHome();
        return;
      case ToolId.scanToPdf:
        ScanToPdfController.startFromHome();
        return;
      case ToolId.pdfToImage:
        PdfToImageController.startFromHome();
        return;
      case ToolId.pdfToWord:
        PdfToWordController.startFromHome();
        return;
      case ToolId.mergePdf:
        MergePdfController.startFromHome();
        return;
      case ToolId.splitPdf:
        SplitPdfController.startFromHome();
        return;
      case ToolId.compressPdf:
        CompressPdfController.startFromHome();
        return;
      case ToolId.rotatePdf:
        RotatePdfController.startFromHome();
        return;
      case ToolId.reorderPages:
        ReorderPdfController.startFromHome();
        return;
      case ToolId.deletePages:
        DeletePagesPdfController.startFromHome();
        return;
      case ToolId.extractPages:
        ExtractPagesController.startFromHome();
        return;
      default:
        Get.snackbar(
          tool.titleKey.tr,
          LocaleKeys.toolComingSoon.tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 2),
        );
    }
  }
}
