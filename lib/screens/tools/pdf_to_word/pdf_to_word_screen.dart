import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/section_card.dart';
import '../../../components/selected_document_grid.dart';
import '../../../controllers/pdf_to_word_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class PdfToWordScreen extends GetView<PdfToWordController> {
  const PdfToWordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolPdfToWord.tr),
        ),
        body: Obx(() {
          final docs = controller.documents.toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SectionCard(
                    title: LocaleKeys.selectedPdfFiles.tr,
                    trailing: Text(
                      '${docs.length}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    child: SelectedDocumentGrid(
                      documents: docs,
                      onDelete: controller.deleteDocument,
                      onAddMore: controller.addMoreDocuments,
                      emptyLabel: LocaleKeys.noPdfSelected.tr,
                      icon: Icons.picture_as_pdf_rounded,
                      showPageCount: true,
                    ),
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
                          : controller.onCreateWordPressed,
                      icon: const Icon(Icons.description_outlined),
                      label: Text(LocaleKeys.createWord.tr),
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
