import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../logic/date_utils.dart';
import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final nt = nutritionTarget(d);
    return PageBody(children: [
      const PageHeader(title: 'Cài đặt'),
      // Key theo đối tượng dữ liệu để form nạp lại sau khi nhập/khôi phục
      _ProfileForm(key: ObjectKey(d.profile)),
      _GoalsForm(key: ObjectKey(d.goals)),
      SectionCard(
        title: 'Giao diện',
        icon: Icons.palette_outlined,
        child: Wrap(children: [SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'system', label: Text('Theo máy'), icon: Icon(Icons.brightness_auto)),
            ButtonSegment(value: 'light', label: Text('Sáng'), icon: Icon(Icons.light_mode)),
            ButtonSegment(value: 'dark', label: Text('Tối'), icon: Icon(Icons.dark_mode)),
          ],
          selected: {d.settings.theme},
          onSelectionChanged: (s) => st.update((dd) => dd.settings.theme = s.first),
        )]),
      ),
      SectionCard(
        title: 'Ước tính dinh dưỡng hiện tại',
        icon: Icons.calculate_outlined,
        child: Text(
          'Năng lượng: ${nt.kcal == null ? 'chưa đủ thông tin' : '~${nt.kcal} kcal/ngày'}\n'
          'Protein: ${nt.proteinG == null ? 'chưa đủ thông tin' : '~${nt.proteinG} g/ngày'}\n'
          '${nt.method}. Đây chỉ là ước tính — điều chỉnh theo cảm giác đói/no và mức vận động.',
          style: const TextStyle(height: 1.5),
        ),
      ),
      const _DataSection(),
      SectionCard(
        title: 'Lưu ý sức khỏe',
        icon: Icons.health_and_safety_outlined,
        child: const Text(
          'Ứng dụng chỉ hỗ trợ theo dõi thói quen và thông tin bạn đã xác nhận, không thay thế bác sĩ. '
          'App không chẩn đoán từ ảnh, không tự đưa ra hoặc thay đổi phác đồ thuốc, không khẳng định thực phẩm hay '
          'thực phẩm chức năng chữa được mụn hoặc rụng tóc. Hãy liên hệ bác sĩ khi có kích ứng nặng, phản ứng bất thường '
          'hoặc tình trạng da/tóc xấu đi rõ rệt.',
          style: TextStyle(height: 1.45),
        ),
      ),
      Center(child: Text('Glow-up Tracker 1.0 · Dữ liệu chỉ lưu trên máy này', style: mutedStyle(context))),
    ]);
  }
}

