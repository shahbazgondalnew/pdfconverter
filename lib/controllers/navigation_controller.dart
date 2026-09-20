import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';

import 'history_controller.dart';

class NavigationController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 1) {
      if (Get.isRegistered<HistoryController>()) {
        Get.find<HistoryController>().reload();
      }
      _requestInAppReview();
    }
  }

  Future<void> _requestInAppReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {
      // Ignore — store review UI is optional and platform-gated.
    }
  }
}
