import 'dart:io';
import 'package:file_picker/file_picker.dart';

Future<String?> nativePickAndReadFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return null;
  final path = result.files.single.path;
  if (path == null) return null;
  return await File(path).readAsString();
}

Future<List<String>?> nativePickMultipleFiles() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    allowMultiple: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final contents = <String>[];
  for (final f in result.files) {
    final path = f.path;
    if (path == null) continue;
    try {
      contents.add(await File(path).readAsString());
    } catch (_) {}
  }
  return contents.isEmpty ? null : contents;
}
