import 'package:get/get.dart';

import '../bindings/compress_image_binding.dart';
import '../bindings/compress_pdf_binding.dart';
import '../bindings/crop_image_binding.dart';
import '../bindings/delete_pages_pdf_binding.dart';
import '../bindings/extract_pages_binding.dart';
import '../bindings/excel_to_pdf_binding.dart';
import '../bindings/html_to_pdf_binding.dart';
import '../bindings/image_to_pdf_binding.dart';
import '../bindings/lock_pdf_binding.dart';
import '../bindings/merge_pdf_binding.dart';
import '../bindings/heic_to_jpg_binding.dart';
import '../bindings/jpg_to_png_binding.dart';
import '../bindings/page_numbers_pdf_binding.dart';
import '../bindings/png_to_jpg_binding.dart';
import '../bindings/sign_pdf_binding.dart';
import '../bindings/unlock_pdf_binding.dart';
import '../bindings/watermark_pdf_binding.dart';
import '../bindings/webp_to_png_binding.dart';
import '../bindings/pdf_to_image_binding.dart';
import '../bindings/pdf_to_word_binding.dart';
import '../bindings/ppt_to_pdf_binding.dart';
import '../bindings/reorder_pdf_binding.dart';
import '../bindings/rotate_pdf_binding.dart';
import '../bindings/scan_to_pdf_binding.dart';
import '../bindings/split_pdf_binding.dart';
import '../bindings/text_to_pdf_binding.dart';
import '../bindings/word_to_pdf_binding.dart';
import '../controllers/pdf_conversion_controller.dart';
import '../screens/main_navigation.dart';
import '../screens/tools/compress_image/compress_image_edit_screen.dart';
import '../screens/tools/compress_image/compress_image_screen.dart';
import '../screens/tools/compress_pdf/compress_pdf_edit_screen.dart';
import '../screens/tools/compress_pdf/compress_pdf_screen.dart';
import '../screens/tools/crop_image/crop_image_edit_screen.dart';
import '../screens/tools/crop_image/crop_image_screen.dart';
import '../screens/tools/delete_pages_pdf/delete_pages_pdf_screen.dart';
import '../screens/tools/extract_pages/extract_pages_screen.dart';
import '../screens/tools/excel_to_pdf/excel_edit_screen.dart';
import '../screens/tools/excel_to_pdf/excel_to_pdf_screen.dart';
import '../screens/tools/html_to_pdf/html_edit_screen.dart';
import '../screens/tools/html_to_pdf/html_to_pdf_screen.dart';
import '../screens/tools/image_to_pdf/image_edit_screen.dart';
import '../screens/tools/image_to_pdf/image_to_pdf_screen.dart';
import '../screens/tools/merge_pdf/merge_pdf_edit_screen.dart';
import '../screens/tools/merge_pdf/merge_pdf_screen.dart';
import '../screens/tools/heic_to_jpg/heic_to_jpg_edit_screen.dart';
import '../screens/tools/heic_to_jpg/heic_to_jpg_screen.dart';
import '../screens/tools/jpg_to_png/jpg_to_png_edit_screen.dart';
import '../screens/tools/jpg_to_png/jpg_to_png_screen.dart';
import '../screens/tools/lock_pdf/lock_pdf_screen.dart';
import '../screens/tools/page_numbers_pdf/page_numbers_pdf_edit_screen.dart';
import '../screens/tools/page_numbers_pdf/page_numbers_pdf_screen.dart';
import '../screens/tools/png_to_jpg/png_to_jpg_edit_screen.dart';
import '../screens/tools/png_to_jpg/png_to_jpg_screen.dart';
import '../screens/tools/sign_pdf/sign_pdf_draw_screen.dart';
import '../screens/tools/sign_pdf/sign_pdf_screen.dart';
import '../screens/tools/unlock_pdf/unlock_pdf_screen.dart';
import '../screens/tools/watermark_pdf/watermark_pdf_edit_screen.dart';
import '../screens/tools/watermark_pdf/watermark_pdf_screen.dart';
import '../screens/tools/webp_to_png/webp_to_png_edit_screen.dart';
import '../screens/tools/webp_to_png/webp_to_png_screen.dart';
import '../screens/tools/pdf_result/pdf_conversion_screens.dart';
import '../screens/tools/pdf_to_image/pdf_to_image_edit_screen.dart';
import '../screens/tools/pdf_to_image/pdf_to_image_screen.dart';
import '../screens/tools/pdf_to_word/pdf_to_word_screen.dart';
import '../screens/tools/ppt_to_pdf/ppt_edit_screen.dart';
import '../screens/tools/ppt_to_pdf/ppt_to_pdf_screen.dart';
import '../screens/tools/reorder_pdf/reorder_pdf_screen.dart';
import '../screens/tools/rotate_pdf/rotate_pdf_screen.dart';
import '../screens/tools/scan_to_pdf/scan_to_pdf_screen.dart';
import '../screens/tools/split_pdf/split_pdf_edit_screen.dart';
import '../screens/tools/split_pdf/split_pdf_screen.dart';
import '../screens/tools/text_to_pdf/text_edit_screen.dart';
import '../screens/tools/text_to_pdf/text_to_pdf_screen.dart';
import '../screens/tools/word_to_pdf/word_edit_screen.dart';
import '../screens/tools/word_to_pdf/word_to_pdf_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.home,
      page: () => const MainNavigation(),
    ),
    GetPage(
      name: AppRoutes.imageToPdf,
      page: () => const ImageToPdfScreen(),
      binding: ImageToPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.imageEdit,
      page: () => const ImageEditScreen(),
      binding: ImageEditBinding(),
    ),
    GetPage(
      name: AppRoutes.scanToPdf,
      page: () => const ScanToPdfScreen(),
      binding: ScanToPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.wordToPdf,
      page: () => const WordToPdfScreen(),
      binding: WordToPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.wordEdit,
      page: () => const WordEditScreen(),
      binding: WordEditBinding(),
    ),
    GetPage(
      name: AppRoutes.excelToPdf,
      page: () => const ExcelToPdfScreen(),
      binding: ExcelToPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.excelEdit,
      page: () => const ExcelEditScreen(),
      binding: ExcelEditBinding(),
    ),
    GetPage(
      name: AppRoutes.textToPdf,
      page: () => const TextToPdfScreen(),
      binding: TextToPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.textEdit,
      page: () => const TextEditScreen(),
      binding: TextEditBinding(),
    ),
    GetPage(
      name: AppRoutes.htmlToPdf,
      page: () => const HtmlToPdfScreen(),
      binding: HtmlToPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.htmlEdit,
      page: () => const HtmlEditScreen(),
      binding: HtmlEditBinding(),
    ),
    GetPage(
      name: AppRoutes.pptToPdf,
      page: () => const PptToPdfScreen(),
      binding: PptToPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.pptEdit,
      page: () => const PptEditScreen(),
      binding: PptEditBinding(),
    ),
    GetPage(
      name: AppRoutes.pdfToImage,
      page: () => const PdfToImageScreen(),
      binding: PdfToImageBinding(),
    ),
    GetPage(
      name: AppRoutes.pdfToImageEdit,
      page: () => const PdfToImageEditScreen(),
      binding: PdfToImageEditBinding(),
    ),
    GetPage(
      name: AppRoutes.pdfToWord,
      page: () => const PdfToWordScreen(),
      binding: PdfToWordBinding(),
    ),
    GetPage(
      name: AppRoutes.mergePdf,
      page: () => const MergePdfScreen(),
      binding: MergePdfBinding(),
    ),
    GetPage(
      name: AppRoutes.mergePdfEdit,
      page: () => const MergePdfEditScreen(),
      binding: MergePdfEditBinding(),
    ),
    GetPage(
      name: AppRoutes.splitPdf,
      page: () => const SplitPdfScreen(),
      binding: SplitPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.splitPdfEdit,
      page: () => const SplitPdfEditScreen(),
      binding: SplitPdfEditBinding(),
    ),
    GetPage(
      name: AppRoutes.compressPdf,
      page: () => const CompressPdfScreen(),
      binding: CompressPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.compressPdfEdit,
      page: () => const CompressPdfEditScreen(),
      binding: CompressPdfEditBinding(),
    ),
    GetPage(
      name: AppRoutes.rotatePdf,
      page: () => const RotatePdfScreen(),
      binding: RotatePdfBinding(),
    ),
    GetPage(
      name: AppRoutes.reorderPdf,
      page: () => const ReorderPdfScreen(),
      binding: ReorderPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.deletePagesPdf,
      page: () => const DeletePagesPdfScreen(),
      binding: DeletePagesPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.extractPages,
      page: () => const ExtractPagesScreen(),
      binding: ExtractPagesBinding(),
    ),
    GetPage(
      name: AppRoutes.pageNumbersPdf,
      page: () => const PageNumbersPdfScreen(),
      binding: PageNumbersPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.pageNumbersPdfEdit,
      page: () => const PageNumbersPdfEditScreen(),
      binding: PageNumbersPdfEditBinding(),
    ),
    GetPage(
      name: AppRoutes.watermarkPdf,
      page: () => const WatermarkPdfScreen(),
      binding: WatermarkPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.watermarkPdfEdit,
      page: () => const WatermarkPdfEditScreen(),
      binding: WatermarkPdfEditBinding(),
    ),
    GetPage(
      name: AppRoutes.pngToJpg,
      page: () => const PngToJpgScreen(),
      binding: PngToJpgBinding(),
    ),
    GetPage(
      name: AppRoutes.pngToJpgEdit,
      page: () => const PngToJpgEditScreen(),
      binding: PngToJpgEditBinding(),
    ),
    GetPage(
      name: AppRoutes.jpgToPng,
      page: () => const JpgToPngScreen(),
      binding: JpgToPngBinding(),
    ),
    GetPage(
      name: AppRoutes.jpgToPngEdit,
      page: () => const JpgToPngEditScreen(),
      binding: JpgToPngEditBinding(),
    ),
    GetPage(
      name: AppRoutes.webpToPng,
      page: () => const WebpToPngScreen(),
      binding: WebpToPngBinding(),
    ),
    GetPage(
      name: AppRoutes.webpToPngEdit,
      page: () => const WebpToPngEditScreen(),
      binding: WebpToPngEditBinding(),
    ),
    GetPage(
      name: AppRoutes.heicToJpg,
      page: () => const HeicToJpgScreen(),
      binding: HeicToJpgBinding(),
    ),
    GetPage(
      name: AppRoutes.heicToJpgEdit,
      page: () => const HeicToJpgEditScreen(),
      binding: HeicToJpgEditBinding(),
    ),
    GetPage(
      name: AppRoutes.compressImage,
      page: () => const CompressImageScreen(),
      binding: CompressImageBinding(),
    ),
    GetPage(
      name: AppRoutes.compressImageEdit,
      page: () => const CompressImageEditScreen(),
      binding: CompressImageEditBinding(),
    ),
    GetPage(
      name: AppRoutes.cropImage,
      page: () => const CropImageScreen(),
      binding: CropImageBinding(),
    ),
    GetPage(
      name: AppRoutes.cropImageEdit,
      page: () => const CropImageEditScreen(),
      binding: CropImageEditBinding(),
    ),
    GetPage(
      name: AppRoutes.lockPdf,
      page: () => const LockPdfScreen(),
      binding: LockPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.unlockPdf,
      page: () => const UnlockPdfScreen(),
      binding: UnlockPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.signPdf,
      page: () => const SignPdfScreen(),
      binding: SignPdfBinding(),
    ),
    GetPage(
      name: AppRoutes.signPdfDraw,
      page: () => const SignPdfDrawScreen(),
      binding: SignPdfDrawBinding(),
    ),
    GetPage(
      name: AppRoutes.pdfProgress,
      page: () => const PdfProgressScreen(),
      binding: BindingsBuilder(() {
        Get.put(PdfProgressController());
      }),
    ),
    GetPage(
      name: AppRoutes.pdfResult,
      page: () => const PdfResultScreen(),
      binding: BindingsBuilder(() {
        Get.put(PdfResultController());
      }),
    ),
  ];
}
