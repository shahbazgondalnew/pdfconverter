import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Hosts a hidden WebView that runs pdf.js + docx (JS) to convert PDF → Word.
class PdfToWordWebConverter {
  PdfToWordWebConverter._();

  static Future<({Uint8List bytes, int pageCount})> convert({
    required List<Uint8List> pdfFiles,
    void Function(int done, int total)? onProgress,
  }) async {
    if (pdfFiles.isEmpty) {
      throw StateError('No PDF files to convert');
    }

    final completer = Completer<({Uint8List bytes, int pageCount})>();

    // Use a transparent GetX dialog — it always has a valid Overlay ancestor
    // (unlike Overlay.of(Get.overlayContext) on some GetPage routes).
    // ignore: unawaited_futures
    Get.dialog(
      PopScope(
        canPop: false,
        child: Material(
          type: MaterialType.transparency,
          child: Transform.translate(
            offset: const Offset(-10000, -10000),
            child: SizedBox(
              width: 360,
              height: 520,
              child: _PdfToWordWebHost(
                pdfFiles: pdfFiles,
                onProgress: onProgress,
                onDone: (bytes, pages) {
                  if (Get.isDialogOpen ?? false) {
                    Get.back();
                  }
                  if (!completer.isCompleted) {
                    completer.complete((bytes: bytes, pageCount: pages));
                  }
                },
                onError: (message) {
                  if (Get.isDialogOpen ?? false) {
                    Get.back();
                  }
                  if (!completer.isCompleted) {
                    completer.completeError(StateError(message));
                  }
                },
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useSafeArea: false,
    );

    try {
      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw TimeoutException('PDF to Word conversion timed out');
        },
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      rethrow;
    }
  }
}

class _PdfToWordWebHost extends StatefulWidget {
  const _PdfToWordWebHost({
    required this.pdfFiles,
    required this.onDone,
    required this.onError,
    this.onProgress,
  });

  final List<Uint8List> pdfFiles;
  final void Function(int done, int total)? onProgress;
  final void Function(Uint8List bytes, int pageCount) onDone;
  final void Function(String message) onError;

  @override
  State<_PdfToWordWebHost> createState() => _PdfToWordWebHostState();
}

class _PdfToWordWebHostState extends State<_PdfToWordWebHost> {
  late final WebViewController _controller;
  var _started = false;
  var _finished = false;

  @override
  void initState() {
    super.initState();

    final controller = WebViewController();
    _controller = controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'ConverterChannel',
        onMessageReceived: _onMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) {
              _fail('WebView error: ${error.description}');
            } else {
              debugPrint('PDF→Word resource error: ${error.description}');
            }
          },
          onPageFinished: (url) {
            debugPrint('PDF→Word page finished: $url');
          },
        ),
      );

    _configureAndroid(controller);
    controller.loadFlutterAsset('assets/pdf_to_word/converter.html');
  }

  Future<void> _configureAndroid(WebViewController controller) async {
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      await platform.setMediaPlaybackRequiresUserGesture(false);
      AndroidWebViewController.enableDebugging(kDebugMode);
    }
  }

  void _fail(String message) {
    if (_finished) return;
    _finished = true;
    widget.onError(message);
  }

  Future<void> _onMessage(JavaScriptMessage message) async {
    try {
      final payload = jsonDecode(message.message) as Map<String, dynamic>;
      final type = payload['type'] as String?;

      switch (type) {
        case 'ready':
          if (_started || _finished) return;
          _started = true;
          await _kickOff();
        case 'progress':
          final done = payload['done'] as int? ?? 0;
          final total = payload['total'] as int? ?? 1;
          widget.onProgress?.call(done, total);
        case 'done':
          if (_finished) return;
          final data = payload['data'] as String? ?? '';
          final pages = payload['pages'] as int? ?? 0;
          if (data.isEmpty) {
            _fail('Empty Word output');
            return;
          }
          _finished = true;
          widget.onDone(base64Decode(data), pages);
        case 'error':
          _fail(payload['message'] as String? ?? 'Conversion failed');
      }
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<void> _kickOff() async {
    try {
      final encoded = widget.pdfFiles.map(base64Encode).toList(growable: false);
      final jsList = jsonEncode(encoded);
      // IMPORTANT (iOS WKWebView): never let evaluateJavaScript receive a Promise
      // ("The object can not be cloned"). Call async work and return a primitive.
      await _controller.runJavaScript(
        'window.startConversion($jsList); 0;',
      );
    } catch (e) {
      _fail('Failed to start converter: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: WebViewWidget(controller: _controller),
    );
  }
}
