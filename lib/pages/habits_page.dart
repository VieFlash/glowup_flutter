import 'package:flutter/material.dart';

import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Quản lý danh sách nhiệm vụ / thói quen hằng ngày.
class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final habits = [...st.data.habits]..sort((a, b) => a.order.compareTo(b.order));
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý nhiệm vụ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showHabitEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
      body: habits.isEmpty
          ? const EmptyState(icon: Icons.checklist, title: 'Chưa có nhiệm vụ', message: 'Nhấn "Thêm" để tạo nhiệm vụ đầu tiên.')
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              itemCount: habits.length,
              onReorder: (oldI, newI) {
                st.update((d) {
                  final l = [...d.habits]..sort((a, b) => a.order.compareTo(b.order));
                  if (newI > oldI) newI--;
                  final it = l.removeAt(oldI);
                  l.insert(newI, it);
                  for (var i = 0; i < l.length; i++) {
                    l[i].order = i + 1;
                  }
                });
              },
              itemBuilder: (context, i) {
                final h = habits[i];
                return Card(
                  key: ValueKey(h.id),
                  elevation: 0,
                  child: ListTile(
                    leading: Switch(
                      value: h.active,
                      onChanged: (v) => st.update((d) {
                        final x = d.habits.firstWhere((e) => e.id == h.id);
                        x.active = v;
                        x.updatedAt = nowIso();
                      }),
                    ),
                    title: Text(h.title, style: TextStyle(color: h.active ? null : Theme.of(context).disabledColor)),
                    subtitle: Text([
                      habitCategoryLabel[h.category] ?? 'Khác',
                      if (h.time != null) h.time!,
                      if (h.weekdays.isNotEmpty) '${h.weekdays.length} ngày/tuần' else 'Mỗi ngày',
                      if (h.important) 'Quan trọng',
                    ].join(' · ')),
                    trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => showHabitEditor(context, h)),
                  ),
                );
              },
            ),
    );
  }
}

Future<void> showHabitEditor(BuildContext context, Habit? habit) async {
  final st = AppScope.read(context);
  final title = TextEditingController(text: habit?.title ?? '');
  var category = habit?.category ?? 'other';
  String? time = habit?.time;
  var important = habit?.important ?? false;
  var weekdays = [...?habit?.weekdays];
  String? err;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(habit == null ? 'Thêm nhiệm vụ' : 'Sửa nhiệm vụ', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                decoration: InputDecoration(labelText: 'Tên nhiệm vụ', errorText: err),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Nhóm'),
                items: [
                  for (final e in habitCategoryLabel.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setS(() => category = v ?? 'other'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: time == null
                      ? OutlinedButton.icon(
                          onPressed: () async {
                            final v = await pickTime(ctx, '20:00');
                            if (v != null) setS(() => time = v);
                          },
                          icon: const Icon(Icons.schedule),
                          label: const Text('Đặt giờ (tùy chọn)'),
                        )
                      : TimeButton(label: 'Giờ', value: time!, onChanged: (v) => setS(() => time = v)),
                ),
                if (time != null)
                  IconButton(onPressed: () => setS(() => time = null), icon: const Icon(Icons.close), tooltip: 'Bỏ giờ'),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: important,
                onChanged: (v) => setS(() => important = v),
                title: const Text('Quan trọng (hiện nhắc nhở nếu chưa làm)'),
              ),
              const Text('Áp dụng vào (để trống = mỗi ngày)'),
              const SizedBox(height: 6),
              WeekdayPicker(selected: weekdays, onChanged: (v) => setS(() => weekdays = v)),
              const SizedBox(height: 16),
              Row(children: [
                if (habit != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
                    onPressed: () async {
                      final ok = await confirmDialog(ctx,
                          title: 'Xóa nhiệm vụ?',
                          message: 'Lịch sử hoàn thành của nhiệm vụ này cũng sẽ bị xóa.',
                          confirmText: 'Xóa',
                          danger: true);
                      if (!ok) return;
                      st.update((d) {
                        d.habits.removeWhere((e) => e.id == habit.id);
                        d.completions.removeWhere((k, v) => v.habitId == habit.id);
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa'),
                  ),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final t = title.text.trim();
                    if (t.isEmpty) {
                      setS(() => err = 'Vui lòng nhập tên nhiệm vụ');
                      return;
                    }
                    st.update((d) {
                      if (habit == null) {
                        final maxOrder = d.habits.fold<int>(0, (a, b) => b.order > a ? b.order : a);
                        d.habits.add(Habit(
                          id: uid('hb'),
                          title: t,
                          category: category,
                          time: time,
                          important: important,
                          weekdays: weekdays,
                          order: maxOrder + 1,
                        ));
                      } else {
                        final x = d.habits.firstWhere((e) => e.id == habit.id);
                        x
                          ..title = t
                          ..category = category
                          ..time = time
                          ..important = important
                          ..weekdays = weekdays
                          ..updatedAt = nowIso();
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Lưu'),
                ),
              ]),
            ],
          ),
        ),
      );
    }),
  );
}
