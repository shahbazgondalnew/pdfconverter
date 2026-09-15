import 'package:flutter/material.dart';

enum ToolId {
  imageToPdf,
  wordToPdf,
  excelToPdf,
  textToPdf,
  pdfToImage,
  pdfToWord,
  pdfToText,
  mergePdf,
  splitPdf,
  compressPdf,
  rotatePdf,
  pngToJpg,
  jpgToPng,
  webpToPng,
}

class ToolItem {
  const ToolItem({
    required this.id,
    required this.titleKey,
    required this.icon,
    required this.color,
  });

  final ToolId id;
  final String titleKey;
  final IconData icon;
  final Color color;
}

class ToolSection {
  const ToolSection({
    required this.titleKey,
    required this.tools,
  });

  final String titleKey;
  final List<ToolItem> tools;
}
