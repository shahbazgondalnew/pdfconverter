import 'package:get/get.dart';

import '../controllers/sign_pdf_controller.dart';

class SignPdfBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SignPdfController>()) {
      Get.put(SignPdfController(), permanent: true);
    }
  }
}

class SignPdfDrawBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SignPdfDrawController());
  }
}
