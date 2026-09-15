import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../controllers/pdf_conversion_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../models/conversion_record.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';

class PdfProgressScreen extends GetView<PdfProgressController> {
  const PdfProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Obx(() {
                if (controller.errorMessage.value != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 56,
                          color: AppColors.brand,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.errorMessage.value!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => Get.back(),
                          child: Text(LocaleKeys.cancel.tr),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brand.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 42,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      LocaleKeys.convertingPdf.tr,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      LocaleKeys.conversionProgress.trParams({
                        'done': '${controller.completed.value}',
                        'total': '${controller.total.value}',
                      }),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 28),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: controller.progress,
                        minHeight: 10,
                        backgroundColor: AppColors.brandSoft,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(controller.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      LocaleKeys.pleaseWait.tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class PdfResultScreen extends GetView<PdfResultController> {
  const PdfResultScreen({super.key});

  Future<void> _share(ConversionRecord record) async {
    final file = File(record.path);
    if (!await file.exists()) {
      Get.snackbar(
        LocaleKeys.toolImageToPdf.tr,
        LocaleKeys.fileMissing.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    await Share.shareXFiles(
      [XFile(record.path, mimeType: 'application/pdf', name: record.name)],
      subject: record.name,
      text: LocaleKeys.sharePdfText.trParams({'name': record.name}),
    );
  }

  Future<void> _save(ConversionRecord record) async {
    // Opens the system share/save sheet so the user can save to Files/Drive/etc.
    // The PDF is already stored in the app documents directory via Hive metadata.
    await _share(record);
  }

  Future<void> _open(ConversionRecord record) async {
    final result = await OpenFilex.open(record.path);
    if (result.type != ResultType.done) {
      Get.snackbar(
        LocaleKeys.toolImageToPdf.tr,
        LocaleKeys.openPdfFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  void _done() {
    Get.until((route) => route.settings.name == AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final record = controller.record;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _done();
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(LocaleKeys.pdfReady.tr),
            actions: [
              TextButton(
                onPressed: _done,
                child: Text(LocaleKeys.done.tr),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xFFEEDFDF),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.brand.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.brand,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                record.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                LocaleKeys.pdfMeta.trParams({
                                  'size': record.formattedSize,
                                  'pages': '${record.pageCount}',
                                }),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                LocaleKeys.savedLocallyHint.tr,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => _share(record),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: Text(LocaleKeys.sharePdf.tr),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _save(record),
                      icon: const Icon(Icons.save_alt_rounded),
                      label: Text(LocaleKeys.savePdf.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brand,
                        side: const BorderSide(color: AppColors.brand),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton.icon(
                      onPressed: () => _open(record),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(LocaleKeys.openPdf.tr),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
