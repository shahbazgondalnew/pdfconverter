enum SignPdfPosition {
  bottomRight,
  bottomLeft,
  bottomCenter,
  topRight,
  topLeft,
  center;
}

enum SignPdfRangeMode {
  all,
  lastPage,
  firstPage,
  custom;
}

class SignPdfSettings {
  const SignPdfSettings({
    this.position = SignPdfPosition.bottomRight,
    this.rangeMode = SignPdfRangeMode.lastPage,
    this.scale = 0.28,
    this.customFrom = 1,
    this.customTo = 1,
  });

  final SignPdfPosition position;
  final SignPdfRangeMode rangeMode;
  final double scale;
  final int customFrom;
  final int customTo;

  SignPdfSettings copyWith({
    SignPdfPosition? position,
    SignPdfRangeMode? rangeMode,
    double? scale,
    int? customFrom,
    int? customTo,
  }) {
    return SignPdfSettings(
      position: position ?? this.position,
      rangeMode: rangeMode ?? this.rangeMode,
      scale: scale ?? this.scale,
      customFrom: customFrom ?? this.customFrom,
      customTo: customTo ?? this.customTo,
    );
  }

  bool shouldApply(int pageIndex, int totalPages) {
    final page = pageIndex + 1;
    switch (rangeMode) {
      case SignPdfRangeMode.all:
        return true;
      case SignPdfRangeMode.lastPage:
        return page == totalPages;
      case SignPdfRangeMode.firstPage:
        return page == 1;
      case SignPdfRangeMode.custom:
        final from = customFrom.clamp(1, totalPages);
        final to = customTo.clamp(from, totalPages);
        return page >= from && page <= to;
    }
  }
}
