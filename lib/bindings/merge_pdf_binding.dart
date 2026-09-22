import 'package:get/get.dart';

import '../controllers/merge_pdf_controller.dart';

class MergePdfBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
  }
}

class MergePdfEditBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
    if (Get.isRegistered<MergePdfEditController>()) {
      Get.delete<MergePdfEditController>(force: true);
    }
    Get.put(MergePdfEditController());
  }
}

void _ensureParent() {
  if (!Get.isRegistered<MergePdfController>()) {
    Get.put(MergePdfController(), permanent: true);
  }
}
