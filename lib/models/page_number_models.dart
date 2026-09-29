import 'package:flutter/material.dart';

enum PageNumberFormat {
  plain,
  withTotal,
  pagePrefix,
  dashed,
  roman;

  String sample(int number, int total) => format(number, total);

  String format(int number, int total) {
    switch (this) {
      case PageNumberFormat.plain:
        return '$number';
      case PageNumberFormat.withTotal:
        return '$number/$total';
      case PageNumberFormat.pagePrefix:
        return 'Page $number';
      case PageNumberFormat.dashed:
        return '- $number -';
      case PageNumberFormat.roman:
        return _toRoman(number).toLowerCase();
    }
  }

  static String _toRoman(int value) {
    if (value <= 0) return '0';
    const pairs = <(int, String)>[
      (1000, 'M'),
      (900, 'CM'),
      (500, 'D'),
      (400, 'CD'),
      (100, 'C'),
      (90, 'XC'),
      (50, 'L'),
      (40, 'XL'),
      (10, 'X'),
      (9, 'IX'),
      (5, 'V'),
      (4, 'IV'),
      (1, 'I'),
    ];
    var n = value;
    final buffer = StringBuffer();
    for (final (v, s) in pairs) {
      while (n >= v) {
        buffer.write(s);
        n -= v;
      }
    }
    return buffer.toString();
  }
}

enum PageNumberPosition {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight;
}

enum PageNumberRangeMode {
  all,
  skipCover,
  custom;
}

class PageNumberSettings {
  const PageNumberSettings({
    this.format = PageNumberFormat.plain,
    this.position = PageNumberPosition.bottomCenter,
    this.fontSize = 16,
    this.colorValue = 0xFF212121,
    this.bold = false,
    this.rangeMode = PageNumberRangeMode.all,
    this.customFrom = 1,
    this.customTo = 1,
    this.startNumber = 1,
  });

  final PageNumberFormat format;
  final PageNumberPosition position;
  final double fontSize;
  final int colorValue;
  final bool bold;
  final PageNumberRangeMode rangeMode;
  final int customFrom;
  final int customTo;
  final int startNumber;

  Color get color => Color(colorValue);

  PageNumberSettings copyWith({
    PageNumberFormat? format,
    PageNumberPosition? position,
    double? fontSize,
    int? colorValue,
    bool? bold,
    PageNumberRangeMode? rangeMode,
    int? customFrom,
    int? customTo,
    int? startNumber,
  }) {
    return PageNumberSettings(
      format: format ?? this.format,
      position: position ?? this.position,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
      bold: bold ?? this.bold,
      rangeMode: rangeMode ?? this.rangeMode,
      customFrom: customFrom ?? this.customFrom,
      customTo: customTo ?? this.customTo,
      startNumber: startNumber ?? this.startNumber,
    );
  }

  /// Whether [pageIndex] (0-based) should receive a page number.
  bool shouldNumber(int pageIndex, int totalPages) {
    final page = pageIndex + 1;
    switch (rangeMode) {
      case PageNumberRangeMode.all:
        return true;
      case PageNumberRangeMode.skipCover:
        return page > 1;
      case PageNumberRangeMode.custom:
        final from = customFrom.clamp(1, totalPages);
        final to = customTo.clamp(from, totalPages);
        return page >= from && page <= to;
    }
  }

  /// Display number for [pageIndex] (0-based).
  int displayNumber(int pageIndex, int totalPages) {
    switch (rangeMode) {
      case PageNumberRangeMode.all:
        return startNumber + pageIndex;
      case PageNumberRangeMode.skipCover:
        return startNumber + (pageIndex - 1);
      case PageNumberRangeMode.custom:
        final from = customFrom.clamp(1, totalPages);
        return startNumber + (pageIndex - (from - 1));
    }
  }

  String labelFor(int pageIndex, int totalPages) {
    if (!shouldNumber(pageIndex, totalPages)) return '';
    final n = displayNumber(pageIndex, totalPages);
    return format.format(n, totalPages);
  }

  static const colorPresets = <int>[
    0xFF212121,
    0xFFFFFFFF,
    0xFFE53935,
    0xFF1E88E5,
    0xFF43A047,
    0xFF6A1B9A,
    0xFF546E7A,
  ];
}
