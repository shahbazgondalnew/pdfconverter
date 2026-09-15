import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
        ),
        ToolItem(
          id: ToolId.jpgToPng,
          titleKey: LocaleKeys.toolJpgToPng,
          icon: Icons.swap_vert,
          color: Color(0xFF7CB342),
        ),
        ToolItem(
          id: ToolId.webpToPng,
          titleKey: LocaleKeys.toolWebpToPng,
          icon: Icons.transform,
          color: Color(0xFF546E7A),
        ),
      ],
    ),
  ];

  void onToolTap(ToolItem tool) {
    Get.snackbar(
      tool.titleKey.tr,
      LocaleKeys.toolComingSoon.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }
}
