import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/locale_keys.dart';

class ProfileController extends GetxController {
  static const termsOfUseUrl =
      'https://gondalsoft.com/allconvert/terms-of-use';
  static const privacyPolicyUrl =
      'https://gondalsoft.com/allconvert/privacy-policy';

  final versionLabel = ''.obs;
  final isBusy = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = info.buildNumber.trim();
      versionLabel.value = build.isEmpty
          ? info.version
          : '${info.version} ($build)';
    } catch (_) {
      versionLabel.value = '—';
    }
  }

  Future<void> openTermsOfUse() => _openUrl(termsOfUseUrl);

  Future<void> openPrivacyPolicy() => _openUrl(privacyPolicyUrl);

  Future<void> rateUs() async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
    } catch (_) {
      Get.snackbar(
        LocaleKeys.rateUs.tr,
        LocaleKeys.openLinkFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> _openUrl(String url) async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      final uri = Uri.parse(url);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        Get.snackbar(
          LocaleKeys.profileTitle.tr,
          LocaleKeys.openLinkFailed.tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
      }
    } catch (_) {
      Get.snackbar(
        LocaleKeys.profileTitle.tr,
        LocaleKeys.openLinkFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isBusy.value = false;
    }
  }
}
