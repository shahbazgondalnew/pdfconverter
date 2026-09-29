import 'package:get/get.dart';

import '../controllers/heic_to_jpg_controller.dart';

class HeicToJpgBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HeicToJpgController>()) {
      Get.put(HeicToJpgController(), permanent: true);
    }
  }
}

class HeicToJpgEditBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HeicToJpgController>()) {
      Get.put(HeicToJpgController(), permanent: true);
    }
    Get.put(HeicToJpgEditController());
  }
}
