import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/history_controller.dart';
import '../localization/locale_keys.dart';
import '../models/conversion_record.dart';
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
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        LocaleKeys.historyTitle.tr,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    Obx(
                      () => controller.hasConversions
                          ? IconButton.filledTonal(
                              onPressed: controller.clearHistory,
                              tooltip: LocaleKeys.historyClear.tr,
                              icon: const Icon(Icons.delete_outline_rounded),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (!controller.hasConversions) {
                    return _EmptyHistory(isDark: isDark);
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    itemCount: controller.records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final record = controller.records[index];
                      return Material(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => controller.openRecord(record),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFEEDFDF),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color:
                                        AppColors.brand.withValues(alpha: 0.12),
                                  ),
                                  child: const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: AppColors.brand,
                                  ),
                                ),
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
                                        '${_typeLabel(record.conversionType)} · ${record.formattedSize}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: LocaleKeys.sharePdf.tr,
                                  onPressed: () =>
                                      controller.shareRecord(record),
                                  icon: const Icon(Icons.ios_share_rounded),
                                ),
                                IconButton(
                                  tooltip: LocaleKeys.deleteImage.tr,
                                  onPressed: () =>
                                      controller.deleteRecord(record),
                                  icon: const Icon(Icons.delete_outline_rounded),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
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
