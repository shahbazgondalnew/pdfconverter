import 'package:flutter/material.dart';

enum WatermarkType {
  text,
  image;
}

enum WatermarkPosition {
  center,
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight;
}

enum WatermarkLayout {
  single,
  tiled;
}

enum WatermarkRangeMode {
  all,
  skipCover,
  custom;
}

class WatermarkSettings {
  const WatermarkSettings({
    this.type = WatermarkType.text,
    this.text = 'CONFIDENTIAL',
    this.imagePath,
    this.position = WatermarkPosition.center,
    this.layout = WatermarkLayout.single,
    this.opacity = 0.28,
    this.rotation = -35,
    this.fontSize = 42,
    this.colorValue = 0xFF9E9E9E,
    this.bold = true,
    this.imageScale = 0.35,
    this.rangeMode = WatermarkRangeMode.all,
    this.customFrom = 1,
    this.customTo = 1,
  });

  final WatermarkType type;
  final String text;
  final String? imagePath;
  final WatermarkPosition position;
  final WatermarkLayout layout;
  final double opacity;
  final double rotation;
  final double fontSize;
  final int colorValue;
  final bool bold;
  final double imageScale;
  final WatermarkRangeMode rangeMode;
  final int customFrom;
  final int customTo;

  Color get color => Color(colorValue);

  bool get hasContent {
    switch (type) {
      case WatermarkType.text:
        return text.trim().isNotEmpty;
      case WatermarkType.image:
        return imagePath != null && imagePath!.isNotEmpty;
    }
  }

  WatermarkSettings copyWith({
    WatermarkType? type,
    String? text,
    String? imagePath,
    bool clearImage = false,
    WatermarkPosition? position,
    WatermarkLayout? layout,
    double? opacity,
    double? rotation,
    double? fontSize,
    int? colorValue,
    bool? bold,
    double? imageScale,
    WatermarkRangeMode? rangeMode,
    int? customFrom,
    int? customTo,
  }) {
    return WatermarkSettings(
      type: type ?? this.type,
      text: text ?? this.text,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      position: position ?? this.position,
      layout: layout ?? this.layout,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
      bold: bold ?? this.bold,
      imageScale: imageScale ?? this.imageScale,
      rangeMode: rangeMode ?? this.rangeMode,
      customFrom: customFrom ?? this.customFrom,
      customTo: customTo ?? this.customTo,
    );
  }

  bool shouldApply(int pageIndex, int totalPages) {
    final page = pageIndex + 1;
    switch (rangeMode) {
      case WatermarkRangeMode.all:
        return true;
      case WatermarkRangeMode.skipCover:
        return page > 1;
      case WatermarkRangeMode.custom:
        final from = customFrom.clamp(1, totalPages);
        final to = customTo.clamp(from, totalPages);
        return page >= from && page <= to;
    }
  }

  static const textPresets = <String>[
    'CONFIDENTIAL',
    'DRAFT',
    'COPY',
    'SAMPLE',
    'DO NOT COPY',
  ];

  static const colorPresets = <int>[
    0xFF9E9E9E,
    0xFF212121,
    0xFFE53935,
    0xFF1E88E5,
    0xFF43A047,
    0xFF6A1B9A,
    0xFFFFFFFF,
  ];

  static const rotationPresets = <double>[-45, -35, -20, 0, 20, 35, 45];
}
