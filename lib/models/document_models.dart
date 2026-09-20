class WordPage {
  WordPage({
    required this.id,
    required this.index,
    List<String>? paragraphs,
    List<List<String>>? rows,
    List<String>? blockKinds,
    this.title,
  })  : paragraphs = paragraphs ?? <String>[],
        rows = rows ?? <List<String>>[],
        blockKinds = blockKinds ?? <String>[];

  final String id;
  int index;
  String? title;
  List<String> paragraphs;
  List<List<String>> rows;
  /// Parallel to [paragraphs]: `p`, `h1`, `h2`, `h3`, `li`, `pre`, `quote`.
  List<String> blockKinds;

  bool get isTable => rows.isNotEmpty;

  String get displayTitle => title?.trim().isNotEmpty == true
      ? title!
      : 'Page ${index + 1}';

  String kindAt(int index) {
    if (index < 0 || index >= blockKinds.length) return 'p';
    return blockKinds[index];
  }

  String get previewText {
    if (isTable) {
      final lines = rows.take(6).map((row) {
        final cells =
            row.take(5).map((cell) => cell.trim()).where((c) => c.isNotEmpty);
        return cells.join(' · ');
      }).where((line) => line.isNotEmpty);
      final joined = lines.join('\n').trim();
      if (joined.isEmpty) return '…';
      if (joined.length <= 160) return joined;
      return '${joined.substring(0, 160)}…';
    }

    final joined = paragraphs.join(' ').trim();
    if (joined.isEmpty) return '…';
    if (joined.length <= 140) return joined;
    return '${joined.substring(0, 140)}…';
  }

  WordPage copyWith({
    String? id,
    int? index,
    String? title,
    List<String>? paragraphs,
    List<List<String>>? rows,
    List<String>? blockKinds,
  }) {
    return WordPage(
      id: id ?? this.id,
      index: index ?? this.index,
      title: title ?? this.title,
      paragraphs: paragraphs ?? List<String>.from(this.paragraphs),
      rows: rows ??
          this.rows.map((row) => List<String>.from(row)).toList(growable: true),
      blockKinds: blockKinds ?? List<String>.from(this.blockKinds),
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
