import 'package:get/get.dart';

import '../controllers/image_edit_controller.dart';
import '../controllers/image_to_pdf_controller.dart';

class ImageToPdfBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ImageToPdfController>()) {
      Get.lazyPut(() => ImageToPdfController(), fenix: true);
    }
  }
}

class ImageEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ImageEditController());
  }
}
