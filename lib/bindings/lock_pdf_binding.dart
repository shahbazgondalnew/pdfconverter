import 'package:get/get.dart';

import '../controllers/lock_pdf_controller.dart';

class LockPdfBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LockPdfController>()) {
      Get.put(LockPdfController(), permanent: true);
    }
  }
}
