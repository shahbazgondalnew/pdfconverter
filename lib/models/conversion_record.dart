enum ConversionType {
  imageToPdf('image_to_pdf'),
  wordToPdf('word_to_pdf'),
  excelToPdf('excel_to_pdf'),
  textToPdf('text_to_pdf'),
  htmlToPdf('html_to_pdf'),
  scanToPdf('scan_to_pdf'),
  pptToPdf('ppt_to_pdf'),
  pdfToImage('pdf_to_image');

  const ConversionType(this.storageValue);
  final String storageValue;

  static ConversionType fromStorage(String value) {
    return ConversionType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => ConversionType.imageToPdf,
    );
  }

  bool get isImageOutput => this == ConversionType.pdfToImage;
}

class ConversionRecord {
  const ConversionRecord({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.conversionType,
    required this.createdAt,
    required this.pageCount,
    this.paths = const [],
  });

  final String id;
  final String name;

  /// Primary stored filename (PDF, or first image in a group).
  final String path;

  /// Extra stored filenames for image groups (PDF → Image).
  final List<String> paths;
  final int sizeBytes;
  final ConversionType conversionType;
  final DateTime createdAt;
  final int pageCount;

  bool get isImageGroup => conversionType.isImageOutput;

  /// All relative filenames for this conversion.
  List<String> get allPaths {
    if (paths.isNotEmpty) return paths;
    if (path.isEmpty) return const [];
    return [path];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'paths': paths,
      'sizeBytes': sizeBytes,
      'conversionType': conversionType.storageValue,
      'createdAt': createdAt.toIso8601String(),
      'pageCount': pageCount,
    };
  }

  factory ConversionRecord.fromMap(Map<dynamic, dynamic> map) {
    final rawPaths = map['paths'];
    final paths = rawPaths is List
        ? rawPaths.map((e) => e.toString()).toList()
        : <String>[];

    return ConversionRecord(
      id: map['id'] as String,
      name: map['name'] as String,
      path: map['path'] as String? ?? '',
      paths: paths,
      sizeBytes: map['sizeBytes'] as int? ?? 0,
      conversionType: ConversionType.fromStorage(
        map['conversionType'] as String? ?? 'image_to_pdf',
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      pageCount: map['pageCount'] as int? ?? 0,
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  ConversionRecord copyWith({
    String? id,
    String? name,
    String? path,
    List<String>? paths,
    int? sizeBytes,
    ConversionType? conversionType,
    DateTime? createdAt,
    int? pageCount,
  }) {
    return ConversionRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      paths: paths ?? List<String>.from(this.paths),
      sizeBytes: sizeBytes ?? this.sizeBytes,
      conversionType: conversionType ?? this.conversionType,
      createdAt: createdAt ?? this.createdAt,
      pageCount: pageCount ?? this.pageCount,
    );
  }
}
