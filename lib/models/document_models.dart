class WordPage {
  WordPage({
    required this.id,
    required this.index,
    required this.paragraphs,
  });

  final String id;
  int index;
  List<String> paragraphs;

  String get previewText {
    final joined = paragraphs.join(' ').trim();
    if (joined.isEmpty) return '…';
    if (joined.length <= 140) return joined;
    return '${joined.substring(0, 140)}…';
  }

  WordPage copyWith({
    String? id,
    int? index,
    List<String>? paragraphs,
  }) {
    return WordPage(
      id: id ?? this.id,
      index: index ?? this.index,
      paragraphs: paragraphs ?? List<String>.from(this.paragraphs),
    );
  }
}

class SelectedDocument {
  SelectedDocument({
    required this.id,
    required this.path,
    required this.name,
    required this.sizeBytes,
    List<WordPage>? pages,
  }) : pages = pages ?? <WordPage>[];

  final String id;
  final String path;
  final String name;
  final int sizeBytes;
  List<WordPage> pages;

  int get pageCount => pages.length;

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }

  SelectedDocument copyWith({
    String? id,
    String? path,
    String? name,
    int? sizeBytes,
    List<WordPage>? pages,
  }) {
    return SelectedDocument(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      pages: pages ??
          this.pages.map((page) => page.copyWith()).toList(growable: true),
    );
  }
}

enum DocumentToolKind { word, excel }

class DocumentToolConfig {
  const DocumentToolConfig({
    required this.kind,
    required this.extensions,
    required this.titleKey,
    required this.addTitleKey,
    required this.selectedTitleKey,
    required this.emptyKey,
    required this.pickFailedKey,
    required this.progressUnitKey,
  });

  final DocumentToolKind kind;
  final List<String> extensions;
  final String titleKey;
  final String addTitleKey;
  final String selectedTitleKey;
  final String emptyKey;
  final String pickFailedKey;
  final String progressUnitKey;
}
