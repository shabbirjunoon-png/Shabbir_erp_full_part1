// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

String registerPdfIframe(String base64Data) {
  final dataUri = 'data:application/pdf;base64,$base64Data';
  final viewId = 'pdf-iframe-${DateTime.now().millisecondsSinceEpoch}';

  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewId, (int id) {
    final iframe = html.IFrameElement()
      ..src = dataUri
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('allowfullscreen', 'true');
    return iframe;
  });

  return viewId;
}

void unregisterPdfIframe(String id) {}

Widget buildPdfIframeWidget(String id) {
  return HtmlElementView(viewType: id);
}
