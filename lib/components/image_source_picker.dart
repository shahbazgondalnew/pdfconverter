import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../theme/app_colors.dart';

enum ImagePickSource { gallery, camera, file }

class ImageSourcePicker extends StatelessWidget {
  const ImageSourcePicker({
    super.key,
    required this.onSourceSelected,
    this.enabled = true,
  });

  final ValueChanged<ImagePickSource> onSourceSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SourceButton(
            icon: Icons.photo_library_outlined,
            label: LocaleKeys.fromGallery.tr,
            onTap: enabled
                ? () => onSourceSelected(ImagePickSource.gallery)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SourceButton(
            icon: Icons.photo_camera_outlined,
            label: LocaleKeys.fromCamera.tr,
            onTap: enabled
                ? () => onSourceSelected(ImagePickSource.camera)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SourceButton(
            icon: Icons.folder_open_outlined,
            label: LocaleKeys.fromFile.tr,
            onTap:
                enabled ? () => onSourceSelected(ImagePickSource.file) : null,
          ),
        ),
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? AppColors.darkMuted
                : AppColors.brandSoft.withValues(alpha: 0.65),
            border: Border.all(
              color: AppColors.brand.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.brand, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
