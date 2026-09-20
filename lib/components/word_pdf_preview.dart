import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../models/document_models.dart';
import '../models/image_to_pdf_models.dart';
import '../theme/app_colors.dart';

/// Preview of how Word content will sit on a PDF page.
class WordPdfPreview extends StatelessWidget {
  const WordPdfPreview({
    super.key,
    required this.document,
    required this.settings,
    this.height = 180,
  });

  final SelectedDocument? document;
  final PdfPageSettings settings;
  final double height;

  @override
  Widget build(BuildContext context) {
    final page =
        document?.pages.isNotEmpty == true ? document!.pages.first : null;

    return WordPageThumbnail(
      page: page,
      documentName: document?.name,
      settings: settings,
      footerLabel: document == null
          ? null
          : LocaleKeys.wordPages.trParams({
              'count': '${document!.pageCount}',
            }),
      emptyIcon: Icons.description_outlined,
    );
  }
}

/// Single A4-style page thumbnail used in preview and edit screens.
class WordPageThumbnail extends StatelessWidget {
  const WordPageThumbnail({
    super.key,
    required this.page,
    required this.settings,
    this.documentName,
    this.footerLabel,
    this.pageNumber,
    this.emptyIcon = Icons.description_outlined,
    this.showFullText = false,
  });

  final WordPage? page;
  final PdfPageSettings settings;
  final String? documentName;
  final String? footerLabel;
  final int? pageNumber;
  final IconData emptyIcon;
  final bool showFullText;

  EdgeInsets get _padding {
    switch (settings.fitMode) {
      case ImageFitMode.center:
        return const EdgeInsets.all(18);
      case ImageFitMode.contain:
        return const EdgeInsets.all(14);
      case ImageFitMode.cover:
        return const EdgeInsets.all(10);
      case ImageFitMode.fill:
        return const EdgeInsets.all(6);
      case ImageFitMode.fitWidth:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 14);
      case ImageFitMode.fitHeight:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
    }
  }

  TextAlign get _align {
    switch (settings.fitMode) {
      case ImageFitMode.center:
        return TextAlign.center;
      case ImageFitMode.fill:
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  double get _fontSize {
    switch (settings.fitMode) {
      case ImageFitMode.center:
        return 7.5;
      case ImageFitMode.contain:
        return 8.5;
      case ImageFitMode.cover:
        return 9;
      case ImageFitMode.fill:
        return 8;
      case ImageFitMode.fitWidth:
        return 9;
      case ImageFitMode.fitHeight:
        return 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = settings.contrastingTextColor;
    final body = page == null
        ? ''
        : showFullText
            ? page!.paragraphs.join('\n\n')
            : page!.previewText;

    return AspectRatio(
      aspectRatio: 210 / 297,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: settings.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: page == null
              ? Center(
                  child: Icon(
                    emptyIcon,
                    color: AppColors.brand.withValues(alpha: 0.35),
                    size: 32,
                  ),
                )
              : Stack(
                  children: [
                    Padding(
                      padding: _padding,
                      child: Column(
                        crossAxisAlignment: _align == TextAlign.center
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.start,
                        children: [
                          if (documentName != null) ...[
                            Text(
                              documentName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 6.5,
                                fontWeight: FontWeight.w700,
                                color: textColor.withValues(alpha: 0.55),
                              ),
                            ),
                            const SizedBox(height: 5),
                          ],
                          Expanded(
                            child: Text(
                              body,
                              textAlign: _align,
                              maxLines: showFullText ? 22 : 14,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: _fontSize,
                                height: 1.35,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (footerLabel != null)
                            Text(
                              footerLabel!,
                              style: TextStyle(
                                fontSize: 6.5,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (pageNumber != null)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$pageNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
