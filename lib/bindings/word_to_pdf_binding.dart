import 'package:get/get.dart';

import '../controllers/word_edit_controller.dart';
import '../controllers/word_to_pdf_controller.dart';

class WordToPdfBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<WordToPdfController>()) {
      Get.lazyPut(() => WordToPdfController(), fenix: true);
    }
  }
}

class WordEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WordEditController());
  }
}
