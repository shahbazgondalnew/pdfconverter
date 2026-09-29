import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/section_card.dart';
import '../../../components/selected_image_grid.dart';
import '../../../controllers/png_to_jpg_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class PngToJpgScreen extends GetView<PngToJpgController> {
  const PngToJpgScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolPngToJpg.tr),
        ),
        body: Obx(() {
          final images = controller.images.toList();
          final quality = controller.quality.value;

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocaleKeys.pngToJpgHint.tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            SelectedImageGrid(
                              images: images,
                              onDelete: controller.deleteImage,
                              onEdit: controller.openEditor,
                              onAddMore: controller.addMoreImages,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.pngToJpgQuality.tr,
                        subtitle: LocaleKeys.pngToJpgQualityHint.trParams({
                          'value': '${quality.round()}',
                        }),
                        child: Slider(
                          value: quality,
                          min: 40,
                          max: 100,
                          divisions: 12,
                          activeColor: AppColors.brand,
                          onChanged: controller.setQuality,
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
                          : controller.onConvertPressed,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: Text(LocaleKeys.pngToJpgConvert.tr),
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
