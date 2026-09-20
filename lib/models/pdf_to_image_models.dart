class PdfSourceFile {
  PdfSourceFile({
    required this.id,
    required this.path,
    required this.name,
  });

  final String id;
  final String path;
  final String name;
}

class PdfPageImage {
  PdfPageImage({
    required this.id,
    required this.path,
    required this.sourceName,
    required this.pageNumber,
    this.rotation = 0,
  });

  final String id;
  String path;
  final String sourceName;
  final int pageNumber;
  int rotation;

  PdfPageImage copyWith({
    String? id,
    String? path,
    String? sourceName,
    int? pageNumber,
    int? rotation,
  }) {
    return PdfPageImage(
      id: id ?? this.id,
      path: path ?? this.path,
      sourceName: sourceName ?? this.sourceName,
      pageNumber: pageNumber ?? this.pageNumber,
      rotation: rotation ?? this.rotation,
    );
  }
}
