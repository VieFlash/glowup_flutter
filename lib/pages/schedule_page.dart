import 'package:flutter/material.dart';

import '../data/defaults.dart';
import '../logic/date_utils.dart';
import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'workout_page.dart';

const kindLabel = {
  'wake': 'Thức dậy',
  'meal': 'Ăn uống',
  'work': 'Làm việc',
  'rest': 'Nghỉ',
  'workout': 'Vận động',
  'care': 'Chăm sóc',
  'winddown': 'Thư giãn',
  'sleep': 'Ngủ',
  'other': 'Khác',
};

const kindIcon = {
  'wake': Icons.wb_twilight,
  'meal': Icons.restaurant,
  'work': Icons.laptop_mac,
  'rest': Icons.self_improvement,
  'workout': Icons.directions_walk,
  'care': Icons.spa_outlined,
  'winddown': Icons.nightlight_outlined,
  'sleep': Icons.bedtime_outlined,
  'other': Icons.circle_outlined,
};

/// Gợi ý điều chỉnh nhẹ nhàng khi bỏ lỡ một hoạt động.
String _gentleTip(ScheduleItem it) => switch (it.kind) {
      'meal' => 'Lỡ giờ ăn? Ăn một bữa nhẹ có protein (trứng, sữa chua, đậu phụ…) khi có thể, không cần bù gấp đôi.',
      'workout' =>
        'Không kịp tập? Đi bộ 10–15 phút cũng tốt, hoặc dời buổi tập sang ngày khác ở trang Tập luyện.',
      'care' => 'Nếu mệt, làm bước tối thiểu: rửa mặt nhẹ và dưỡng ẩm. Thuốc thì theo đúng hướng dẫn bác sĩ.',
      'winddown' || 'sleep' =>
        'Ngủ muộn hơn dự kiến không sao. Tối mai thử chuẩn bị sớm hơn 15 phút, giữ giờ thức dậy ổn định.',
      'wake' => 'Dậy muộn? Giữ phần còn lại của ngày như bình thường, tránh ngủ bù quá dài vào buổi chiều.',
      _ => 'Bỏ lỡ một hoạt động không làm hỏng cả ngày — tiếp tục với việc tiếp theo.',
    };

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String date = todayStr();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final items = [...d.routine.items]..sort((a, b) => hmToMin(a.time).compareTo(hmToMin(b.time)));
    final isToday = date == todayStr();
    final isPast = date.compareTo(todayStr()) < 0;
    final nowMin = hmToMin(nowHm());
    final doneCount = items.where((it) => d.scheduleChecks['$date:${it.id}'] == true).length;
    final planned = plannedWorkoutsFor(d, date);

    return PageBody(children: [
      PageHeader(
        title: 'Lịch sinh hoạt',
        subtitle: 'Linh hoạt — không có "thất bại" vì bỏ lỡ',
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'add') _editItem(context, null);
              if (v == 'reset') {
                final ok = await confirmDialog(context,
                    title: 'Khôi phục lịch mặc định?', message: 'Các chỉnh sửa giờ của bạn sẽ được thay bằng lịch mặc định.');
                if (ok) {
                  st.update((dd) {
                    dd.routine.items = defaultRoutine();
                    dd.routine.updatedAt = nowIso();
                  });
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'add', child: Text('Thêm hoạt động')),
              PopupMenuItem(value: 'reset', child: Text('Khôi phục lịch mặc định')),
            ],
          ),
        ],
      ),
      DateNavigator(date: date, onChanged: (v) => setState(() => date = v)),
      SectionCard(
        child: Row(children: [
          Expanded(child: Text('Đã hoàn thành $doneCount/${items.length} hoạt động', style: const TextStyle(fontWeight: FontWeight.w600))),
          if (planned.items.isNotEmpty || planned.movedOutTo != null)
            OutlinedButton.icon(
              onPressed: () => showMoveWorkoutDialog(context, date),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Dời buổi tập'),
            ),
        ]),
      ),
      if (planned.movedOutTo != null)
        InfoBanner('Buổi tập hôm nay đã dời sang ${fmtLong(planned.movedOutTo!)}.', tone: Tone.info),
      for (final p in planned.items.where((e) => e.movedIn))
        InfoBanner('Hôm nay có buổi "${p.day.title}" dời từ ${fmtDate(p.sourceDate)}.', tone: Tone.info),
      SectionCard(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(children: [
          for (final it in items)
            Builder(builder: (context) {
              final key = '$date:${it.id}';
              final done = d.scheduleChecks[key] == true;
              final endMin = hmToMin(it.endTime ?? it.time) + 30;
              final missed = !done && (isPast || (isToday && nowMin > endMin));
              return Column(children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Checkbox(
                    value: done,
                    onChanged: (v) => st.update((dd) {
                      if (v == true) {
                        dd.scheduleChecks[key] = true;
                      } else {
                        dd.scheduleChecks.remove(key);
                      }
                    }),
                  ),
                  title: Text(it.title,
                      style: TextStyle(
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                      )),
                  subtitle: Row(children: [
                    Icon(kindIcon[it.kind] ?? Icons.circle_outlined, size: 14),
                    const SizedBox(width: 4),
                    Text('${it.time}${it.endTime != null ? '–${it.endTime}' : ''} · ${kindLabel[it.kind] ?? ''}'),
                  ]),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Sửa',
                    onPressed: () => _editItem(context, it),
                  ),
                ),
                if (missed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 12, 8),
                    child: Text(_gentleTip(it), style: mutedStyle(context)?.copyWith(fontStyle: FontStyle.italic)),
                  ),
              ]);
            }),
        ]),
      ),
    ]);
  }

  Future<void> _editItem(BuildContext context, ScheduleItem? item) async {
    final st = AppScope.read(context);
    final title = TextEditingController(text: item?.title ?? '');
    var time = item?.time ?? '09:00';
    String? endTime = item?.endTime;
    var kind = item?.kind ?? 'other';
    String? err;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text(item == null ? 'Thêm hoạt động' : 'Sửa hoạt động', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: title, decoration: InputDecoration(labelText: 'Tên hoạt động', errorText: err)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TimeButton(label: 'Bắt đầu', value: time, onChanged: (v) => setS(() => time = v))),
                const SizedBox(width: 8),
                Expanded(
                  child: endTime == null
                      ? OutlinedButton(
                          onPressed: () async {
                            final v = await pickTime(ctx, minToHm(hmToMin(time) + 30));
                            if (v != null) setS(() => endTime = v);
                          },
                          child: const Text('+ Giờ kết thúc'))
                      : TimeButton(label: 'Kết thúc', value: endTime!, onChanged: (v) => setS(() => endTime = v)),
                ),
                if (endTime != null) IconButton(onPressed: () => setS(() => endTime = null), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: kind,
                decoration: const InputDecoration(labelText: 'Loại'),
                items: [for (final e in kindLabel.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setS(() => kind = v ?? 'other'),
              ),
              const SizedBox(height: 16),
              Row(children: [
                if (item != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
                    onPressed: () async {
                      final ok = await confirmDialog(ctx,
                          title: 'Xóa hoạt động?', message: '"${item.title}" sẽ bị xóa khỏi lịch.', confirmText: 'Xóa', danger: true);
                      if (!ok) return;
                      st.update((dd) {
                        dd.routine.items.removeWhere((e) => e.id == item.id);
                        dd.routine.updatedAt = nowIso();
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
                    if (title.text.trim().isEmpty) {
                      setS(() => err = 'Vui lòng nhập tên');
                      return;
                    }
                    if (endTime != null && hmToMin(endTime!) <= hmToMin(time)) {
                      setS(() => err = 'Giờ kết thúc phải sau giờ bắt đầu');
                      return;
                    }
                    st.update((dd) {
                      if (item == null) {
                        dd.routine.items.add(
                            ScheduleItem(id: uid('rt'), time: time, endTime: endTime, title: title.text.trim(), kind: kind));
                      } else {
                        final x = dd.routine.items.firstWhere((e) => e.id == item.id);
                        x
                          ..title = title.text.trim()
                          ..time = time
                          ..endTime = endTime
                          ..kind = kind;
                      }
                      dd.routine.updatedAt = nowIso();
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Lưu'),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
