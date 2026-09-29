import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../components/section_card.dart';
import '../../../controllers/watermark_pdf_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../models/pdf_to_image_models.dart';
import '../../../models/watermark_models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class WatermarkPdfScreen extends GetView<WatermarkPdfController> {
  const WatermarkPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolWatermark.tr),
        ),
        body: Obx(() {
          final pages = controller.pages.toList();
          final settings = controller.settings.value;

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
                                    LocaleKeys.watermarkPagesHint.tr,
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
                        title: LocaleKeys.watermarkPreview.tr,
                        child: _WatermarkPreview(settings: settings),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.watermarkType.tr,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChoiceChip(
                              label: LocaleKeys.watermarkTypeText.tr,
                              selected: settings.type == WatermarkType.text,
                              onTap: () =>
                                  controller.setType(WatermarkType.text),
                            ),
                            _ChoiceChip(
                              label: LocaleKeys.watermarkTypeImage.tr,
                              selected: settings.type == WatermarkType.image,
                              onTap: () =>
                                  controller.setType(WatermarkType.image),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (settings.type == WatermarkType.text) ...[
                        SectionCard(
                          title: LocaleKeys.watermarkText.tr,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: controller.textController,
                                decoration: InputDecoration(
                                  hintText: LocaleKeys.watermarkTextHint.tr,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  isDense: true,
                                ),
                                textCapitalization:
                                    TextCapitalization.characters,
                                onChanged: controller.setText,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                LocaleKeys.watermarkPresets.tr,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final preset
                                      in WatermarkSettings.textPresets)
                                    _ChoiceChip(
                                      label: preset,
                                      selected: settings.text == preset &&
                                          settings.type == WatermarkType.text,
                                      onTap: () =>
                                          controller.useTextPreset(preset),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else ...[
                        SectionCard(
                          title: LocaleKeys.watermarkImage.tr,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (settings.imagePath != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Image.file(
                                      File(settings.imagePath!),
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => const Center(
                                        child:
                                            Icon(Icons.broken_image_outlined),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: controller.isBusy.value
                                          ? null
                                          : controller.pickWatermarkImage,
                                      icon: const Icon(
                                        Icons.image_outlined,
                                      ),
                                      label: Text(
                                        settings.imagePath == null
                                            ? LocaleKeys.watermarkPickImage.tr
                                            : LocaleKeys
                                                .watermarkChangeImage.tr,
                                      ),
                                    ),
                                  ),
                                  if (settings.imagePath != null) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed:
                                          controller.clearWatermarkImage,
                                      tooltip: LocaleKeys.watermarkClearImage.tr,
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      SectionCard(
                        title: LocaleKeys.watermarkLayout.tr,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChoiceChip(
                              label: LocaleKeys.watermarkLayoutSingle.tr,
                              selected:
                                  settings.layout == WatermarkLayout.single,
                              onTap: () => controller
                                  .setLayout(WatermarkLayout.single),
                            ),
                            _ChoiceChip(
                              label: LocaleKeys.watermarkLayoutTiled.tr,
                              selected:
                                  settings.layout == WatermarkLayout.tiled,
                              onTap: () =>
                                  controller.setLayout(WatermarkLayout.tiled),
                            ),
                          ],
                        ),
                      ),
                      if (settings.layout == WatermarkLayout.single) ...[
                        const SizedBox(height: 14),
                        SectionCard(
                          title: LocaleKeys.watermarkPosition.tr,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final position
                                  in WatermarkPosition.values)
                                _ChoiceChip(
                                  label: _positionLabel(position),
                                  selected: settings.position == position,
                                  onTap: () =>
                                      controller.setPosition(position),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.watermarkOpacity.tr,
                        subtitle: LocaleKeys.watermarkOpacityHint.trParams({
                          'value':
                              '${(settings.opacity * 100).round()}',
                        }),
                        child: Slider(
                          value: settings.opacity,
                          min: 0.05,
                          max: 1.0,
                          divisions: 19,
                          activeColor: AppColors.brand,
                          onChanged: controller.setOpacity,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.watermarkRotation.tr,
                        subtitle: LocaleKeys.watermarkRotationHint.trParams({
                          'value': '${settings.rotation.round()}',
                        }),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Slider(
                              value: settings.rotation,
                              min: -90,
                              max: 90,
                              divisions: 36,
                              activeColor: AppColors.brand,
                              onChanged: controller.setRotation,
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final angle
                                    in WatermarkSettings.rotationPresets)
                                  _ChoiceChip(
                                    label: '${angle.round()}°',
                                    selected:
                                        settings.rotation == angle,
                                    onTap: () =>
                                        controller.setRotation(angle),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.watermarkStyle.tr,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (settings.type == WatermarkType.text) ...[
                              Text(
                                LocaleKeys.watermarkFontSize.trParams({
                                  'size':
                                      settings.fontSize.round().toString(),
                                }),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Slider(
                                value: settings.fontSize,
                                min: 16,
                                max: 96,
                                divisions: 40,
                                activeColor: AppColors.brand,
                                onChanged: controller.setFontSize,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                LocaleKeys.watermarkColor.tr,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final color
                                      in WatermarkSettings.colorPresets)
                                    GestureDetector(
                                      onTap: () =>
                                          controller.setColor(color),
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: Color(color),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                settings.colorValue == color
                                                    ? AppColors.brand
                                                    : Colors.black26,
                                            width:
                                                settings.colorValue == color
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
                                title: Text(LocaleKeys.watermarkBold.tr),
                                value: settings.bold,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppColors.brand,
                                onChanged: controller.setBold,
                              ),
                            ] else ...[
                              Text(
                                LocaleKeys.watermarkImageScale.trParams({
                                  'value':
                                      '${(settings.imageScale * 100).round()}',
                                }),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Slider(
                                value: settings.imageScale,
                                min: 0.1,
                                max: 0.9,
                                divisions: 16,
                                activeColor: AppColors.brand,
                                onChanged: controller.setImageScale,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.watermarkRange.tr,
                        child: Column(
                          children: [
                            for (final mode
                                in WatermarkRangeMode.values) ...[
                              if (mode != WatermarkRangeMode.values.first)
                                const SizedBox(height: 8),
                              _RangeTile(
                                title: _rangeTitle(mode),
                                subtitle: _rangeSubtitle(mode),
                                selected: settings.rangeMode == mode,
                                onTap: () =>
                                    controller.setRangeMode(mode),
                              ),
                            ],
                            if (settings.rangeMode ==
                                WatermarkRangeMode.custom) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _NumberField(
                                      label: LocaleKeys.watermarkFrom.tr,
                                      value: settings.customFrom,
                                      max: pages.isEmpty ? 1 : pages.length,
                                      onChanged: controller.setCustomFrom,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _NumberField(
                                      label: LocaleKeys.watermarkTo.tr,
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
                      icon: const Icon(Icons.branding_watermark_outlined),
                      label: Text(LocaleKeys.watermarkApply.tr),
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

  String _positionLabel(WatermarkPosition position) {
    switch (position) {
      case WatermarkPosition.center:
        return LocaleKeys.watermarkPosCenter.tr;
      case WatermarkPosition.topLeft:
        return LocaleKeys.watermarkPosTopLeft.tr;
      case WatermarkPosition.topCenter:
        return LocaleKeys.watermarkPosTopCenter.tr;
      case WatermarkPosition.topRight:
        return LocaleKeys.watermarkPosTopRight.tr;
      case WatermarkPosition.bottomLeft:
        return LocaleKeys.watermarkPosBottomLeft.tr;
      case WatermarkPosition.bottomCenter:
        return LocaleKeys.watermarkPosBottomCenter.tr;
      case WatermarkPosition.bottomRight:
        return LocaleKeys.watermarkPosBottomRight.tr;
    }
  }

  String _rangeTitle(WatermarkRangeMode mode) {
    switch (mode) {
      case WatermarkRangeMode.all:
        return LocaleKeys.watermarkRangeAll.tr;
      case WatermarkRangeMode.skipCover:
        return LocaleKeys.watermarkRangeSkipCover.tr;
      case WatermarkRangeMode.custom:
        return LocaleKeys.watermarkRangeCustom.tr;
    }
  }

  String _rangeSubtitle(WatermarkRangeMode mode) {
    switch (mode) {
      case WatermarkRangeMode.all:
        return LocaleKeys.watermarkRangeAllHint.tr;
      case WatermarkRangeMode.skipCover:
        return LocaleKeys.watermarkRangeSkipCoverHint.tr;
      case WatermarkRangeMode.custom:
        return LocaleKeys.watermarkRangeCustomHint.tr;
    }
  }
}

class _WatermarkPreview extends StatelessWidget {
  const _WatermarkPreview({required this.settings});

  final WatermarkSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brand.withValues(alpha: 0.18),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _PageLinesPainter(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.18),
              ),
            ),
            if (settings.layout == WatermarkLayout.tiled)
              for (final alignment in const [
                Alignment.topLeft,
                Alignment.topCenter,
                Alignment.topRight,
                Alignment.centerLeft,
                Alignment.center,
                Alignment.centerRight,
                Alignment.bottomLeft,
                Alignment.bottomCenter,
                Alignment.bottomRight,
              ])
                Align(
                  alignment: alignment,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _PreviewMark(settings: settings, compact: true),
                  ),
                )
            else
              Align(
                alignment: _flutterAlignment(settings.position),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _PreviewMark(settings: settings, compact: false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Alignment _flutterAlignment(WatermarkPosition position) {
    switch (position) {
      case WatermarkPosition.center:
        return Alignment.center;
      case WatermarkPosition.topLeft:
        return Alignment.topLeft;
      case WatermarkPosition.topCenter:
        return Alignment.topCenter;
      case WatermarkPosition.topRight:
        return Alignment.topRight;
      case WatermarkPosition.bottomLeft:
        return Alignment.bottomLeft;
      case WatermarkPosition.bottomCenter:
        return Alignment.bottomCenter;
      case WatermarkPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }
}

class _PreviewMark extends StatelessWidget {
  const _PreviewMark({
    required this.settings,
    required this.compact,
  });

  final WatermarkSettings settings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (settings.type == WatermarkType.image &&
        settings.imagePath != null) {
      child = SizedBox(
        width: compact ? 36 : 72,
        height: compact ? 36 : 72,
        child: Image.file(
          File(settings.imagePath!),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            Icons.image_outlined,
            color: settings.color.withValues(alpha: settings.opacity),
          ),
        ),
      );
    } else {
      final text = settings.text.trim().isEmpty ? '—' : settings.text.trim();
      child = Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact
              ? (settings.fontSize * 0.35).clamp(9, 16)
              : (settings.fontSize * 0.55).clamp(12, 28),
          fontWeight: settings.bold ? FontWeight.w700 : FontWeight.w500,
          color: settings.color,
        ),
      );
    }

    return Opacity(
      opacity: settings.opacity.clamp(0.05, 1.0),
      child: Transform.rotate(
        angle: settings.rotation * math.pi / 180,
        child: child,
      ),
    );
  }
}

class _PageLinesPainter extends CustomPainter {
  _PageLinesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const gap = 18.0;
    for (var y = 28.0; y < size.height - 12; y += gap) {
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PageLinesPainter oldDelegate) =>
      oldDelegate.color != color;
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
