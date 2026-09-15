import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../models/conversion_record.dart';
import '../models/image_to_pdf_models.dart';
import '../routes/app_routes.dart';
import '../services/image_to_pdf_service.dart';
import 'history_controller.dart';

class PdfProgressController extends GetxController {
  final total = 0.obs;
  final completed = 0.obs;
  final isWorking = true.obs;
  final errorMessage = RxnString();

  late final List<SelectedImage> _images;
  late final PdfPageSettings _settings;
  final _service = const ImageToPdfService();

  double get progress {
    if (total.value == 0) return 0;
    return completed.value / total.value;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is! Map) {
      errorMessage.value = LocaleKeys.conversionFailed.tr;
      isWorking.value = false;
      return;
    }

    _images = List<SelectedImage>.from(args['images'] as List);
    _settings = args['settings'] as PdfPageSettings;
    total.value = _images.length;
    _start();
  }

  Future<void> _start() async {
    try {
      final record = await _service.convert(
        images: _images,
        settings: _settings,
        onProgress: (done, all) {
          completed.value = done;
          total.value = all;
        },
      );

      if (Get.isRegistered<HistoryController>()) {
        Get.find<HistoryController>().reload();
      }

      Get.offNamed(AppRoutes.pdfResult, arguments: record);
    } catch (_) {
      errorMessage.value = LocaleKeys.conversionFailed.tr;
      isWorking.value = false;
    }
  }
}

class PdfResultController extends GetxController {
  late final ConversionRecord record;

  @override
  void onInit() {
    super.onInit();
    record = Get.arguments as ConversionRecord;
  }
}
