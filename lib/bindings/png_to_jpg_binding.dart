import 'package:get/get.dart';

import '../controllers/png_to_jpg_controller.dart';

class PngToJpgBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PngToJpgController>()) {
      Get.put(PngToJpgController(), permanent: true);
    }
  }
}

class PngToJpgEditBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PngToJpgController>()) {
      Get.put(PngToJpgController(), permanent: true);
    }
    Get.put(PngToJpgEditController());
  }
}
