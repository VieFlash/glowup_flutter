import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/defaults.dart';
import '../models/models.dart';

class ImportException implements Exception {
  final String message;
  ImportException(this.message);
  @override
  String toString() => message;
}

/// Lưu trữ cục bộ:
/// - Dữ liệu có cấu trúc: JSON trong SharedPreferences.
/// - Ảnh: file trong thư mục tài liệu riêng của ứng dụng (không lưu ảnh dạng chuỗi trong JSON).
/// Không có bất kỳ dữ liệu nào được gửi lên máy chủ.
class StorageService {
  static const storageKey = 'glowup.v1';
  static const backupKey = 'glowup.v1.backup';

  SharedPreferences? _prefs;
  Directory? _photoDir;

  bool get photosSupported => !kIsWeb;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (!kIsWeb) {
      try {
        final docs = await getApplicationDocumentsDirectory();
        final dir = Directory('${docs.path}${Platform.pathSeparator}glowup_photos');
        if (!await dir.exists()) await dir.create(recursive: true);
        _photoDir = dir;
      } catch (_) {
        _photoDir = null;
      }
    }
  }

  /// Trả về dữ liệu đã lưu, hoặc null nếu chưa có. Ném lỗi nếu dữ liệu hỏng.
  AppData? load() {
    final s = _prefs?.getString(storageKey);
    if (s == null || s.isEmpty) return null;
    final decoded = jsonDecode(s);
    if (decoded is! Map) throw const FormatException('Dữ liệu không hợp lệ');
    return appDataFromJson(Map<String, dynamic>.from(decoded));
  }

  /// Giữ lại bản dữ liệu hỏng để không mất khi app ghi dữ liệu mới.
  Future<void> preserveCorrupted() async {
    final s = _prefs?.getString(storageKey);
    if (s != null) await _prefs?.setString('$storageKey.corrupted', s);
  }

  Future<bool> save(AppData data) async {
    try {
      return await _prefs?.setString(storageKey, jsonEncode(data.toJson())) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ---------- Sao lưu nội bộ nhanh (trong máy) ----------
  Future<String?> lastInternalBackupAt() async {
    final s = _prefs?.getString(backupKey);
    if (s == null) return null;
    try {
      final j = jsonDecode(s);
      return j is Map ? j['exportedAt']?.toString() : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> makeInternalBackup(AppData data) async {
    final payload = await buildExport(data, includePhotos: false);
    return await _prefs?.setString(backupKey, jsonEncode(payload)) ?? false;
  }

  Future<AppData?> restoreInternalBackup() async {
    final s = _prefs?.getString(backupKey);
    if (s == null) return null;
    return parseImport(s).data;
  }

  Future<void> clearAll() async {
    await _prefs?.remove(storageKey);
    await _prefs?.remove(backupKey);
    await _prefs?.remove('$storageKey.corrupted');
    final dir = _photoDir;
    if (dir != null && await dir.exists()) {
      for (final f in dir.listSync()) {
        try {
          await f.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  // ---------- Ảnh ----------
  File? photoFile(String fileName) {
    final dir = _photoDir;
    if (dir == null || fileName.isEmpty) return null;
    return File('${dir.path}${Platform.pathSeparator}$fileName');
  }

  Future<String> savePhotoBytes(Uint8List bytes, String fileName) async {
    final f = photoFile(fileName);
    if (f == null) throw Exception('Thiết bị này không hỗ trợ lưu ảnh');
    await f.writeAsBytes(bytes, flush: true);
    return fileName;
  }

  Future<void> deletePhoto(String fileName) async {
    final f = photoFile(fileName);
    if (f != null && await f.exists()) await f.delete();
  }

  // ---------- Xuất / nhập ----------
  Future<Map<String, dynamic>> buildExport(AppData data, {required bool includePhotos}) async {
    final out = <String, dynamic>{
      'app': 'glowup-tracker',
      'exportedAt': DateTime.now().toIso8601String(),
      'state': data.toJson(),
    };
    if (includePhotos && photosSupported) {
      final photos = <String, String>{};
      for (final p in data.photos) {
        final f = photoFile(p.fileName);
        if (f != null && await f.exists()) {
          photos[p.fileName] = base64Encode(await f.readAsBytes());
        }
      }
      out['photos'] = photos;
    }
    return out;
  }

  /// Kiểm tra & đọc file sao lưu. Ném [ImportException] với thông báo tiếng Việt nếu sai.
  ({AppData data, Map<String, String> photos}) parseImport(String text) {
    dynamic obj;
    try {
      obj = jsonDecode(text);
    } catch (_) {
      throw ImportException('File không phải JSON hợp lệ.');
    }
    if (obj is! Map) throw ImportException('Nội dung file không hợp lệ.');
    if (obj['app'] != 'glowup-tracker' || obj['state'] is! Map) {
      throw ImportException('File không phải bản sao lưu của ứng dụng này.');
    }
    final st = Map<String, dynamic>.from(obj['state'] as Map);
    if (st['version'] != 1) throw ImportException('Phiên bản dữ liệu không được hỗ trợ.');
    const arrays = [
      'habits',
      'workoutSessions',
      'mealLogs',
      'sleepLogs',
      'skinLogs',
      'hairLogs',
      'medications',
      'photos',
      'expenses',
    ];
    for (final k in arrays) {
      if (st[k] != null && st[k] is! List) throw ImportException('Trường "$k" sai định dạng.');
    }
    AppData data;
    try {
      data = appDataFromJson(st);
    } catch (e) {
      throw ImportException('Không đọc được dữ liệu: $e');
    }
    final photos = <String, String>{};
    final ph = obj['photos'];
    if (ph is Map) {
      ph.forEach((k, v) {
        if (v is String) photos[k.toString()] = v;
      });
    }
    return (data: data, photos: photos);
  }

  Future<int> restorePhotos(Map<String, String> photos) async {
    if (!photosSupported) return 0;
    var n = 0;
    for (final e in photos.entries) {
      try {
        await savePhotoBytes(base64Decode(e.value), e.key);
        n++;
      } catch (_) {}
    }
    return n;
  }
}
