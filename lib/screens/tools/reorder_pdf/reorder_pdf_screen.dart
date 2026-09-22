import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/reorder_pdf_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../models/pdf_to_image_models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class ReorderPdfScreen extends GetView<ReorderPdfController> {
  const ReorderPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolReorderPages.tr),
          actions: [
            IconButton(
              tooltip: LocaleKeys.addMore.tr,
              onPressed: controller.addMorePdfs,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        body: Obx(() {
          final pages = controller.pages.toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    LocaleKeys.reorderPagesHint.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
              Expanded(
                child: pages.isEmpty
                    ? Center(child: Text(LocaleKeys.noPagesSelected.tr))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: pages.length,
                        onReorderItem: controller.onReorderItem,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.transparent,
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final page = pages[index];
                          return _ReorderRow(
                            key: ValueKey(page.id),
                            page: page,
                            index: index,
                            total: pages.length,
                            isDark: isDark,
                            onDelete: () => controller.deletePage(page.id),
                            onMoveUp: () => controller.moveUp(index),
                            onMoveDown: () => controller.moveDown(index),
                            onMoveToStart: () => controller.moveToStart(index),
                            onMoveToEnd: () => controller.moveToEnd(index),
                          );
                        },
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
                      label: Text(LocaleKeys.reorderPdfAction.tr),
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

class _ReorderRow extends StatelessWidget {
  const _ReorderRow({
    super.key,
    required this.page,
    required this.index,
    required this.total,
    required this.isDark,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onMoveToStart,
    required this.onMoveToEnd,
  });

  final PdfPageImage page;
  final int index;
  final int total;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onMoveToStart;
  final VoidCallback onMoveToEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFEEDFDF),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.drag_handle_rounded, color: Colors.grey),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 84,
                    child: Transform.rotate(
                      angle: page.rotation * 3.1415926535 / 180,
                      child: Image.file(
                        File(page.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: AppColors.brand.withValues(alpha: 0.12),
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.pageLabel.trParams({
                          'number': '${index + 1}',
                        }),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LocaleKeys.reorderPosition.trParams({
                          'current': '${index + 1}',
                          'total': '$total',
                        }),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _IconAction(
                            icon: Icons.vertical_align_top_rounded,
                            enabled: index > 0,
                            onTap: onMoveToStart,
                          ),
                          _IconAction(
                            icon: Icons.keyboard_arrow_up_rounded,
                            enabled: index > 0,
                            onTap: onMoveUp,
                          ),
                          _IconAction(
                            icon: Icons.keyboard_arrow_down_rounded,
                            enabled: index < total - 1,
                            onTap: onMoveDown,
                          ),
                          _IconAction(
                            icon: Icons.vertical_align_bottom_rounded,
                            enabled: index < total - 1,
                            onTap: onMoveToEnd,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: LocaleKeys.removePage.tr,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      onPressed: enabled ? onTap : null,
      icon: Icon(
        icon,
        color: enabled ? AppColors.brand : Colors.grey.withValues(alpha: 0.4),
      ),
    );
  }
}
