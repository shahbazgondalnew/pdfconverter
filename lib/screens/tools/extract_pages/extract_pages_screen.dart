import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/section_card.dart';
import '../../../controllers/extract_pages_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../models/pdf_to_image_models.dart';
import '../../../services/pdf_to_image_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class ExtractPagesScreen extends GetView<ExtractPagesController> {
  const ExtractPagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolExtractPages.tr),
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
          final format = controller.selectedFormat.value;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      SectionCard(
                        title: LocaleKeys.extractImageFormat.tr,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ExtractImageFormat.values.map((item) {
                            final selected = item == format;
                            return ChoiceChip(
                              label: Text(item.label),
                              selected: selected,
                              onSelected: (_) => controller.setFormat(item),
                              selectedColor:
                                  AppColors.brand.withValues(alpha: 0.18),
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? AppColors.brand
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? AppColors.brand
                                    : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        title: LocaleKeys.selectedPages.tr,
                        trailing: Text(
                          LocaleKeys.selectedCount.trParams({
                            'count': '$selectedCount',
                            'total': '${pages.length}',
                          }),
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
                                    LocaleKeys.extractPagesSelectHint.tr,
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
                          : controller.onExtractPressed,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        selectedCount == 0
                            ? LocaleKeys.extractPagesSave.tr
                            : LocaleKeys.extractPagesSaveCount.trParams({
                                'count': '$selectedCount',
                                'format': format.label,
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
    required this.onAddMore,
  });

  final List<PdfPageImage> pages;
  final bool Function(String id) isSelected;
  final ValueChanged<String> onToggle;
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
          selected: isSelected(page.id),
          onToggle: () => onToggle(page.id),
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
    required this.selected,
    required this.onToggle,
  });

  final PdfPageImage page;
  final int displayIndex;
  final bool selected;
  final VoidCallback onToggle;

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
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
