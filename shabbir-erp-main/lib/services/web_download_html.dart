// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void triggerWebDownload(List<int> bytes, String filename) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<List<String>?> webPickMultipleBackupFiles() async {
  final completer = html.InputElement(type: 'file');
  completer.accept = '.json,application/json';
  completer.multiple = true;
  completer.click();

  await completer.onChange.first;
  final files = completer.files;
  if (files == null || files.isEmpty) return null;

  final results = <String>[];
  for (var i = 0; i < files.length; i++) {
    final file = files[i];
    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoad.first;
    final content = reader.result as String?;
    if (content != null && content.isNotEmpty) results.add(content);
  }
  return results.isEmpty ? null : results;
}
