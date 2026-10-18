import 'dart:async';

import 'package:flutter/material.dart';

import '../data/defaults.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

/// Trạng thái toàn ứng dụng. Mọi thay đổi đi qua [update] và được lưu bền vững ngay sau đó.
class AppState extends ChangeNotifier {
  final StorageService storage;
  AppData data;
  String? loadError;
  bool _saveFailedNotified = false;
  Timer? _debounce;
  final ValueNotifier<String?> messages = ValueNotifier<String?>(null);

  AppState._(this.storage, this.data, this.loadError);

  static Future<AppState> create() async {
    final storage = StorageService();
    await storage.init();
    AppData? data;
    String? err;
    try {
      data = storage.load();
    } catch (_) {
      err = 'Không đọc được dữ liệu đã lưu (có thể bị hỏng). Bản cũ đã được giữ lại; app đang dùng dữ liệu mặc định.';
      await storage.preserveCorrupted();
    }
    return AppState._(storage, data ?? createInitialData(), err);
  }

  bool get needsOnboarding => data.profile.onboardedAt == null;

  ThemeMode get themeMode => switch (data.settings.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  /// Sửa dữ liệu trực tiếp rồi thông báo + lưu.
  void update(void Function(AppData d) fn) {
    fn(data);
    notifyListeners();
    _scheduleSave();
  }

  void replaceAll(AppData d) {
    data = d;
    notifyListeners();
    _scheduleSave(immediate: true);
  }

  Future<void> resetAll() async {
    await storage.clearAll();
    data = createInitialData();
    notifyListeners();
  }

  void _scheduleSave({bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      _save();
    } else {
      _debounce = Timer(const Duration(milliseconds: 250), _save);
    }
  }

  Future<void> _save() async {
    final ok = await storage.save(data);
    if (!ok && !_saveFailedNotified) {
      _saveFailedNotified = true;
      messages.value = 'Không lưu được dữ liệu vào bộ nhớ máy.';
    } else if (ok) {
      _saveFailedNotified = false;
    }
  }

  /// Gọi khi app chuyển nền để chắc chắn dữ liệu đã được ghi.
  Future<void> flush() async {
    _debounce?.cancel();
    await _save();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    messages.dispose();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Lấy state và đăng ký rebuild khi dữ liệu đổi.
  static AppState of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(w != null, 'AppScope not found');
    return w!.notifier!;
  }

  /// Lấy state nhưng không đăng ký rebuild (dùng trong callback).
  static AppState read(BuildContext context) {
    final w = context.getInheritedWidgetOfExactType<AppScope>();
    return w!.notifier!;
  }
}
