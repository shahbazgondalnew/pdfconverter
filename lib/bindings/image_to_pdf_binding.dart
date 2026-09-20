import 'package:get/get.dart';

import '../controllers/image_edit_controller.dart';
import '../controllers/image_to_pdf_controller.dart';

class ImageToPdfBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
  }
}

class ImageEditBinding extends Bindings {
  @override
  void dependencies() {
    // Keep parent alive — GetX SmartManagement can drop it on push otherwise.
    _ensureParent();
    if (Get.isRegistered<ImageEditController>()) {
      Get.delete<ImageEditController>(force: true);
    }
    Get.put(ImageEditController());
  }
}

void _ensureParent() {
  if (!Get.isRegistered<ImageToPdfController>()) {
    Get.put(ImageToPdfController(), permanent: true);
  }
}
