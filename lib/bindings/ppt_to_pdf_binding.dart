import 'package:get/get.dart';

import '../controllers/ppt_edit_controller.dart';
import '../controllers/ppt_to_pdf_controller.dart';

class PptToPdfBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
  }
}

class PptEditBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
    if (Get.isRegistered<PptEditController>()) {
      Get.delete<PptEditController>(force: true);
    }
    Get.put(PptEditController());
  }
}

void _ensureParent() {
  if (!Get.isRegistered<PptToPdfController>()) {
    Get.put(PptToPdfController(), permanent: true);
  }
}
