import 'package:get/get.dart';

import '../controllers/jpg_to_png_controller.dart';

class JpgToPngBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<JpgToPngController>()) {
      Get.put(JpgToPngController(), permanent: true);
    }
  }
}

class JpgToPngEditBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<JpgToPngController>()) {
      Get.put(JpgToPngController(), permanent: true);
    }
    Get.put(JpgToPngEditController());
  }
}
