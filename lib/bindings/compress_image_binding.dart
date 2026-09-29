import 'package:get/get.dart';

import '../controllers/compress_image_controller.dart';

class CompressImageBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CompressImageController>()) {
      Get.put(CompressImageController(), permanent: true);
    }
  }
}

class CompressImageEditBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CompressImageController>()) {
      Get.put(CompressImageController(), permanent: true);
    }
    Get.put(CompressImageEditController());
  }
}
