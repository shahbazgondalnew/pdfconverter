import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../models/image_to_pdf_models.dart';
import '../theme/app_colors.dart';

class ImageFitSelector extends StatelessWidget {
  const ImageFitSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ImageFitMode value;
  final ValueChanged<ImageFitMode> onChanged;

  static const _options = <(ImageFitMode, IconData, String)>[
    (ImageFitMode.center, Icons.center_focus_strong_outlined, LocaleKeys.fitCenter),
    (ImageFitMode.contain, Icons.fit_screen_outlined, LocaleKeys.fitContain),
    (ImageFitMode.cover, Icons.crop_landscape_outlined, LocaleKeys.fitCover),
    (ImageFitMode.fill, Icons.aspect_ratio_outlined, LocaleKeys.fitFill),
    (ImageFitMode.fitWidth, Icons.swap_horiz, LocaleKeys.fitWidth),
    (ImageFitMode.fitHeight, Icons.swap_vert, LocaleKeys.fitHeight),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((option) {
        final selected = option.$1 == value;
        return ChoiceChip(
          selected: selected,
          showCheckmark: false,
          avatar: Icon(
            option.$2,
            size: 18,
            color: selected ? Colors.white : AppColors.brand,
          ),
          label: Text(option.$3.tr),
          selectedColor: AppColors.brand,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkMuted
              : AppColors.brandSoft.withValues(alpha: 0.55),
          labelStyle: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          onSelected: (_) => onChanged(option.$1),
        );
      }).toList(),
    );
  }
}
