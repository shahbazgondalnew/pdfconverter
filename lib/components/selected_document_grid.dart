import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../models/document_models.dart';
import '../theme/app_colors.dart';

class SelectedDocumentGrid extends StatelessWidget {
  const SelectedDocumentGrid({
    super.key,
    required this.documents,
    required this.onDelete,
    required this.onAddMore,
    required this.emptyLabel,
    this.onEdit,
    this.icon = Icons.description_outlined,
    this.showPageCount = false,
  });

  final List<SelectedDocument> documents;
  final ValueChanged<String> onDelete;
  final VoidCallback onAddMore;
  final String emptyLabel;
  final ValueChanged<String>? onEdit;
  final IconData icon;
  final bool showPageCount;

  @override
  Widget build(BuildContext context) {
    final itemCount = documents.length + 1;

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
        if (index == documents.length) {
          return _AddMoreTile(onTap: onAddMore);
        }
        final doc = documents[index];
        return _DocumentTile(
          document: doc,
          icon: icon,
          showPageCount: showPageCount,
          onDelete: () => onDelete(doc.id),
          onEdit: onEdit == null ? null : () => onEdit!(doc.id),
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

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.icon,
    required this.onDelete,
    required this.showPageCount,
    this.onEdit,
  });

  final SelectedDocument document;
  final IconData icon;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final bool showPageCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: isDark ? AppColors.darkMuted : AppColors.brandSoft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 28, 10, onEdit != null ? 36 : 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.brand, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    document.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    showPageCount && document.pageCount > 0
                        ? LocaleKeys.wordPages.trParams({
                            'count': '${document.pageCount}',
                          })
                        : document.formattedSize,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
          if (onEdit != null)
            Positioned(
              left: 6,
              bottom: 6,
              right: 6,
              child: Material(
                color: AppColors.brand.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            LocaleKeys.editImage.tr,
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
