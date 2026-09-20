import 'package:get/get.dart';

import '../controllers/html_edit_controller.dart';
import '../controllers/html_to_pdf_controller.dart';

class HtmlToPdfBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
  }
}

class HtmlEditBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
    if (Get.isRegistered<HtmlEditController>()) {
      Get.delete<HtmlEditController>(force: true);
    }
    Get.put(HtmlEditController());
  }
}

void _ensureParent() {
  if (!Get.isRegistered<HtmlToPdfController>()) {
    Get.put(HtmlToPdfController(), permanent: true);
  }
}