// ============================================================================

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({super.key});
  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final UserProfile p = AppScope.read(context).data.profile;
  late final name = TextEditingController(text: p.name);
  late final age = TextEditingController(text: p.age?.toString() ?? '');
  late final height = TextEditingController(text: p.heightCm == null ? '' : fmtNum(p.heightCm));
  late final weight = TextEditingController(text: p.weightKg == null ? '' : fmtNum(p.weightKg));
  late final food = TextEditingController(text: p.foodRestrictions);
  late final skin = TextEditingController(text: p.skinRoutineNote);
  late final hair = TextEditingController(text: p.hairRoutineNote);
  late String sex = p.sex;
  late String activity = p.activityLevel;
  late String nutGoal = p.nutritionGoal;
  String? err;

  @override
  void dispose() {
    for (final c in [name, age, height, weight, food, skin, hair]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    int? a;
    double? h, w;
    try {
      a = parseOptionalInt(age.text, min: 10, max: 100);
      h = parseOptionalDouble(height.text, min: 100, max: 230);
      w = parseOptionalDouble(weight.text, min: 30, max: 250);
    } on FormatException {
      setState(() => err = 'Kiểm tra lại: tuổi 10–100, chiều cao 100–230 cm, cân nặng 30–250 kg.');
      return;
    }
    setState(() => err = null);
    AppScope.read(context).update((d) {
      d.profile
        ..name = name.text.trim()
        ..age = a
        ..heightCm = h
        ..weightKg = w
        ..sex = sex
        ..activityLevel = activity
        ..nutritionGoal = nutGoal
        ..foodRestrictions = food.text.trim()
        ..skinRoutineNote = skin.text.trim()
        ..hairRoutineNote = hair.text.trim();
    });
    showSnack(context, 'Đã lưu hồ sơ');
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Hồ sơ',
      icon: Icons.person_outline,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên gọi (tùy chọn)')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tuổi'))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: height,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Chiều cao (cm)'))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: weight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Cân nặng (kg)'))),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: sex,
          decoration: const InputDecoration(labelText: 'Giới tính (dùng cho ước tính năng lượng)'),
          items: const [
            DropdownMenuItem(value: 'unspecified', child: Text('Không chọn')),
            DropdownMenuItem(value: 'male', child: Text('Nam')),
            DropdownMenuItem(value: 'female', child: Text('Nữ')),
          ],
          onChanged: (v) => setState(() => sex = v ?? sex),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: activity,
          decoration: const InputDecoration(labelText: 'Mức vận động'),
          items: const [
            DropdownMenuItem(value: 'sedentary', child: Text('Ít vận động (ngồi nhiều)')),
            DropdownMenuItem(value: 'light', child: Text('Nhẹ (1–3 buổi/tuần)')),
            DropdownMenuItem(value: 'moderate', child: Text('Vừa (3–5 buổi/tuần)')),
            DropdownMenuItem(value: 'active', child: Text('Nhiều (6–7 buổi/tuần)')),
          ],
          onChanged: (v) => setState(() => activity = v ?? activity),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: nutGoal,
          decoration: const InputDecoration(labelText: 'Mục tiêu năng lượng'),
          items: const [
            DropdownMenuItem(value: 'maintain', child: Text('Giữ cân')),
            DropdownMenuItem(value: 'gain', child: Text('Tăng cân/tăng cơ nhẹ')),
            DropdownMenuItem(value: 'lose', child: Text('Giảm cân nhẹ')),
          ],
          onChanged: (v) => setState(() => nutGoal = v ?? nutGoal),
        ),
        const SizedBox(height: 12),
        TextField(controller: food, decoration: const InputDecoration(labelText: 'Thực phẩm không thích / dị ứng / hạn chế')),
        const SizedBox(height: 12),
        TextField(controller: skin, maxLines: 2, decoration: const InputDecoration(labelText: 'Routine da hiện tại (tự ghi)')),
        const SizedBox(height: 12),
        TextField(controller: hair, maxLines: 2, decoration: const InputDecoration(labelText: 'Phác đồ tóc hiện tại đã được xác nhận (tự ghi)')),
        if (err != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _save, child: const Text('Lưu hồ sơ'))),
      ]),
    );
  }
}

// ============================================================================

class _GoalsForm extends StatefulWidget {
  const _GoalsForm({super.key});
  @override
  State<_GoalsForm> createState() => _GoalsFormState();
}

class _GoalsFormState extends State<_GoalsForm> {
  late final Goals g = AppScope.read(context).data.goals;
  late String bed = g.bedTime, sleep = g.sleepTime, wake = g.wakeTime;
  late final hours = TextEditingController(text: fmtNum(g.sleepHours));
  late final water = TextEditingController(text: '${g.waterGlasses}');
  late final kcal = TextEditingController(text: g.kcalOverride?.toString() ?? '');
  late final protein = TextEditingController(text: g.proteinOverride?.toString() ?? '');
  late final budget = TextEditingController(text: '${g.monthlyBudget}');
  late final warn = TextEditingController(text: '${g.budgetWarnPercent}');
  String? err;

