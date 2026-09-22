import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/section_card.dart';
import '../../../controllers/rotate_pdf_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../models/pdf_to_image_models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class RotatePdfScreen extends GetView<RotatePdfController> {
  const RotatePdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolRotatePdf.tr),
        ),
        body: Obx(() {
          final pages = controller.pages.toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      if (pages.isNotEmpty) ...[
                        SectionCard(
                          title: LocaleKeys.rotateAll.tr,
                          subtitle: LocaleKeys.rotateAllHint.tr,
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: controller.rotateAllLeft,
                                  icon: const Icon(Icons.rotate_left_rounded),
                                  label: Text(LocaleKeys.rotateLeft.tr),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.brand,
                                    side: const BorderSide(
                                      color: AppColors.brand,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: controller.rotateAllRight,
                                  icon: const Icon(Icons.rotate_right_rounded),
                                  label: Text(LocaleKeys.rotateRight.tr),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.brand,
                                    side: const BorderSide(
                                      color: AppColors.brand,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
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
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LocaleKeys.rotatePageHint.tr,
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
                                  _PageGrid(
                                    pages: pages,
                                    onDelete: controller.deletePage,
                                    onRotateLeft: controller.rotatePageLeft,
                                    onRotateRight: controller.rotatePageRight,
                                    onAddMore: controller.addMorePdfs,
                                  ),
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
                          : controller.onSavePressed,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(LocaleKeys.rotatePdfAction.tr),
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

class _PageGrid extends StatelessWidget {
  const _PageGrid({
    required this.pages,
    required this.onDelete,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onAddMore,
  });

  final List<PdfPageImage> pages;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onRotateLeft;
  final ValueChanged<String> onRotateRight;
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
        childAspectRatio: 0.68,
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
          onRotateLeft: () => onRotateLeft(page.id),
          onRotateRight: () => onRotateRight(page.id),
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
    required this.onRotateLeft,
    required this.onRotateRight,
  });

  final PdfPageImage page;
  final int displayIndex;
  final VoidCallback onDelete;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;

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
          if (page.rotation % 360 != 0)
            Positioned(
              left: 6,
              top: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${page.rotation % 360}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
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
            right: 6,
            bottom: 6,
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: AppColors.brand.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: onRotateLeft,
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Icon(
                          Icons.rotate_left_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Material(
                    color: AppColors.brand.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: onRotateRight,
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Icon(
                          Icons.rotate_right_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
