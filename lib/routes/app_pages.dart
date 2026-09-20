import 'package:get/get.dart';

import '../bindings/excel_to_pdf_binding.dart';
import '../bindings/html_to_pdf_binding.dart';
import '../bindings/image_to_pdf_binding.dart';
import '../bindings/scan_to_pdf_binding.dart';
import '../bindings/text_to_pdf_binding.dart';
import '../bindings/word_to_pdf_binding.dart';
import '../controllers/pdf_conversion_controller.dart';
import '../screens/main_navigation.dart';
import '../screens/tools/excel_to_pdf/excel_edit_screen.dart';
import '../screens/tools/excel_to_pdf/excel_to_pdf_screen.dart';
import '../screens/tools/html_to_pdf/html_edit_screen.dart';
import '../screens/tools/html_to_pdf/html_to_pdf_screen.dart';
import '../screens/tools/image_to_pdf/image_edit_screen.dart';
import '../screens/tools/image_to_pdf/image_to_pdf_screen.dart';
import '../screens/tools/pdf_result/pdf_conversion_screens.dart';
import '../screens/tools/scan_to_pdf/scan_to_pdf_screen.dart';
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
