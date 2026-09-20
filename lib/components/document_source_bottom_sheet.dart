import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../theme/app_colors.dart';

/// Bottom sheet for document tools (Word / Excel).
/// Only shows file-based options — no gallery/camera.
class DocumentSourceBottomSheet extends StatelessWidget {
  const DocumentSourceBottomSheet({
    super.key,
    required this.title,
  });

  final String title;

  /// Returns `true` when the user chooses Files, otherwise null.
  static Future<bool?> show({required String title}) {
    return Get.bottomSheet<bool>(
      DocumentSourceBottomSheet(title: title),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Material(
              color: isDark
                  ? AppColors.darkMuted
                  : AppColors.brandSoft.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => Get.back(result: true),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.folder_open_outlined,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          LocaleKeys.fromFile.tr,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(LocaleKeys.cancel.tr),
            ),
          ],
        ),
      ),
    );
  }
}
