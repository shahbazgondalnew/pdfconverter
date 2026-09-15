import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../models/image_to_pdf_models.dart';
import '../theme/app_colors.dart';

class PdfBackgroundPicker extends StatelessWidget {
  const PdfBackgroundPicker({
    super.key,
    required this.option,
    required this.customColor,
    required this.onOptionChanged,
    required this.onCustomColorChanged,
  });

  final PdfBackgroundOption option;
  final Color customColor;
  final ValueChanged<PdfBackgroundOption> onOptionChanged;
  final ValueChanged<Color> onCustomColorChanged;

  static const _presets = <(PdfBackgroundOption, Color, String)>[
    (PdfBackgroundOption.white, Colors.white, LocaleKeys.bgWhite),
    (PdfBackgroundOption.black, Colors.black, LocaleKeys.bgBlack),
    (PdfBackgroundOption.gray, Color(0xFFE0E0E0), LocaleKeys.bgGray),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._presets.map((preset) {
              final selected = option == preset.$1;
              return _ColorOption(
                color: preset.$2,
                label: preset.$3.tr,
                selected: selected,
                onTap: () => onOptionChanged(preset.$1),
              );
            }),
            _ColorOption(
              color: customColor,
              label: LocaleKeys.bgCustom.tr,
              selected: option == PdfBackgroundOption.custom,
              onTap: () async {
                final picked = await showDialog<Color>(
                  context: context,
                  builder: (context) => _SimpleColorDialog(initial: customColor),
                );
                if (picked != null) {
                  onCustomColorChanged(picked);
                  onOptionChanged(PdfBackgroundOption.custom);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 78,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.brand : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleColorDialog extends StatefulWidget {
  const _SimpleColorDialog({required this.initial});

  final Color initial;

  @override
  State<_SimpleColorDialog> createState() => _SimpleColorDialogState();
}

class _SimpleColorDialogState extends State<_SimpleColorDialog> {
  static const _colors = <Color>[
    Colors.white,
    Color(0xFFF5F5F5),
    Color(0xFFE0E0E0),
    Colors.black,
    Color(0xFFFFEBEE),
    Color(0xFFE3F2FD),
    Color(0xFFE8F5E9),
    Color(0xFFFFF8E1),
    Color(0xFFF3E5F5),
  ];

  late Color _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocaleKeys.bgCustom.tr),
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _colors.map((color) {
          final selected = color.toARGB32() == _selected.toARGB32();
          return InkWell(
            onTap: () => setState(() => _selected = color),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.brand : Colors.black26,
                  width: selected ? 3 : 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocaleKeys.cancel.tr),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(LocaleKeys.save.tr),
        ),
      ],
    );
  }
}
