import 'package:flutter/material.dart';

enum ToolId {
  // Convert to PDF
  imageToPdf,
  wordToPdf,
  excelToPdf,
  textToPdf,
  pptToPdf,
  htmlToPdf,
  scanToPdf,
  // Convert from PDF
  pdfToImage,
  pdfToWord,
  pdfToText,
  pdfToExcel,
  pdfToPpt,
  pdfToHtml,
  // Organize PDF
  mergePdf,
  splitPdf,
  compressPdf,
  rotatePdf,
  reorderPages,
  deletePages,
  extractPages,
  pageNumbers,
  watermark,
  // Image tools
  pngToJpg,
  jpgToPng,
  webpToPng,
  heicToJpg,
  compressImage,
  cropImage,
  // Protect & edit
  lockPdf,
  unlockPdf,
  signPdf,
}

class ToolItem {
  const ToolItem({
    required this.id,
    required this.titleKey,
    required this.icon,
    required this.color,
    this.comingSoon = false,
  });

  final ToolId id;
  final String titleKey;
  final IconData icon;
  final Color color;
  final bool comingSoon;
}

class ToolSection {
  const ToolSection({
    required this.titleKey,
    required this.tools,
  });

  final String titleKey;
  final List<ToolItem> tools;
}