  @override
  void dispose() {
    for (final c in [hours, water, kcal, protein, budget, warn]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    double? h;
    int? w, k, p, wp;
    int? b;
    try {
      h = parseOptionalDouble(hours.text, min: 4, max: 12);
      w = parseOptionalInt(water.text, min: 1, max: 30);
      k = parseOptionalInt(kcal.text, min: 1000, max: 5000);
      p = parseOptionalInt(protein.text, min: 20, max: 300);
      wp = parseOptionalInt(warn.text, min: 50, max: 100);
    } on FormatException {
      setState(() => err = 'Kiểm tra: giờ ngủ 4–12, nước 1–30 cốc, kcal 1000–5000, protein 20–300 g, cảnh báo 50–100%.');
      return;
    }
    b = parseMoney(budget.text);
    if (h == null || w == null || b == null || b <= 0 || wp == null) {
      setState(() => err = 'Giờ ngủ, số cốc nước, ngân sách và % cảnh báo là bắt buộc.');
      return;
    }
    setState(() => err = null);
    AppScope.read(context).update((d) {
      d.goals
        ..bedTime = bed
        ..sleepTime = sleep
        ..wakeTime = wake
        ..sleepHours = h!
        ..waterGlasses = w!
        ..kcalOverride = k
        ..proteinOverride = p
        ..monthlyBudget = b!
        ..budgetWarnPercent = wp!;
      // Cập nhật tiêu đề nhiệm vụ ngủ theo mục tiêu mới
      for (final x in d.habits) {
        if (x.id == 'hb_winddown') {
          x.title = 'Chuẩn bị đi ngủ lúc $bed';
          x.time = bed;
        }
        if (x.id == 'hb_sleep') {
          x.title = 'Ngủ trước $sleep';
          x.time = sleep;
        }
        if (x.id == 'hb_wake') x.time = wake;
      }
    });
    showSnack(context, 'Đã lưu mục tiêu');
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Mục tiêu',
      icon: Icons.flag_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: TimeButton(label: 'Lên giường', value: bed, onChanged: (v) => setState(() => bed = v))),
          const SizedBox(width: 8),
          Expanded(child: TimeButton(label: 'Ngủ', value: sleep, onChanged: (v) => setState(() => sleep = v))),
          const SizedBox(width: 8),
          Expanded(child: TimeButton(label: 'Thức dậy', value: wake, onChanged: (v) => setState(() => wake = v))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: hours,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Số giờ ngủ mục tiêu'))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(controller: water, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cốc nước/ngày'))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: kcal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'kcal/ngày (trống = tự ước tính)'))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: protein,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Protein g (trống = tự ước tính)'))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: budget,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ngân sách tháng (₫)'))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(controller: warn, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cảnh báo khi đạt (%)'))),
        ]),
        if (err != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _save, child: const Text('Lưu mục tiêu'))),
      ]),
    );
  }
}

// ============================================================================
// Dữ liệu: xuất / nhập / sao lưu / xóa
// ============================================================================

