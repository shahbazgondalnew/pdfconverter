import 'package:get/get.dart';

import '../controllers/crop_image_controller.dart';

class CropImageBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CropImageController>()) {
      Get.put(CropImageController(), permanent: true);
    }
  }
}

class CropImageEditBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CropImageController>()) {
      Get.put(CropImageController(), permanent: true);
    }
    Get.put(CropImageEditController());
  }
}
