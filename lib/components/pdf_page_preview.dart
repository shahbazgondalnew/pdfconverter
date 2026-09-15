import 'dart:io';

import 'package:flutter/material.dart';

import '../models/image_to_pdf_models.dart';
import '../theme/app_colors.dart';

/// Preview of how an image will sit on a PDF page.
class PdfPagePreview extends StatelessWidget {
  const PdfPagePreview({
    super.key,
    required this.image,
    required this.settings,
    this.height = 180,
  });

  final SelectedImage? image;
  final PdfPageSettings settings;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 210 / 297,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: settings.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: image == null
            ? Center(
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.brand.withValues(alpha: 0.35),
                  size: 36,
                ),
              )
            : Transform.rotate(
                angle: image!.rotation * 3.1415926535 / 180,
                child: Image.file(
                  File(image!.path),
                  fit: settings.boxFit,
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
      ),
    );
  }
}
