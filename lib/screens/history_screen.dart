import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/history_controller.dart';
import '../localization/locale_keys.dart';

class HistoryScreen extends GetView<HistoryController> {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.historyTitle.tr),
        actions: [
          Obx(
            () => controller.hasConversions
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: controller.clearHistory,
                    tooltip: LocaleKeys.historyClear.tr,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (!controller.hasConversions) {
          return Center(
            child: Text(
              LocaleKeys.historyEmpty.tr,
              style: const TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.conversions.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(controller.conversions[index]),
            );
          },
        );
      }),
    );
  }
}
