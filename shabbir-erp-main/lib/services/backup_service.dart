import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_html.dart';
import 'native_backup_stub.dart'
    if (dart.library.io) 'native_backup_impl.dart';
import 'native_restore_stub.dart'
    if (dart.library.io) 'native_restore_impl.dart';

class RestoreMode {
  static const replace = 'replace';
  static const merge = 'merge';
}

class BackupService {
  static BackupService? _instance;
  BackupService._();
  static BackupService get instance {
    _instance ??= BackupService._();
    return _instance!;
  }

  static const _lastBackupKey = 'backup:last_backup_epoch';
  static const _lastChangeKey = 'backup:last_change_epoch';

  String _buildFilename() {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final y = now.year.toString();
    return 'shabbir_erp_backup_$y-$m-$d.json';
  }

  Future<void> recordDataChange() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastChangeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> isBackupNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastChange = prefs.getInt(_lastChangeKey) ?? 0;
    final lastBackup = prefs.getInt(_lastBackupKey) ?? 0;
    if (lastChange == 0) return false;
    if (lastBackup == 0) return true;
    final daysSinceBackup =
        (DateTime.now().millisecondsSinceEpoch - lastBackup) / (1000 * 60 * 60 * 24);
    return daysSinceBackup >= 3 && lastChange > lastBackup;
  }

  Future<DateTime?> lastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final epoch = prefs.getInt(_lastBackupKey) ?? 0;
    if (epoch == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(epoch);
  }

  Future<void> _markBackupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> backupToLocalStorage() async {
    final json = await DatabaseService.instance.exportToJson();
    final bytes = utf8.encode(json);
    final filename = _buildFilename();
    if (kIsWeb) {
      triggerWebDownload(bytes, filename);
    } else {
      await nativeBackup(bytes, filename);
    }
    await _markBackupDone();
  }

  Future<void> autoBackupNative() async {
    if (kIsWeb) return;
    final needed = await isBackupNeeded();
    if (!needed) return;
    try {
      final json = await DatabaseService.instance.exportToJson();
      final bytes = utf8.encode(json);
      final filename = _buildFilename();
      await nativeSilentBackup(bytes, filename);
      await _markBackupDone();
    } catch (_) {}
  }

  Future<List<String>?> _pickFiles() async {
    if (kIsWeb) {
      return await webPickMultipleBackupFiles();
    } else {
      return await nativePickMultipleFiles();
    }
  }

  Future<bool> restoreFromFiles({required String mode}) async {
    final files = await _pickFiles();
    if (files == null || files.isEmpty) return false;
    for (final json in files) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      if (mode == RestoreMode.merge) {
        await DatabaseService.instance.mergeData(data);
      } else {
        await DatabaseService.instance.importData(data);
      }
    }
    await recordDataChange();
    return true;
  }

  Future<bool> restoreFromLocalFile() async {
    return restoreFromFiles(mode: RestoreMode.replace);
  }

  Future<void> restoreFromJson(String json, {String mode = RestoreMode.replace}) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    if (mode == RestoreMode.merge) {
      await DatabaseService.instance.mergeData(data);
    } else {
      await DatabaseService.instance.importData(data);
    }
    await recordDataChange();
  }
}
