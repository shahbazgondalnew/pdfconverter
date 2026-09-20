import 'package:get/get.dart';

import '../controllers/word_edit_controller.dart';
import '../controllers/word_to_pdf_controller.dart';

class WordToPdfBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
  }
}

class WordEditBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
    if (Get.isRegistered<WordEditController>()) {
      Get.delete<WordEditController>(force: true);
    }
    Get.put(WordEditController());
  }
}

void _ensureParent() {
  if (!Get.isRegistered<WordToPdfController>()) {
    Get.put(WordToPdfController(), permanent: true);
  }
}
