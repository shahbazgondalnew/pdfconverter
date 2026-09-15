import 'package:get/get.dart';

class HistoryController extends GetxController {
  final conversions = <String>[].obs;

  bool get hasConversions => conversions.isNotEmpty;

  void addConversion(String name) {
    conversions.add(name);
  }

  void clearHistory() {
    conversions.clear();
  }
}