class _DataSection extends StatefulWidget {
  const _DataSection();
  @override
  State<_DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends State<_DataSection> {
  String? lastBackup;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final v = await AppScope.read(context).storage.lastInternalBackupAt();
      if (mounted) setState(() => lastBackup = v);
    });
  }

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _export(bool withPhotos) async {
    final st = AppScope.read(context);
    setState(() => busy = true);
    try {
      await st.flush();
      final payload = await st.storage.buildExport(st.data, includePhotos: withPhotos);
      final text = const JsonEncoder.withIndent('  ').convert(payload);
      final name = 'glowup-backup-${todayStr()}${withPhotos ? '-kem-anh' : ''}.json';
      if (_isMobile) {
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}${Platform.pathSeparator}$name');
        await f.writeAsString(text, flush: true);
        await Share.shareXFiles([XFile(f.path, mimeType: 'application/json')], subject: 'Sao lưu Glow-up');
      } else {
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Lưu file sao lưu',
          fileName: name,
          type: FileType.custom,
          allowedExtensions: const ['json'],
        );
        if (path == null) return;
        await File(path).writeAsString(text, flush: true);
        if (mounted) showSnack(context, 'Đã lưu: $path');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Xuất dữ liệu thất bại: $e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _import() async {
    final st = AppScope.read(context);
    try {
      final res = await FilePicker.platform.pickFiles(
        dialogTitle: 'Chọn file sao lưu (.json)',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (res == null || res.files.isEmpty) return;
      final f = res.files.first;
      String text;
      if (f.bytes != null) {
        text = utf8.decode(f.bytes!);
      } else if (f.path != null) {
        text = await File(f.path!).readAsString();
      } else {
        throw ImportException('Không đọc được file.');
      }
      final parsed = st.storage.parseImport(text);
      if (!mounted) return;
      final s = parsed.data;
      final ok = await confirmDialog(
        context,
        title: 'Nhập dữ liệu?',
        message: 'File chứa ${s.sleepLogs.length} đêm ngủ, ${s.workoutSessions.length} buổi tập, ${s.mealLogs.length} bữa ăn, '
            '${s.skinLogs.length} nhật ký da, ${s.hairLogs.length} nhật ký tóc, ${s.expenses.length} khoản chi'
            '${parsed.photos.isNotEmpty ? ', ${parsed.photos.length} ảnh' : ''}.\n\n'
            'Toàn bộ dữ liệu hiện tại sẽ được THAY THẾ. Nên xuất bản sao lưu trước nếu cần.',
        confirmText: 'Thay thế',
        danger: true,
      );
      if (!ok) return;
      setState(() => busy = true);
      final n = await st.storage.restorePhotos(parsed.photos);
      st.replaceAll(s);
      if (mounted) showSnack(context, 'Đã nhập dữ liệu${n > 0 ? ' và $n ảnh' : ''}.');
    } on ImportException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (e) {
      if (mounted) showSnack(context, 'Nhập dữ liệu thất bại: $e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _backupInternal() async {
    final st = AppScope.read(context);
    final ok = await st.storage.makeInternalBackup(st.data);
    final v = await st.storage.lastInternalBackupAt();
    if (!mounted) return;
    setState(() => lastBackup = v);
    showSnack(context, ok ? 'Đã tạo bản sao lưu trong máy' : 'Không tạo được bản sao lưu', error: !ok);
  }

  Future<void> _restoreInternal() async {
    final st = AppScope.read(context);
    final ok = await confirmDialog(context,
        title: 'Khôi phục bản sao lưu?',
        message: 'Dữ liệu hiện tại sẽ được thay bằng bản sao lưu lúc ${_fmtIso(lastBackup)}. Ảnh không bị ảnh hưởng.',
        confirmText: 'Khôi phục',
        danger: true);
    if (!ok) return;
    try {
      final d = await st.storage.restoreInternalBackup();
      if (d == null) throw ImportException('Không có bản sao lưu.');
      st.replaceAll(d);
      if (mounted) showSnack(context, 'Đã khôi phục');
    } catch (e) {
      if (mounted) showSnack(context, 'Khôi phục thất bại: $e', error: true);
    }
  }

  Future<void> _deleteAll() async {
    final st = AppScope.read(context);
    final ok = await confirmDialog(context,
        title: 'Xóa toàn bộ dữ liệu cá nhân?',
        message: 'Mọi nhật ký, ảnh, thuốc, chi tiêu và cài đặt sẽ bị xóa vĩnh viễn khỏi máy này. Không thể hoàn tác.',
        confirmText: 'Tiếp tục',
        danger: true);
    if (!ok || !mounted) return;
    final typed = await promptText(context, title: 'Gõ XOA để xác nhận', hint: 'XOA');
    if (typed?.toUpperCase() != 'XOA') {
      if (mounted) showSnack(context, 'Đã hủy — dữ liệu không bị xóa.');
      return;
    }
    await st.resetAll();
  }

  String _fmtIso(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    return '${fmtDate(toLocalDate(dt))} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return SectionCard(
      title: 'Dữ liệu',
      icon: Icons.storage_outlined,
      subtitle: 'Lưu cục bộ trên máy, không gửi lên máy chủ nào',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (busy) const LinearProgressIndicator(),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(onPressed: busy ? null : () => _export(false), icon: const Icon(Icons.upload_file), label: const Text('Xuất JSON')),
          if (st.storage.photosSupported)
            OutlinedButton.icon(
                onPressed: busy ? null : () => _export(true), icon: const Icon(Icons.photo_library_outlined), label: const Text('Xuất JSON kèm ảnh')),
          OutlinedButton.icon(onPressed: busy ? null : _import, icon: const Icon(Icons.download), label: const Text('Nhập từ JSON')),
        ]),
        const SizedBox(height: 8),
        Text('File kèm ảnh có thể khá lớn. Hãy cất file sao lưu ở nơi riêng tư vì nó chứa thông tin sức khỏe.', style: mutedStyle(context)),
        const Divider(height: 24),
        Text('Sao lưu nhanh trong máy: ${_fmtIso(lastBackup)}'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonalIcon(onPressed: _backupInternal, icon: const Icon(Icons.backup_outlined), label: const Text('Tạo bản sao lưu')),
          OutlinedButton.icon(
              onPressed: lastBackup == null ? null : _restoreInternal, icon: const Icon(Icons.restore), label: const Text('Khôi phục')),
        ]),
        const Divider(height: 24),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await confirmDialog(context,
                  title: 'Thiết lập lại từ đầu?', message: 'Mở lại phần thiết lập ban đầu. Dữ liệu đã ghi vẫn được giữ.');
              if (ok) st.update((d) => d.profile.onboardedAt = null);
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Chạy lại thiết lập ban đầu'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError),
            onPressed: _deleteAll,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Xóa toàn bộ dữ liệu'),
          ),
        ]),
      ]),
    );
  }
}
