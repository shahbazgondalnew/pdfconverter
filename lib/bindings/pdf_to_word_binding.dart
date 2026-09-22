import 'package:get/get.dart';

import '../controllers/pdf_to_word_controller.dart';

class PdfToWordBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PdfToWordController>()) {
      Get.put(PdfToWordController(), permanent: true);
    }
  }
}
