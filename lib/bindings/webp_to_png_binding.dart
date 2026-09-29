import 'package:get/get.dart';

import '../controllers/webp_to_png_controller.dart';

class WebpToPngBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<WebpToPngController>()) {
      Get.put(WebpToPngController(), permanent: true);
    }
  }
}

class WebpToPngEditBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<WebpToPngController>()) {
      Get.put(WebpToPngController(), permanent: true);
    }
    Get.put(WebpToPngEditController());
  }
}
