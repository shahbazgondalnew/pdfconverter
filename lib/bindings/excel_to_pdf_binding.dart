import 'package:get/get.dart';

import '../controllers/excel_edit_controller.dart';
import '../controllers/excel_to_pdf_controller.dart';

class ExcelToPdfBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
  }
}

class ExcelEditBinding extends Bindings {
  @override
  void dependencies() {
    _ensureParent();
    if (Get.isRegistered<ExcelEditController>()) {
      Get.delete<ExcelEditController>(force: true);
    }
    Get.put(ExcelEditController());
  }
}

void _ensureParent() {
  if (!Get.isRegistered<ExcelToPdfController>()) {
    Get.put(ExcelToPdfController(), permanent: true);
  }
}
