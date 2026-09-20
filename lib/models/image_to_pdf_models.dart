import 'package:flutter/material.dart';

class SelectedImage {
  SelectedImage({
    required this.id,
    required this.path,
    this.rotation = 0,
  });

  final String id;
  String path;
  int rotation;

  SelectedImage copyWith({
    String? id,
    String? path,
    int? rotation,
  }) {
    return SelectedImage(
      id: id ?? this.id,
      path: path ?? this.path,
      rotation: rotation ?? this.rotation,
    );
  }
}

enum ImageFitMode {
  center,
  contain,
  cover,
  fill,
  fitWidth,
  fitHeight,
}

enum PdfBackgroundOption {
  white,
  black,
  gray,
  custom,
}

class PdfPageSettings {
  PdfPageSettings({
    this.fitMode = ImageFitMode.contain,
    this.backgroundOption = PdfBackgroundOption.white,
    this.customBackground = Colors.white,
  });

  ImageFitMode fitMode;
  PdfBackgroundOption backgroundOption;
  Color customBackground;

  Color get backgroundColor {
    switch (backgroundOption) {
      case PdfBackgroundOption.white:
        return Colors.white;
      case PdfBackgroundOption.black:
        return Colors.black;
      case PdfBackgroundOption.gray:
        return const Color(0xFFE0E0E0);
      case PdfBackgroundOption.custom:
        return customBackground;
    }
  }

  /// Readable text color against [backgroundColor].
  Color get contrastingTextColor {
    return backgroundColor.computeLuminance() < 0.45
        ? Colors.white
        : const Color(0xFF1A1A1A);
  }

  BoxFit get boxFit {
    switch (fitMode) {
      case ImageFitMode.center:
        return BoxFit.none;
      case ImageFitMode.contain:
        return BoxFit.contain;
      case ImageFitMode.cover:
        return BoxFit.cover;
      case ImageFitMode.fill:
        return BoxFit.fill;
      case ImageFitMode.fitWidth:
        return BoxFit.fitWidth;
      case ImageFitMode.fitHeight:
        return BoxFit.fitHeight;
    }
  }
}
