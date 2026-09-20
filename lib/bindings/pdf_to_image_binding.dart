import 'package:get/get.dart';

import '../controllers/pdf_to_image_controller.dart';

class PdfToImageBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
  }
}

class PdfToImageEditBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
    if (Get.isRegistered<PdfToImageEditController>()) {
      Get.delete<PdfToImageEditController>(force: true);
    }
    Get.put(PdfToImageEditController());
  }
}

void _ensureParent() {
  if (!Get.isRegistered<PdfToImageController>()) {
    Get.put(PdfToImageController(), permanent: true);
  }
}
