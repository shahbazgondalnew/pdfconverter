import 'package:get/get.dart';

import '../controllers/rotate_pdf_controller.dart';

class RotatePdfBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RotatePdfController>()) {
      Get.put(RotatePdfController(), permanent: true);
    }
  }
}
