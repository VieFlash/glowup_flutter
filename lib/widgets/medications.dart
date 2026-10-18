import 'package:flutter/material.dart';

import '../data/defaults.dart';
import '../logic/date_utils.dart';
import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'common.dart';

const _areaLabel = {'skin': 'Da', 'hair': 'Tóc', 'other': 'Khác'};

/// Cảnh báo an toàn theo tên (không đưa ra phác đồ, chỉ nhắc xác minh).
List<String> medWarnings(AppData d, MedicationPlan m) {
  final n = m.name.toLowerCase();
  final out = <String>[];
  bool active(String key) => d.medications.any((x) => x.id != m.id && x.active && x.name.toLowerCase().contains(key));
  if (n.contains('finasteride') && !n.contains('morr')) {
    out.add('Lịch finasteride trong đơn cũ có vẻ không phải lịch thông thường — hãy xác nhận lịch hiện hành với bác sĩ/dược sĩ. App không tự đổi sang dùng hằng ngày.');
    if (active('morr')) out.add('Bạn cũng có Morr F5 trong danh sách. Kiểm tra bao bì xem có finasteride không và hỏi bác sĩ trước khi dùng đồng thời.');
  }
  if (n.contains('morr')) {
    out.add('Kiểm tra thành phần chính xác của Morr F5 trên bao bì.');
    if (active('finasteride')) out.add('Nếu Morr F5 có chứa finasteride, hỏi bác sĩ trước khi dùng cùng finasteride uống.');
  }
  if (n.contains('minoxidil')) out.add('Không tự tăng liều hoặc thay đổi tần suất minoxidil.');
  if (n.contains('adapalene') || n.contains('dipalen')) {
    out.add('Adapalene có thể gây khô, đỏ, bong tróc giai đoạn đầu. Nếu kích ứng nặng hoặc bất thường, liên hệ bác sĩ.');
  }
  if (n.contains('canova')) out.add('App không suy đoán thành phần/cách dùng CANOVA RIVESCAL DS — làm theo nhãn và chỉ định của bác sĩ.');
  return out;
}

class MedicationManager extends StatelessWidget {
  final String area;
  const MedicationManager({super.key, required this.area});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final meds = d.medications.where((m) => m.area == area).toList();
    final prior = priorPrescriptions.where((p) => p.area == area).toList();
    final t = todayStr();
    final adh = medAdherence(d, shiftDate(t, -29), t, area);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(
        title: 'Thuốc / sản phẩm điều trị',
        icon: Icons.medication_outlined,
        subtitle: 'Chỉ mục đã xác nhận mới xuất hiện trong nhắc nhở hằng ngày',
        trailing: IconButton.filledTonal(
          tooltip: 'Thêm',
          onPressed: () => showMedicationEditor(context, null, area),
          icon: const Icon(Icons.add),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (adh.due > 0)
            LabeledBar(label: 'Tuân thủ 30 ngày qua', valueText: '${adh.taken}/${adh.due} · ${fmtPct(adh.rate)}', value: adh.rate),
          if (meds.isEmpty)
            const EmptyState(
              icon: Icons.medication_outlined,
              title: 'Chưa có mục nào',
              message: 'Thêm thuốc bạn ĐANG dùng theo hướng dẫn hiện hành của bác sĩ.',
            ),
          for (final m in meds)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.name),
              subtitle: Text([
                if (m.instructions.isNotEmpty) m.instructions else 'Chưa nhập hướng dẫn',
                if (m.timesOfDay.isNotEmpty) 'Giờ: ${m.timesOfDay.join(', ')}',
                m.weekdays.isEmpty ? 'Mỗi ngày' : m.weekdays.map((w) => weekdayShort[w]).join(', '),
              ].join(' · ')),
              trailing: !m.active
                  ? Tag('Tạm ngừng', color: Theme.of(context).colorScheme.outline)
                  : m.confirmedCurrent
                      ? const Tag('Đã xác nhận')
                      : Tag('Chưa xác nhận', color: Theme.of(context).colorScheme.error),
              onTap: () => showMedicationEditor(context, m, area),
            ),
        ]),
      ),
      if (prior.isNotEmpty)
        SectionCard(
          title: 'Thông tin từ đơn cũ (chỉ tham khảo)',
          icon: Icons.history_edu,
          subtitle: 'KHÔNG được tự coi là phác đồ hiện tại',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const InfoBanner(
              'Đây là thông tin từ đơn khám trước đây. Nếu bạn đã ngừng lâu hoặc tình trạng đã thay đổi, '
              'đừng tự bắt đầu lại — hãy hỏi bác sĩ. Chỉ thêm vào danh sách khi đã xác nhận cách dùng hiện hành.',
              tone: Tone.warn,
            ),
            for (final p in prior)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(p.caution, style: mutedStyle(context)),
                    ]),
                  ),
                  if (!d.medications.any((m) => m.name == p.name))
                    TextButton(
                      onPressed: () {
                        // Chưa lưu cho đến khi người dùng nhấn "Lưu" trong form.
                        final m = MedicationPlan(id: uid('med'), name: p.name, area: p.area, note: 'Thêm từ thông tin đơn cũ');
                        showMedicationEditor(context, m, area);
                      },
                      child: const Text('Đang dùng?'),
                    ),
                ]),
              ),
          ]),
        ),
    ]);
  }
}

