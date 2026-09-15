import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../models/image_to_pdf_models.dart';
import '../theme/app_colors.dart';

class SelectedImageGrid extends StatelessWidget {
  const SelectedImageGrid({
    super.key,
    required this.images,
    required this.onDelete,
    required this.onEdit,
    this.onAddMore,
    this.emptyLabel,
  });

  final List<SelectedImage> images;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onEdit;
  final VoidCallback? onAddMore;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final showAddMore = onAddMore != null;
    final itemCount = images.isEmpty && !showAddMore
        ? 0
        : images.length + (showAddMore ? 1 : 0);

    if (itemCount == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          emptyLabel ?? LocaleKeys.noImagesSelected.tr,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        if (showAddMore && index == images.length) {
          return _AddMoreTile(onTap: onAddMore!);
        }

        final image = images[index];
        return _ImageGridTile(
          image: image,
          onDelete: () => onDelete(image.id),
          onEdit: () => onEdit(image.id),
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

class _ImageGridTile extends StatelessWidget {
  const _ImageGridTile({
    required this.image,
    required this.onDelete,
    required this.onEdit,
  });

  final SelectedImage image;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppColors.lightMuted,
            child: Transform.rotate(
              angle: image.rotation * 3.1415926535 / 180,
              child: Image.file(
                File(image.path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _RoundAction(
              icon: Icons.close_rounded,
              color: Colors.black.withValues(alpha: 0.55),
              onTap: onDelete,
              tooltip: LocaleKeys.deleteImage.tr,
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            right: 6,
            child: _RoundAction(
              icon: Icons.edit_outlined,
              label: LocaleKeys.editImage.tr,
              color: AppColors.brand.withValues(alpha: 0.92),
              onTap: onEdit,
              tooltip: LocaleKeys.editImage.tr,
              expanded: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.label,
    this.expanded = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final String? label;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 10 : 6,
              vertical: 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                if (label != null) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
