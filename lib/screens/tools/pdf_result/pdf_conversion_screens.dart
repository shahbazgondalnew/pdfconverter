import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../controllers/pdf_conversion_controller.dart';
import '../../../localization/locale_keys.dart';
import '../../../models/conversion_record.dart';
import '../../../routes/app_routes.dart';
import '../../../services/conversion_storage.dart';
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

                final isImageFlow =
                    controller.titleKey.value == LocaleKeys.convertingImages ||
                        controller.titleKey.value == LocaleKeys.savingImages;

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
                      child: Icon(
                        isImageFlow
                            ? Icons.image_outlined
                            : Icons.picture_as_pdf_rounded,
                        size: 42,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      controller.titleKey.value.tr,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      controller.progressLabel.value.trParams({
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
    if (record.isImageGroup) {
      final files = ConversionStorage.resolveFiles(record);
      final existing = <XFile>[];
      for (final file in files) {
        if (await file.exists()) {
          existing.add(
            XFile(file.path, mimeType: 'image/png', name: file.uri.pathSegments.last),
          );
        }
      }
      if (existing.isEmpty) {
        Get.snackbar(
          LocaleKeys.toolPdfToImage.tr,
          LocaleKeys.fileMissing.tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
        return;
      }
      await Share.shareXFiles(
        existing,
        subject: record.name,
        text: LocaleKeys.sharePdfText.trParams({'name': record.name}),
      );
      return;
    }

    final absolutePath = ConversionStorage.resolvePath(record.path);
    final file = File(absolutePath);
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
      [XFile(absolutePath, mimeType: 'application/pdf', name: record.name)],
      subject: record.name,
      text: LocaleKeys.sharePdfText.trParams({'name': record.name}),
    );
  }

  Future<void> _saveToGallery(ConversionRecord record) async {
    try {
      final granted = await Gal.requestAccess();
      if (!granted) {
        Get.snackbar(
          LocaleKeys.toolPdfToImage.tr,
          LocaleKeys.gallerySaveFailed.tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
        return;
      }

      final files = ConversionStorage.resolveFiles(record);
      var saved = 0;
      for (final file in files) {
        if (!await file.exists()) continue;
        await Gal.putImage(file.path, album: 'PDF Converter');
        saved++;
      }

      if (saved == 0) {
        Get.snackbar(
          LocaleKeys.toolPdfToImage.tr,
          LocaleKeys.fileMissing.tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
        return;
      }

      Get.snackbar(
        LocaleKeys.toolPdfToImage.tr,
        LocaleKeys.gallerySaveSuccess.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } catch (_) {
      Get.snackbar(
        LocaleKeys.toolPdfToImage.tr,
        LocaleKeys.gallerySaveFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Future<void> _save(ConversionRecord record) async {
    if (record.isImageGroup) {
      await _saveToGallery(record);
      return;
    }
    await _share(record);
  }

  Future<void> _open(ConversionRecord record) async {
    final absolutePath = ConversionStorage.resolvePath(record.path);
    final file = File(absolutePath);
    if (!await file.exists()) {
      Get.snackbar(
        record.isImageGroup
            ? LocaleKeys.toolPdfToImage.tr
            : LocaleKeys.toolImageToPdf.tr,
        LocaleKeys.fileMissing.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    final result = await OpenFilex.open(absolutePath);
    if (result.type != ResultType.done) {
      Get.snackbar(
        record.isImageGroup
            ? LocaleKeys.toolPdfToImage.tr
            : LocaleKeys.toolImageToPdf.tr,
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
    final isImages = record.isImageGroup;

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
            title: Text(
              isImages ? LocaleKeys.imagesReady.tr : LocaleKeys.pdfReady.tr,
            ),
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
                              if (isImages)
                                _ImageGroupPreview(record: record)
                              else
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.brand.withValues(alpha: 0.12),
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
                                isImages
                                    ? LocaleKeys.imageMeta.trParams({
                                        'size': record.formattedSize,
                                        'count': '${record.pageCount}',
                                      })
                                    : LocaleKeys.pdfMeta.trParams({
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
                      label: Text(
                        isImages
                            ? LocaleKeys.shareImages.tr
                            : LocaleKeys.sharePdf.tr,
                      ),
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
                      icon: Icon(
                        isImages
                            ? Icons.photo_library_outlined
                            : Icons.save_alt_rounded,
                      ),
                      label: Text(
                        isImages
                            ? LocaleKeys.saveToGallery.tr
                            : LocaleKeys.savePdf.tr,
                      ),
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
                      label: Text(
                        isImages
                            ? LocaleKeys.openImages.tr
                            : LocaleKeys.openPdf.tr,
                      ),
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

class _ImageGroupPreview extends StatelessWidget {
  const _ImageGroupPreview({required this.record});

  final ConversionRecord record;

  @override
  Widget build(BuildContext context) {
    final files = ConversionStorage.resolveFiles(record);
    final previewCount = files.length.clamp(0, 4);

    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < previewCount; i++)
            Transform.translate(
              offset: Offset((i - (previewCount - 1) / 2) * 18, i * 2.0),
              child: Transform.rotate(
                angle: (i - (previewCount - 1) / 2) * 0.08,
                child: Container(
                  width: 72,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: FileImage(files[i]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 8,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                LocaleKeys.imageGroupLabel.trParams({
                  'count': '${record.pageCount}',
                }),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
