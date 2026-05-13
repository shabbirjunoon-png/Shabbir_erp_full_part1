import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> nativeBackup(List<int> bytes, String filename) async {
  Directory? saveDir;
  try { saveDir = await getExternalStorageDirectory(); } catch (_) { saveDir = await getTemporaryDirectory(); }
  saveDir ??= await getTemporaryDirectory();
  final file = File('${saveDir.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/json')],
    subject: 'Shabbir ERP Backup',
    text: 'Backup: $filename',
  );
}

Future<void> nativeSilentBackup(List<int> bytes, String filename) async {
  Directory? saveDir;
  try { saveDir = await getExternalStorageDirectory(); } catch (_) { saveDir = await getTemporaryDirectory(); }
  saveDir ??= await getTemporaryDirectory();
  final file = File('${saveDir.path}/$filename');
  await file.writeAsBytes(bytes);
}
