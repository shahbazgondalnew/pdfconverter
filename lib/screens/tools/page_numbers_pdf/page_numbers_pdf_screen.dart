import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../components/section_card.dart';
import '../../../controllers/page_numbers_pdf_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../models/page_number_models.dart';
import '../../../models/pdf_to_image_models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class PageNumbersPdfScreen extends GetView<PageNumbersPdfController> {
  const PageNumbersPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolPageNumbers.tr),
        ),
        body: Obx(() {
          final pages = controller.pages.toList();
          final settings = controller.settings.value;
          final preview = controller.previewLabel;

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
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LocaleKeys.pageNumbersPagesHint.tr,
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
                                    onEdit: controller.openEditor,
                                    onAddMore: controller.addMorePdfs,
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.pageNumbersPreview.tr,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.brand.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            preview.isEmpty ? '—' : preview,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: settings.fontSize,
                              fontWeight: settings.bold
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: settings.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.pageNumbersFormat.tr,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final format in PageNumberFormat.values)
                              _ChoiceChip(
                                label: _formatLabel(format),
                                selected: settings.format == format,
                                onTap: () => controller.setFormat(format),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.pageNumbersPosition.tr,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final position in PageNumberPosition.values)
                              _ChoiceChip(
                                label: _positionLabel(position),
                                selected: settings.position == position,
                                onTap: () => controller.setPosition(position),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.pageNumbersStyle.tr,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocaleKeys.pageNumbersFontSize.trParams({
                                'size': settings.fontSize.round().toString(),
                              }),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Slider(
                              value: settings.fontSize,
                              min: 10,
                              max: 36,
                              divisions: 26,
                              activeColor: AppColors.brand,
                              onChanged: controller.setFontSize,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              LocaleKeys.pageNumbersColor.tr,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final color
                                    in PageNumberSettings.colorPresets)
                                  GestureDetector(
                                    onTap: () => controller.setColor(color),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Color(color),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: settings.colorValue == color
                                              ? AppColors.brand
                                              : Colors.black26,
                                          width: settings.colorValue == color
                                              ? 2.5
                                              : 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(LocaleKeys.pageNumbersBold.tr),
                              value: settings.bold,
                              activeThumbColor: Colors.white,
                              activeTrackColor: AppColors.brand,
                              onChanged: (value) =>
                                  controller.setBold(value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.pageNumbersRange.tr,
                        child: Column(
                          children: [
                            for (final mode in PageNumberRangeMode.values) ...[
                              if (mode != PageNumberRangeMode.values.first)
                                const SizedBox(height: 8),
                              _RangeTile(
                                title: _rangeTitle(mode),
                                subtitle: _rangeSubtitle(mode),
                                selected: settings.rangeMode == mode,
                                onTap: () => controller.setRangeMode(mode),
                              ),
                            ],
                            if (settings.rangeMode ==
                                PageNumberRangeMode.custom) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _NumberField(
                                      label: LocaleKeys.pageNumbersFrom.tr,
                                      value: settings.customFrom,
                                      max: pages.isEmpty ? 1 : pages.length,
                                      onChanged: controller.setCustomFrom,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _NumberField(
                                      label: LocaleKeys.pageNumbersTo.tr,
                                      value: settings.customTo,
                                      max: pages.isEmpty ? 1 : pages.length,
                                      onChanged: controller.setCustomTo,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.pageNumbersStart.tr,
                        subtitle: LocaleKeys.pageNumbersStartHint.tr,
                        child: _NumberField(
                          label: LocaleKeys.pageNumbersStart.tr,
                          value: settings.startNumber,
                          max: 9999,
                          onChanged: controller.setStartNumber,
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
                          : controller.onApplyPressed,
                      icon: const Icon(Icons.format_list_numbered_rounded),
                      label: Text(LocaleKeys.pageNumbersApply.tr),
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

  String _formatLabel(PageNumberFormat format) {
    switch (format) {
      case PageNumberFormat.plain:
        return LocaleKeys.pageNumbersFormatPlain.tr;
      case PageNumberFormat.withTotal:
        return LocaleKeys.pageNumbersFormatTotal.tr;
      case PageNumberFormat.pagePrefix:
        return LocaleKeys.pageNumbersFormatPage.tr;
      case PageNumberFormat.dashed:
        return LocaleKeys.pageNumbersFormatDashed.tr;
      case PageNumberFormat.roman:
        return LocaleKeys.pageNumbersFormatRoman.tr;
    }
  }

  String _positionLabel(PageNumberPosition position) {
    switch (position) {
      case PageNumberPosition.topLeft:
        return LocaleKeys.pageNumbersPosTopLeft.tr;
      case PageNumberPosition.topCenter:
        return LocaleKeys.pageNumbersPosTopCenter.tr;
      case PageNumberPosition.topRight:
        return LocaleKeys.pageNumbersPosTopRight.tr;
      case PageNumberPosition.bottomLeft:
        return LocaleKeys.pageNumbersPosBottomLeft.tr;
      case PageNumberPosition.bottomCenter:
        return LocaleKeys.pageNumbersPosBottomCenter.tr;
      case PageNumberPosition.bottomRight:
        return LocaleKeys.pageNumbersPosBottomRight.tr;
    }
  }

  String _rangeTitle(PageNumberRangeMode mode) {
    switch (mode) {
      case PageNumberRangeMode.all:
        return LocaleKeys.pageNumbersRangeAll.tr;
      case PageNumberRangeMode.skipCover:
        return LocaleKeys.pageNumbersRangeSkipCover.tr;
      case PageNumberRangeMode.custom:
        return LocaleKeys.pageNumbersRangeCustom.tr;
    }
  }

  String _rangeSubtitle(PageNumberRangeMode mode) {
    switch (mode) {
      case PageNumberRangeMode.all:
        return LocaleKeys.pageNumbersRangeAllHint.tr;
      case PageNumberRangeMode.skipCover:
        return LocaleKeys.pageNumbersRangeSkipCoverHint.tr;
      case PageNumberRangeMode.custom:
        return LocaleKeys.pageNumbersRangeCustomHint.tr;
    }
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.brand.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected
            ? AppColors.brand
            : Theme.of(context).colorScheme.onSurface,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.brand
            : Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _RangeTile extends StatelessWidget {
  const _RangeTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.brand.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$label-$value-$max'),
      initialValue: '$value',
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (raw) {
        final parsed = int.tryParse(raw);
        if (parsed != null) onChanged(parsed.clamp(1, max));
      },
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
          Material(
            color: AppColors.lightMuted,
            child: InkWell(
              onTap: onEdit,
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
              onTap: onDelete,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Text(
                    LocaleKeys.editImage.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
