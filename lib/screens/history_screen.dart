import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/history_controller.dart';
import '../localization/locale_keys.dart';
import '../models/conversion_record.dart';
import '../services/conversion_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';

class HistoryScreen extends GetView<HistoryController> {
  const HistoryScreen({super.key});

  String _typeLabel(ConversionType type) {
    switch (type) {
      case ConversionType.imageToPdf:
        return LocaleKeys.toolImageToPdf.tr;
      case ConversionType.wordToPdf:
        return LocaleKeys.toolWordToPdf.tr;
      case ConversionType.excelToPdf:
        return LocaleKeys.toolExcelToPdf.tr;
      case ConversionType.textToPdf:
        return LocaleKeys.toolTextToPdf.tr;
      case ConversionType.htmlToPdf:
        return LocaleKeys.toolHtmlToPdf.tr;
      case ConversionType.scanToPdf:
        return LocaleKeys.toolScanToPdf.tr;
      case ConversionType.pptToPdf:
        return LocaleKeys.toolPptToPdf.tr;
      case ConversionType.pdfToImage:
        return LocaleKeys.toolPdfToImage.tr;
      case ConversionType.pdfToWord:
        return LocaleKeys.toolPdfToWord.tr;
      case ConversionType.mergePdf:
        return LocaleKeys.toolMergePdf.tr;
      case ConversionType.splitPdf:
        return LocaleKeys.toolSplitPdf.tr;
      case ConversionType.compressPdf:
        return LocaleKeys.toolCompressPdf.tr;
      case ConversionType.rotatePdf:
        return LocaleKeys.toolRotatePdf.tr;
      case ConversionType.reorderPdf:
        return LocaleKeys.toolReorderPages.tr;
      case ConversionType.deletePagesPdf:
        return LocaleKeys.toolDeletePages.tr;
      case ConversionType.extractPages:
        return LocaleKeys.toolExtractPages.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Obx(() {
                  final selecting = controller.isSelectionMode.value;
                  return Row(
                    children: [
                      if (selecting)
                        IconButton(
                          onPressed: controller.exitSelectionMode,
                          tooltip: LocaleKeys.cancel.tr,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      Expanded(
                        child: Text(
                          selecting
                              ? LocaleKeys.historySelectedCount.trParams({
                                  'count': '${controller.selectedIds.length}',
                                })
                              : LocaleKeys.historyTitle.tr,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                      if (controller.hasConversions) ...[
                        if (selecting) ...[
                          TextButton(
                            onPressed: controller.allSelected
                                ? controller.deselectAll
                                : controller.selectAll,
                            child: Text(
                              controller.allSelected
                                  ? LocaleKeys.deselectAll.tr
                                  : LocaleKeys.selectAll.tr,
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: controller.hasSelection
                                ? controller.deleteSelected
                                : null,
                            tooltip: LocaleKeys.historyDelete.tr,
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ] else ...[
                          IconButton(
                            onPressed: controller.enterSelectionMode,
                            tooltip: LocaleKeys.historySelect.tr,
                            icon: const Icon(Icons.checklist_rounded),
                          ),
                          IconButton.filledTonal(
                            onPressed: controller.clearHistory,
                            tooltip: LocaleKeys.historyClear.tr,
                            icon: const Icon(Icons.delete_sweep_outlined),
                          ),
                        ],
                      ],
                    ],
                  );
                }),
              ),
              Expanded(
                child: Obx(() {
                  if (!controller.hasConversions) {
                    return _EmptyHistory(isDark: isDark);
                  }

                  final selecting = controller.isSelectionMode.value;

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      selecting ? 120 : 110,
                    ),
                    itemCount: controller.records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final record = controller.records[index];
                      final selected = controller.isSelected(record.id);
                      return Material(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => controller.openRecord(record),
                          onLongPress: selecting
                              ? null
                              : () => controller.enterSelectionMode(
                                    initialId: record.id,
                                  ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? AppColors.brand
                                    : isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : const Color(0xFFEEDFDF),
                                width: selected ? 1.6 : 1,
                              ),
                              color: selected
                                  ? AppColors.brand.withValues(alpha: 0.08)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                if (selecting) ...[
                                  Icon(
                                    selected
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    color: selected
                                        ? AppColors.brand
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                _HistoryThumb(record: record),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        record.isImageGroup
                                            ? '${_typeLabel(record.conversionType)} · ${LocaleKeys.imageGroupLabel.trParams({'count': '${record.pageCount}'})} · ${record.formattedSize}'
                                            : '${_typeLabel(record.conversionType)} · ${LocaleKeys.pdfMeta.trParams({
                                                  'size': record.formattedSize,
                                                  'pages':
                                                      '${record.pageCount}',
                                                })}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!selecting) ...[
                                  if (record.isImageGroup)
                                    IconButton(
                                      tooltip: LocaleKeys.saveToGallery.tr,
                                      onPressed: () => controller
                                          .promptSaveToGallery(record),
                                      icon: const Icon(
                                        Icons.photo_library_outlined,
                                      ),
                                    )
                                  else
                                    IconButton(
                                      tooltip: record.isWordFile
                                          ? LocaleKeys.saveWord.tr
                                          : LocaleKeys.savePdf.tr,
                                      onPressed: () =>
                                          controller.downloadRecord(record),
                                      icon: const Icon(Icons.download_rounded),
                                    ),
                                  IconButton(
                                    tooltip: record.isImageGroup
                                        ? LocaleKeys.shareImages.tr
                                        : LocaleKeys.sharePdf.tr,
                                    onPressed: () =>
                                        controller.shareRecord(record),
                                    icon: const Icon(Icons.ios_share_rounded),
                                  ),
                                  IconButton(
                                    tooltip: LocaleKeys.historyDelete.tr,
                                    onPressed: () =>
                                        controller.deleteRecord(record),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              Obx(() {
                if (!controller.isSelectionMode.value ||
                    !controller.hasSelection) {
                  return const SizedBox.shrink();
                }
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: controller.deleteSelected,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(
                          LocaleKeys.historyDeleteSelected.trParams({
                            'count': '${controller.selectedIds.length}',
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
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryThumb extends StatelessWidget {
  const _HistoryThumb({required this.record});

  final ConversionRecord record;

  @override
  Widget build(BuildContext context) {
    if (record.isImageGroup) {
      final files = ConversionStorage.resolveFiles(record);
      final first = files.isNotEmpty ? files.first : null;
      final exists = first != null && first.existsSync();

      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (exists)
                Image.file(
                  first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: AppColors.brand.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.brand,
                    ),
                  ),
                )
              else
                ColoredBox(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.brand,
                  ),
                ),
              if (record.pageCount > 1)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${record.pageCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.brand.withValues(alpha: 0.12),
      ),
      child: Icon(
        record.isWordFile
            ? Icons.description_outlined
            : Icons.picture_as_pdf_rounded,
        color: AppColors.brand,
      ),
    );
  }
}

class _EmptyHistory extends StatefulWidget {
  const _EmptyHistory({required this.isDark});

  final bool isDark;

  @override
  State<_EmptyHistory> createState() => _EmptyHistoryState();
}

class _EmptyHistoryState extends State<_EmptyHistory>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: widget.isDark
                        ? [
                            AppColors.brand.withValues(alpha: 0.25),
                            AppColors.darkMuted,
                          ]
                        : [
                            AppColors.brandSoft,
                            Colors.white,
                          ],
                  ),
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 40,
                  color: widget.isDark
                      ? const Color(0xFFFF8A80)
                      : AppColors.brand,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                LocaleKeys.historyEmpty.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.homeSubtitle.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
