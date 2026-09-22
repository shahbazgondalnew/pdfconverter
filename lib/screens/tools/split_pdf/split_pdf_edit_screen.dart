import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/split_pdf_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class SplitPdfEditScreen extends GetView<SplitPdfEditController> {
  const SplitPdfEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(LocaleKeys.editImage.tr),
          actions: [
            TextButton(
              onPressed: controller.save,
              child: Text(
                LocaleKeys.save.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        body: Obx(() {
          final image = controller.draft.value;
          if (image == null) {
            return Center(child: Text(LocaleKeys.noPagesSelected.tr));
          }

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Transform.rotate(
                          angle: image.rotation * 3.1415926535 / 180,
                          child: Image.file(
                            File(image.path),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _EditActionButton(
                          icon: Icons.crop_rounded,
                          label: LocaleKeys.crop.tr,
                          onTap:
                              controller.isBusy.value ? null : controller.crop,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _EditActionButton(
                          icon: Icons.rotate_left_rounded,
                          label: LocaleKeys.rotateLeft.tr,
                          onTap: controller.rotateLeft,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _EditActionButton(
                          icon: Icons.rotate_right_rounded,
                          label: LocaleKeys.rotateRight.tr,
                          onTap: controller.rotateRight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _EditActionButton extends StatelessWidget {
  const _EditActionButton({
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
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFEEDFDF),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.brand),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
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
