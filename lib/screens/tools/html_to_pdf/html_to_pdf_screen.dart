import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/image_fit_selector.dart';
import '../../../components/pdf_background_picker.dart';
import '../../../components/section_card.dart';
import '../../../components/selected_document_grid.dart';
import '../../../components/word_pdf_preview.dart';
import '../../../controllers/html_to_pdf_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class HtmlToPdfScreen extends GetView<HtmlToPdfController> {
  const HtmlToPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolHtmlToPdf.tr),
        ),
        body: Obx(() {
          final docs = controller.documents.toList();
          final settings = controller.settings.value;
          final previewDoc = docs.isEmpty ? null : docs.first;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      SectionCard(
                        title: LocaleKeys.pasteHtml.tr,
                        subtitle: LocaleKeys.pasteHtmlHint.tr,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: controller.pasteController,
                              autofocus: controller.focusPaste.value,
                              minLines: 5,
                              maxLines: 10,
                              textInputAction: TextInputAction.newline,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                  ),
                              decoration: InputDecoration(
                                hintText: LocaleKeys.pasteHtmlPlaceholder.tr,
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkMuted
                                    : AppColors.brandSoft.withValues(
                                        alpha: 0.45,
                                      ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonalIcon(
                                onPressed: controller.addPastedHtml,
                                icon: const Icon(Icons.add_rounded),
                                label: Text(LocaleKeys.addPastedHtml.tr),
                                style: FilledButton.styleFrom(
                                  foregroundColor: AppColors.brand,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.selectedHtmlItems.tr,
                        trailing: Text(
                          '${docs.length}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        child: SelectedDocumentGrid(
                          documents: docs,
                          onDelete: controller.deleteDocument,
                          onEdit: controller.openEditor,
                          onAddMore: controller.addMoreDocuments,
                          emptyLabel: LocaleKeys.noHtmlSelected.tr,
                          icon: Icons.code,
                          showPageCount: true,
                          pageCountKey: LocaleKeys.wordPages,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.fitSettings.tr,
                        child: ImageFitSelector(
                          value: settings.fitMode,
                          onChanged: controller.setFitMode,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.pdfBackground.tr,
                        subtitle: LocaleKeys.htmlBackgroundHint.tr,
                        child: PdfBackgroundPicker(
                          option: settings.backgroundOption,
                          customColor: settings.customBackground,
                          onOptionChanged: controller.setBackgroundOption,
                          onCustomColorChanged: controller.setCustomBackground,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.preview.tr,
                        child: Center(
                          child: SizedBox(
                            width: 180,
                            child: WordPdfPreview(
                              document: previewDoc,
                              settings: settings,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: controller.isBusy.value
                          ? null
                          : controller.onCreatePdfPressed,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(LocaleKeys.createPdf.tr),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
