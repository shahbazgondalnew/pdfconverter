import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/word_pdf_preview.dart';
import '../../../controllers/ppt_edit_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../models/document_models.dart';
import '../../../models/image_to_pdf_models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class PptEditScreen extends GetView<PptEditController> {
  const PptEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.editPptSlides.tr),
          actions: [
            TextButton(
              onPressed: controller.save,
              child: Text(
                LocaleKeys.save.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        body: Obx(() {
          final doc = controller.draft.value;
          if (doc == null) {
            return Center(child: Text(LocaleKeys.noPptSelected.tr));
          }

          final settings = controller.settings;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  '${doc.name} · ${LocaleKeys.pptSlides.trParams({
                        'count': '${doc.pages.length}',
                      })}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  LocaleKeys.editPptSlidesHint.tr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: doc.pages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final page = doc.pages[index];
                    return _PptSlideCard(
                      pageNumber: index + 1,
                      page: page,
                      documentName: doc.name,
                      settings: settings,
                      onRemove: () => controller.removePage(page.id),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _PptSlideCard extends StatelessWidget {
  const _PptSlideCard({
    required this.pageNumber,
    required this.page,
    required this.documentName,
    required this.settings,
    required this.onRemove,
  });

  final int pageNumber;
  final WordPage page;
  final String documentName;
  final PdfPageSettings settings;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        WordPageThumbnail(
          page: page,
          documentName: documentName,
          settings: settings,
          pageNumber: pageNumber,
          showFullText: true,
          aspectRatio: 16 / 9,
          emptyIcon: Icons.slideshow_outlined,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Tooltip(
                message: LocaleKeys.removePage.tr,
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              page.title ??
                  LocaleKeys.slideLabel.trParams({'number': '$pageNumber'}),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
