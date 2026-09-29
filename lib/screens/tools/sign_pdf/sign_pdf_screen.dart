import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../components/section_card.dart';
import '../../../controllers/sign_pdf_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../models/sign_pdf_models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class SignPdfScreen extends GetView<SignPdfController> {
  const SignPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.toolSignPdf.tr),
        ),
        body: Obx(() {
          final file = controller.selected.value;
          final settings = controller.settings.value;
          final signature = controller.signaturePath.value;
          final sizeLabel = controller.fileSizeLabel;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      SectionCard(
                        title: LocaleKeys.signPdfFile.tr,
                        child: file == null
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    LocaleKeys.signPdfNoFile.tr,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              )
                            : Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.brand
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
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
                                          file.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        if (sizeLabel != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            sizeLabel,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: controller.isBusy.value
                                        ? null
                                        : controller.changePdf,
                                    child: Text(LocaleKeys.signPdfChange.tr),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.signPdfSignature.tr,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (signature != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 120,
                                  color: Colors.white,
                                  alignment: Alignment.center,
                                  child: Image.file(
                                    File(signature),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.broken_image_outlined,
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
                                        : controller.openDrawSignature,
                                    icon: const Icon(Icons.draw_outlined),
                                    label: Text(LocaleKeys.signPdfDraw.tr),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: controller.isBusy.value
                                        ? null
                                        : controller.pickSignatureImage,
                                    icon: const Icon(Icons.image_outlined),
                                    label: Text(LocaleKeys.signPdfUpload.tr),
                                  ),
                                ),
                              ],
                            ),
                            if (signature != null) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: controller.clearSignature,
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: Text(LocaleKeys.signPdfClear.tr),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.signPdfPosition.tr,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final position in SignPdfPosition.values)
                              ChoiceChip(
                                label: Text(_positionLabel(position)),
                                selected: settings.position == position,
                                onSelected: (_) =>
                                    controller.setPosition(position),
                                selectedColor:
                                    AppColors.brand.withValues(alpha: 0.18),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: settings.position == position
                                      ? AppColors.brand
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.signPdfSize.tr,
                        subtitle: LocaleKeys.signPdfSizeHint.trParams({
                          'value': '${(settings.scale * 100).round()}',
                        }),
                        child: Slider(
                          value: settings.scale,
                          min: 0.12,
                          max: 0.55,
                          divisions: 17,
                          activeColor: AppColors.brand,
                          onChanged: controller.setScale,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        title: LocaleKeys.signPdfRange.tr,
                        child: Column(
                          children: [
                            for (final mode in SignPdfRangeMode.values) ...[
                              if (mode != SignPdfRangeMode.values.first)
                                const SizedBox(height: 8),
                              _RangeTile(
                                title: _rangeTitle(mode),
                                subtitle: _rangeSubtitle(mode),
                                selected: settings.rangeMode == mode,
                                onTap: () => controller.setRangeMode(mode),
                              ),
                            ],
                            if (settings.rangeMode ==
                                SignPdfRangeMode.custom) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _NumberField(
                                      label: LocaleKeys.signPdfFrom.tr,
                                      value: settings.customFrom,
                                      max: controller.pageCount.value,
                                      onChanged: controller.setCustomFrom,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _NumberField(
                                      label: LocaleKeys.signPdfTo.tr,
                                      value: settings.customTo,
                                      max: controller.pageCount.value,
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
                          : controller.onSignPressed,
                      icon: const Icon(Icons.draw_outlined),
                      label: Text(LocaleKeys.signPdfAction.tr),
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

  String _positionLabel(SignPdfPosition position) {
    switch (position) {
      case SignPdfPosition.bottomRight:
        return LocaleKeys.signPdfPosBottomRight.tr;
      case SignPdfPosition.bottomLeft:
        return LocaleKeys.signPdfPosBottomLeft.tr;
      case SignPdfPosition.bottomCenter:
        return LocaleKeys.signPdfPosBottomCenter.tr;
      case SignPdfPosition.topRight:
        return LocaleKeys.signPdfPosTopRight.tr;
      case SignPdfPosition.topLeft:
        return LocaleKeys.signPdfPosTopLeft.tr;
      case SignPdfPosition.center:
        return LocaleKeys.signPdfPosCenter.tr;
    }
  }

  String _rangeTitle(SignPdfRangeMode mode) {
    switch (mode) {
      case SignPdfRangeMode.all:
        return LocaleKeys.signPdfRangeAll.tr;
      case SignPdfRangeMode.lastPage:
        return LocaleKeys.signPdfRangeLast.tr;
      case SignPdfRangeMode.firstPage:
        return LocaleKeys.signPdfRangeFirst.tr;
      case SignPdfRangeMode.custom:
        return LocaleKeys.signPdfRangeCustom.tr;
    }
  }

  String _rangeSubtitle(SignPdfRangeMode mode) {
    switch (mode) {
      case SignPdfRangeMode.all:
        return LocaleKeys.signPdfRangeAllHint.tr;
      case SignPdfRangeMode.lastPage:
        return LocaleKeys.signPdfRangeLastHint.tr;
      case SignPdfRangeMode.firstPage:
        return LocaleKeys.signPdfRangeFirstHint.tr;
      case SignPdfRangeMode.custom:
        return LocaleKeys.signPdfRangeCustomHint.tr;
    }
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
