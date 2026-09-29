import 'package:get/get.dart';

import '../controllers/unlock_pdf_controller.dart';

class UnlockPdfBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UnlockPdfController>()) {
      Get.put(UnlockPdfController(), permanent: true);
    }
  }
}
