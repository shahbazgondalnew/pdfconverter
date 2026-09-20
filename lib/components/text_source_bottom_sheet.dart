import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../theme/app_colors.dart';

enum TextSourceOption { paste, files }

/// Bottom sheet for Text/HTML to PDF: paste content or pick files.
class TextSourceBottomSheet extends StatelessWidget {
  const TextSourceBottomSheet({
    super.key,
    this.titleKey = LocaleKeys.addTextContent,
    this.pasteKey = LocaleKeys.pasteText,
  });

  final String titleKey;
  final String pasteKey;

  static Future<TextSourceOption?> show({
    String titleKey = LocaleKeys.addTextContent,
    String pasteKey = LocaleKeys.pasteText,
  }) {
    return Get.bottomSheet<TextSourceOption>(
      TextSourceBottomSheet(titleKey: titleKey, pasteKey: pasteKey),
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
              titleKey.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            _SourceTile(
              icon: Icons.content_paste_rounded,
              label: pasteKey.tr,
              isDark: isDark,
              onTap: () => Get.back(result: TextSourceOption.paste),
            ),
            const SizedBox(height: 10),
            _SourceTile(
              icon: Icons.folder_open_outlined,
              label: LocaleKeys.fromFile.tr,
              isDark: isDark,
              onTap: () => Get.back(result: TextSourceOption.files),
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

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? AppColors.darkMuted
          : AppColors.brandSoft.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.brand),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
    );
  }
}
