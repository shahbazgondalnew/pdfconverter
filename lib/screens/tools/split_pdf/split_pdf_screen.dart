import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/section_card.dart';
import '../../../controllers/split_pdf_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../models/pdf_to_image_models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class SplitPdfScreen extends GetView<SplitPdfController> {
  const SplitPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolSplitPdf.tr),
          actions: [
            Obx(() {
              if (controller.pages.isEmpty) return const SizedBox.shrink();
              final allSelected =
                  controller.selectedIds.length == controller.pages.length &&
                      controller.pages.isNotEmpty;
              return TextButton(
                onPressed:
                    allSelected ? controller.deselectAll : controller.selectAll,
                child: Text(
                  allSelected
                      ? LocaleKeys.deselectAll.tr
                      : LocaleKeys.selectAll.tr,
                ),
              );
            }),
          ],
        ),
        body: Obx(() {
          final pages = controller.pages.toList();
          final selectedCount = controller.selectedIds.length;

          return Column(
            children: [
              if (controller.createdCount.value > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    LocaleKeys.splitCreatedCount.trParams({
                      'count': '${controller.createdCount.value}',
                    }),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SectionCard(
                    title: LocaleKeys.selectedPages.tr,
                    trailing: Text(
                      LocaleKeys.selectedCount.trParams({
                        'count': '$selectedCount',
                        'total': '${pages.length}',
                      }),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    child: pages.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                LocaleKeys.noPagesSelected.tr,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleKeys.splitSelectPagesHint.tr,
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
                                isSelected: controller.isSelected,
                                onToggle: controller.toggleSelect,
                                onDelete: controller.deletePage,
                                onEdit: controller.openEditor,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: controller.isBusy.value
                              ? null
                              : controller.onCreatePdfPressed,
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: Text(
                            selectedCount == 0
                                ? LocaleKeys.splitCreatePdf.tr
                                : LocaleKeys.splitCreatePdfCount.trParams({
                                    'count': '$selectedCount',
                                  }),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton.icon(
                          onPressed: controller.finishSession,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(LocaleKeys.done.tr),
                        ),
                      ),
                    ],
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
    required this.isSelected,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final List<PdfPageImage> pages;
  final bool Function(String id) isSelected;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final page = pages[index];
        return _PageTile(
          page: page,
          displayIndex: index + 1,
          selected: isSelected(page.id),
          onToggle: () => onToggle(page.id),
          onDelete: () => onDelete(page.id),
          onEdit: () => onEdit(page.id),
        );
      },
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.page,
    required this.displayIndex,
    required this.selected,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final PdfPageImage page;
  final int displayIndex;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(
            color: AppColors.lightMuted,
            child: InkWell(
              onTap: onToggle,
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
          ),
          if (selected)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.brand, width: 3),
                borderRadius: BorderRadius.circular(16),
                color: AppColors.brand.withValues(alpha: 0.18),
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
            child: GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? AppColors.brand : Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.circle_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Material(
              color: AppColors.brand.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
