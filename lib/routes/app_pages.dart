import 'package:get/get.dart';

import '../bindings/image_to_pdf_binding.dart';
import '../controllers/pdf_conversion_controller.dart';
import '../screens/main_navigation.dart';
import '../screens/tools/image_to_pdf/image_edit_screen.dart';
import '../screens/tools/image_to_pdf/image_to_pdf_screen.dart';
import '../screens/tools/pdf_result/pdf_conversion_screens.dart';
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
