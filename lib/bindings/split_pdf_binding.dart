import 'package:get/get.dart';

import '../controllers/split_pdf_controller.dart';

class SplitPdfBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
  }
}

class SplitPdfEditBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
    if (Get.isRegistered<SplitPdfEditController>()) {
      Get.delete<SplitPdfEditController>(force: true);
    }
    Get.put(SplitPdfEditController());
  }
}

void _ensureParent() {
  if (!Get.isRegistered<SplitPdfController>()) {
    Get.put(SplitPdfController(), permanent: true);
  }
}
