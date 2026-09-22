import 'package:get/get.dart';

import '../controllers/reorder_pdf_controller.dart';

class ReorderPdfBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ReorderPdfController>()) {
      Get.put(ReorderPdfController(), permanent: true);
    }
  }
}
