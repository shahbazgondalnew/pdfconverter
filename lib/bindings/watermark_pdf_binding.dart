import 'package:get/get.dart';

import '../controllers/watermark_pdf_controller.dart';

class WatermarkPdfBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<WatermarkPdfController>()) {
      Get.put(WatermarkPdfController(), permanent: true);
    }
  }
}

class WatermarkPdfEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(WatermarkPdfEditController());
  }
}
