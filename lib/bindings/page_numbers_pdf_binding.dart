import 'package:get/get.dart';

import '../controllers/page_numbers_pdf_controller.dart';

class PageNumbersPdfBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PageNumbersPdfController>()) {
      Get.put(PageNumbersPdfController(), permanent: true);
    }
  }
}

class PageNumbersPdfEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PageNumbersPdfEditController());
  }
}
