import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../services/gallery_save_service.dart';
import '../theme/app_colors.dart';

/// Bottom sheet to pick which images to save to the device gallery.
class SelectImagesToSaveSheet extends StatefulWidget {
  const SelectImagesToSaveSheet({
    super.key,
    required this.files,
    this.snackTitle = LocaleKeys.toolPdfToImage,
  });

  final List<File> files;
  final String snackTitle;

  /// Opens the sheet. Returns `true` if images were saved.
  static Future<bool?> show({
    required List<File> files,
    String snackTitle = LocaleKeys.toolPdfToImage,
  }) {
    if (files.isEmpty) return Future.value(false);
    return Get.bottomSheet<bool>(
      SelectImagesToSaveSheet(files: files, snackTitle: snackTitle),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<SelectImagesToSaveSheet> createState() =>
      _SelectImagesToSaveSheetState();
}

class _SelectImagesToSaveSheetState extends State<SelectImagesToSaveSheet> {
  late final Set<int> _selected;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = {for (var i = 0; i < widget.files.length; i++) i};
  }

  void _selectAll() {
    setState(() {
      _selected
        ..clear()
        ..addAll(List.generate(widget.files.length, (i) => i));
    });
  }

  void _deselectAll() {
    setState(_selected.clear);
  }

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  Future<void> _saveSelected() async {
    if (_selected.isEmpty || _saving) return;
    setState(() => _saving = true);
    final files = _selected.map((i) => widget.files[i]).toList();
    final ok = await const GallerySaveService().saveFiles(
      files,
      snackTitle: widget.snackTitle,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Get.back(result: ok);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSelected = _selected.length == widget.files.length;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.85),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      LocaleKeys.selectImages.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(result: false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: allSelected ? null : _selectAll,
                    child: Text(LocaleKeys.selectAll.tr),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty ? null : _deselectAll,
                    child: Text(LocaleKeys.deselectAll.tr),
                  ),
                  const Spacer(),
                  Text(
                    LocaleKeys.selectedCount.trParams({
                      'count': '${_selected.length}',
                      'total': '${widget.files.length}',
                    }),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemCount: widget.files.length,
                itemBuilder: (context, index) {
                  final file = widget.files[index];
                  final selected = _selected.contains(index);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _toggle(index),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color: AppColors.lightMuted,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? AppColors.brand
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              color: selected
                                  ? AppColors.brand.withValues(alpha: 0.12)
                                  : Colors.transparent,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? AppColors.brand
                                    : Colors.black.withValues(alpha: 0.45),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _selected.isEmpty || _saving ? null : _saveSelected,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.photo_library_outlined),
                  label: Text(LocaleKeys.saveSelectedImages.tr),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
