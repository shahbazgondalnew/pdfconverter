import 'package:get/get.dart';

import '../controllers/text_edit_controller.dart';
import '../controllers/text_to_pdf_controller.dart';

class TextToPdfBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
  }
}

class TextEditBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
    if (Get.isRegistered<TextEditController>()) {
      Get.delete<TextEditController>(force: true);
    }
    Get.put(TextEditController());
  }
}

void _ensureParent() {
  if (!Get.isRegistered<TextToPdfController>()) {
    Get.put(TextToPdfController(), permanent: true);
  }
}
