import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/section_card.dart';
import '../../../controllers/compress_pdf_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../models/pdf_to_image_models.dart';
import '../../../services/merge_pdf_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class CompressPdfScreen extends GetView<CompressPdfController> {
  const CompressPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolCompressPdf.tr),
        ),
        body: Obx(() {
          final pages = controller.pages.toList();
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
                        title: LocaleKeys.selectedPages.tr,
                        trailing: Text(
                          '${pages.length}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        child: pages.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    LocaleKeys.noPagesSelected.tr,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              )
                            : _PageGrid(
                                pages: pages,
                                onDelete: controller.deletePage,
                                onEdit: controller.openEditor,
                                onAddMore: controller.addMorePdfs,
                              ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.compressLevel.tr,
                        subtitle: LocaleKeys.compressLevelHint.tr,
                        child: Column(
                          children: [
                            for (final option in PdfCompressLevel.values) ...[
                              if (option != PdfCompressLevel.values.first)
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
                      icon: const Icon(Icons.compress_rounded),
                      label: Text(LocaleKeys.compressPdfAction.tr),
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

  final PdfCompressLevel level;
  final bool selected;
  final VoidCallback onTap;

  String get _title {
    switch (level) {
      case PdfCompressLevel.low:
        return LocaleKeys.compressLow.tr;
      case PdfCompressLevel.medium:
        return LocaleKeys.compressMedium.tr;
      case PdfCompressLevel.high:
        return LocaleKeys.compressHigh.tr;
    }
  }

  String get _subtitle {
    switch (level) {
      case PdfCompressLevel.low:
        return LocaleKeys.compressLowHint.tr;
      case PdfCompressLevel.medium:
        return LocaleKeys.compressMediumHint.tr;
      case PdfCompressLevel.high:
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
                color: selected ? AppColors.brand : Colors.grey,
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

class _PageGrid extends StatelessWidget {
  const _PageGrid({
    required this.pages,
    required this.onDelete,
    required this.onEdit,
    required this.onAddMore,
  });

  final List<PdfPageImage> pages;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onEdit;
  final VoidCallback onAddMore;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pages.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        if (index == pages.length) {
          return _AddMoreTile(onTap: onAddMore);
        }
        final page = pages[index];
        return _PageTile(
          page: page,
          displayIndex: index + 1,
          onDelete: () => onDelete(page.id),
          onEdit: () => onEdit(page.id),
        );
      },
    );
  }
}

class _AddMoreTile extends StatelessWidget {
  const _AddMoreTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.brand.withValues(alpha: 0.45),
              width: 1.5,
            ),
            color: isDark
                ? AppColors.darkMuted
                : AppColors.brandSoft.withValues(alpha: 0.55),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.brand),
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.addMore.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.page,
    required this.displayIndex,
    required this.onDelete,
    required this.onEdit,
  });

  final PdfPageImage page;
  final int displayIndex;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppColors.lightMuted,
            child: Transform.rotate(
              angle: page.rotation * 3.1415926535 / 180,
              child: Image.file(
                File(page.path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'P$displayIndex',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child:
                      Icon(Icons.close_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            right: 6,
            child: Material(
              color: AppColors.brand.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          LocaleKeys.editImage.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
