import 'package:get/get.dart';

import '../controllers/scan_to_pdf_controller.dart';

class ScanToPdfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScanToPdfController());
  }
}
