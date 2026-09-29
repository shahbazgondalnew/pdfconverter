import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/section_card.dart';
import '../../../components/selected_image_grid.dart';
import '../../../controllers/compress_image_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../services/compress_image_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class CompressImageScreen extends GetView<CompressImageController> {
  const CompressImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolCompressImage.tr),
        ),
        body: Obx(() {
          final images = controller.images.toList();
          final level = controller.compressLevel.value;

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
                              LocaleKeys.compressImageHint.tr,
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
                        title: LocaleKeys.compressLevel.tr,
                        subtitle: LocaleKeys.compressLevelHint.tr,
                        child: Column(
                          children: [
                            for (final option
                                in ImageCompressLevel.values) ...[
                              if (option != ImageCompressLevel.values.first)
                                const SizedBox(height: 8),
                              _LevelTile(
                                level: option,
                                selected: level == option,
                                onTap: () =>
                                    controller.setCompressLevel(option),
                              ),
                            ],
                          ],
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
                          : controller.onCompressPressed,
                      icon: const Icon(Icons.photo_size_select_large_rounded),
                      label: Text(LocaleKeys.compressImageAction.tr),
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

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final ImageCompressLevel level;
  final bool selected;
  final VoidCallback onTap;

  String get _title {
    switch (level) {
      case ImageCompressLevel.low:
        return LocaleKeys.compressLow.tr;
      case ImageCompressLevel.medium:
        return LocaleKeys.compressMedium.tr;
      case ImageCompressLevel.high:
        return LocaleKeys.compressHigh.tr;
    }
  }

  String get _subtitle {
    switch (level) {
      case ImageCompressLevel.low:
        return LocaleKeys.compressLowHint.tr;
      case ImageCompressLevel.medium:
        return LocaleKeys.compressMediumHint.tr;
      case ImageCompressLevel.high:
        return LocaleKeys.compressHighHint.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: selected
          ? AppColors.brand.withValues(alpha: 0.12)
          : (isDark ? AppColors.darkMuted : const Color(0xFFF8F2F2)),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.brand
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFEEDFDF)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? AppColors.brand
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
