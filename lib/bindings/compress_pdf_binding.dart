import 'package:get/get.dart';

import '../controllers/compress_pdf_controller.dart';

class CompressPdfBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
  }
}

class CompressPdfEditBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
    if (Get.isRegistered<CompressPdfEditController>()) {
      Get.delete<CompressPdfEditController>(force: true);
    }
    Get.put(CompressPdfEditController());
  }
}

void _ensureParent() {
  if (!Get.isRegistered<CompressPdfController>()) {
    Get.put(CompressPdfController(), permanent: true);
  }
}
