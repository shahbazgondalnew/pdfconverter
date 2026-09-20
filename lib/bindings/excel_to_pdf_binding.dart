import 'package:get/get.dart';

import '../controllers/excel_to_pdf_controller.dart';

class ExcelToPdfBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ExcelToPdfController>()) {
      Get.lazyPut(() => ExcelToPdfController(), fenix: true);
    }
  }
}
