import 'package:get/get.dart';

import '../controllers/delete_pages_pdf_controller.dart';

class DeletePagesPdfBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DeletePagesPdfController>()) {
      Get.put(DeletePagesPdfController(), permanent: true);
    }
  }
}
