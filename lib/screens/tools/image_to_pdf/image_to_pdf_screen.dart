import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/image_fit_selector.dart';
import '../../../components/pdf_background_picker.dart';
import '../../../components/pdf_page_preview.dart';
import '../../../components/section_card.dart';
import '../../../components/selected_image_grid.dart';
import '../../../controllers/image_to_pdf_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class ImageToPdfScreen extends GetView<ImageToPdfController> {
  const ImageToPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolImageToPdf.tr),
        ),
        body: Obx(() {
          final images = controller.images.toList();
          final settings = controller.settings.value;
          final previewImage = images.isEmpty ? null : images.first;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      SectionCard(
                        title: LocaleKeys.selectedImages.tr,
                        trailing: Text(
                          '${images.length}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        child: SelectedImageGrid(
                          images: images,
                          onDelete: controller.deleteImage,
                          onEdit: controller.openEditor,
                          onAddMore: controller.addMoreImages,
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
                        subtitle: LocaleKeys.pdfBackgroundHint.tr,
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
                            child: PdfPagePreview(
                              image: previewImage,
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