Future<void> showMedicationEditor(BuildContext context, MedicationPlan? med, String defaultArea) async {
  final st = AppScope.read(context);
  final name = TextEditingController(text: med?.name ?? '');
  final instr = TextEditingController(text: med?.instructions ?? '');
  final by = TextEditingController(text: med?.prescribedBy ?? '');
  final note = TextEditingController(text: med?.note ?? '');
  var area = med?.area ?? defaultArea;
  var times = [...?med?.timesOfDay];
  var weekdays = [...?med?.weekdays];
  var active = med?.active ?? true;
  var confirmed = med?.confirmedCurrent ?? false;
  String? err;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final preview = MedicationPlan(id: med?.id ?? '_new', name: name.text);
      final warnings = medWarnings(st.data, preview);
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Text(med == null ? 'Thêm thuốc / sản phẩm' : 'Sửa thuốc / sản phẩm', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Tên (theo nhãn)'),
              onChanged: (_) => setS(() {}),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [for (final e in _areaLabel.entries) ButtonSegment(value: e.key, label: Text(e.value))],
              selected: {area},
              onSelectionChanged: (s) => setS(() => area = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: instr,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Cách dùng theo hướng dẫn HIỆN HÀNH của bác sĩ',
                hintText: 'Ghi đúng như bác sĩ/dược sĩ dặn. App không tự đề xuất liều.',
              ),
            ),
            const SizedBox(height: 12),
            const Text('Giờ nhắc (tùy chọn)'),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final t in times)
                InputChip(label: Text(t), onDeleted: () => setS(() => times.remove(t))),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Thêm giờ'),
                onPressed: () async {
                  final v = await pickTime(ctx, '21:00');
                  if (v != null && !times.contains(v)) setS(() => times = [...times, v]..sort());
                },
              ),
            ]),
            const SizedBox(height: 12),
            const Text('Ngày dùng (để trống = mỗi ngày) — nhập theo đúng chỉ định'),
            const SizedBox(height: 6),
            WeekdayPicker(selected: weekdays, onChanged: (v) => setS(() => weekdays = v)),
            const SizedBox(height: 12),
            TextField(controller: by, decoration: const InputDecoration(labelText: 'Bác sĩ / nơi kê đơn (tùy chọn)')),
            const SizedBox(height: 12),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Ghi chú')),
            for (final w in warnings) Padding(padding: const EdgeInsets.only(top: 8), child: InfoBanner(w, tone: Tone.warn)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: active,
              onChanged: (v) => setS(() => active = v),
              title: const Text('Đang dùng'),
              subtitle: const Text('Tắt nếu đã ngừng theo chỉ định'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: confirmed,
              onChanged: (v) => setS(() => confirmed = v == true),
              title: const Text('Tôi xác nhận đây là cách dùng hiện hành theo hướng dẫn của bác sĩ/dược sĩ'),
            ),
            if (err != null) Text(err!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            const SizedBox(height: 8),
            Row(children: [
              if (med != null)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
                  onPressed: () async {
                    final ok = await confirmDialog(ctx,
                        title: 'Xóa khỏi danh sách?',
                        message: 'Lịch sử ghi nhận của "${med.name}" cũng sẽ bị xóa.',
                        confirmText: 'Xóa',
                        danger: true);
                    if (!ok) return;
                    st.update((dd) {
                      dd.medications.removeWhere((e) => e.id == med.id);
                      dd.medLogs.removeWhere((k, v) => v.medicationId == med.id);
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa'),
                ),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              FilledButton(
                onPressed: () {
                  if (name.text.trim().isEmpty) {
                    setS(() => err = 'Vui lòng nhập tên');
                    return;
                  }
                  if (confirmed && instr.text.trim().isEmpty) {
                    setS(() => err = 'Cần nhập cách dùng hiện hành trước khi xác nhận.');
                    return;
                  }
                  st.update((dd) {
                    MedicationPlan x;
                    final idx = med == null ? -1 : dd.medications.indexWhere((e) => e.id == med.id);
                    if (idx < 0) {
                      x = MedicationPlan(id: med?.id ?? uid('med'), name: name.text.trim());
                      dd.medications.add(x);
                    } else {
                      x = dd.medications[idx];
                    }
                    final newlyConfirmed = confirmed && !x.confirmedCurrent;
                    x
                      ..name = name.text.trim()
                      ..area = area
                      ..instructions = instr.text.trim()
                      ..timesOfDay = times
                      ..weekdays = weekdays
                      ..prescribedBy = by.text.trim()
                      ..note = note.text.trim()
                      ..active = active
                      ..confirmedCurrent = confirmed
                      ..updatedAt = nowIso();
                    if (newlyConfirmed) x.confirmedAt = nowIso();
                    if (!confirmed) x.confirmedAt = null;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Lưu'),
              ),
            ]),
          ]),
        ),
      );
    }),
  );
}
