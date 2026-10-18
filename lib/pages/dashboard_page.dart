import 'package:flutter/material.dart';

import '../app.dart';
import '../logic/date_utils.dart';
import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/meds_today.dart';
import 'habits_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  String _greeting(String name) {
    final h = DateTime.now().hour;
    final g = h < 11 ? 'Chào buổi sáng' : (h < 14 ? 'Chào buổi trưa' : (h < 18 ? 'Chào buổi chiều' : 'Chào buổi tối'));
    return name.trim().isEmpty ? g : '$g, ${name.trim()}';
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final t = todayStr();
    final prog = dayProgress(d, t);
    final streak = currentStreak(d);
    final wk = weekRange(t);
    final mo = monthRange(t);
    final weekRate = rangeHabitRate(d, wk.start, wk.end);
    final monthRate = rangeHabitRate(d, mo.start, mo.end);
    final habits = habitsForDate(d, t);
    final nowMin = hmToMin(nowHm());

    // Nhắc nhở nhẹ nhàng: việc quan trọng đã qua giờ nhưng chưa làm.
    final reminders = habits.where((h) {
      if (!h.important) return false;
      if (habitStatus(d, t, h.id) != null) return false;
      if (h.time == null || !isValidHm(h.time!)) return nowMin >= 20 * 60;
      return nowMin >= hmToMin(h.time!) + 30;
    }).toList();

    return PageBody(children: [
      PageHeader(title: _greeting(d.profile.name), subtitle: fmtLong(t)),
      _SummaryCard(prog: prog, streak: streak, weekRate: weekRate, monthRate: monthRate),
      if (reminders.isNotEmpty)
        SectionCard(
          title: 'Nhắc nhẹ',
          icon: Icons.notifications_none,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final h in reminders)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• ${h.title}${h.time != null ? ' (${h.time})' : ''}'),
                ),
              Text(
                'Chưa kịp cũng không sao — làm phần nhỏ nhất có thể, hoặc đánh dấu "Bỏ qua" để ngày mai bắt đầu lại.',
                style: mutedStyle(context),
              ),
            ],
          ),
        ),
      SectionCard(
        title: 'Nhiệm vụ hôm nay',
        subtitle: '${prog.done}/${prog.counted} đã xong'
            '${prog.skipped > 0 ? ' · ${prog.skipped} bỏ qua' : ''}'
            '${prog.na > 0 ? ' · ${prog.na} không áp dụng' : ''}',
        icon: Icons.checklist,
        trailing: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HabitsPage())),
          child: const Text('Quản lý'),
        ),
        child: habits.isEmpty
            ? EmptyState(
                icon: Icons.checklist,
                title: 'Chưa có nhiệm vụ nào cho hôm nay',
                action: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HabitsPage())),
                  child: const Text('Thêm nhiệm vụ'),
                ),
              )
            : Column(children: [for (final h in habits) HabitTile(habit: h, date: t)]),
      ),
      LayoutBuilder(builder: (context, c) {
        final cards = <Widget>[
          _SleepTargetCard(goals: d.goals),
          _WorkoutTodayCard(data: d, date: t),
          _MealsTodayCard(data: d, date: t),
          _CareTodayCard(data: d, date: t),
        ];
        if (c.maxWidth < 640) return Column(children: cards);
        return Column(children: [
          for (var i = 0; i < cards.length; i += 2)
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: cards[i]),
                const SizedBox(width: 12),
                Expanded(child: i + 1 < cards.length ? cards[i + 1] : const SizedBox()),
              ]),
            ),
        ]);
      }),
      const SectionCard(
        title: 'Thuốc / sản phẩm điều trị hôm nay',
        icon: Icons.medication_outlined,
        subtitle: 'Chỉ hiển thị những gì bạn đã xác nhận đang dùng theo hướng dẫn hiện hành',
        child: MedsTodayList(),
      ),
    ]);
  }
}

class _SummaryCard extends StatelessWidget {
  final DayProgress prog;
  final int streak;
  final double? weekRate, monthRate;
  const _SummaryCard({required this.prog, required this.streak, required this.weekRate, required this.monthRate});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          ProgressRing(
            value: prog.rate,
            size: 100,
            center: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(prog.rate == null ? '—' : fmtPct(prog.rate),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              Text('hôm nay', style: mutedStyle(context)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv(context, Icons.local_fire_department_outlined, 'Chuỗi duy trì', '$streak ngày'),
                _kv(context, Icons.date_range, 'Tuần này', fmtPct(weekRate)),
                _kv(context, Icons.calendar_month, 'Tháng này', fmtPct(monthRate)),
                const SizedBox(height: 4),
                Text('Ngày duy trì = hoàn thành từ 50% nhiệm vụ. "Bỏ qua" và "Không áp dụng" không bị tính là chưa làm.',
                    style: mutedStyle(context)?.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, IconData i, String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(i, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(k)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}

/// Một dòng nhiệm vụ: checkbox + menu Bỏ qua / Không áp dụng / Sửa.
class HabitTile extends StatelessWidget {
  final Habit habit;
  final String date;
  const HabitTile({super.key, required this.habit, required this.date});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final status = habitStatus(st.data, date, habit.id);
    final cs = Theme.of(context).colorScheme;
    final muted = status == 'skipped' || status == 'na';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => st.update((d) => setHabitStatus(d, date, habit.id, status == 'done' ? null : 'done')),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: status == 'done',
              onChanged: (v) => st.update((d) => setHabitStatus(d, date, habit.id, v == true ? 'done' : null)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: TextStyle(
                      decoration: status == 'done' || muted ? TextDecoration.lineThrough : null,
                      color: status == 'done' || muted ? cs.onSurfaceVariant : null,
                    ),
                  ),
                  Wrap(spacing: 6, children: [
                    if (habit.time != null) Text(habit.time!, style: mutedStyle(context)),
                    if (habit.important) Tag('Quan trọng', color: cs.tertiary),
                    if (status == 'skipped') Tag('Bỏ qua', color: cs.outline),
                    if (status == 'na') Tag('Không áp dụng', color: cs.outline),
                  ]),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Tùy chọn',
              onSelected: (v) async {
                if (v == 'edit') {
                  await showHabitEditor(context, habit);
                  return;
                }
                st.update((d) => setHabitStatus(d, date, habit.id, v == 'clear' ? null : v));
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'done', child: Text('Đánh dấu hoàn thành')),
                PopupMenuItem(value: 'skipped', child: Text('Bỏ qua hôm nay')),
                PopupMenuItem(value: 'na', child: Text('Không áp dụng hôm nay')),
                PopupMenuItem(value: 'clear', child: Text('Bỏ đánh dấu')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'edit', child: Text('Sửa nhiệm vụ')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepTargetCard extends StatelessWidget {
  final Goals goals;
  const _SleepTargetCard({required this.goals});
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Giấc ngủ mục tiêu',
      icon: Icons.bedtime_outlined,
      trailing: TextButton(onPressed: () => appNav.value = 4, child: const Text('Ghi')),
      child: Row(children: [
        Expanded(child: StatTile(label: 'Lên giường', value: goals.bedTime)),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'Ngủ', value: goals.sleepTime)),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'Thức dậy', value: goals.wakeTime)),
      ]),
    );
  }
}

class _WorkoutTodayCard extends StatelessWidget {
  final AppData data;
  final String date;
  const _WorkoutTodayCard({required this.data, required this.date});
  @override
  Widget build(BuildContext context) {
    final p = plannedWorkoutsFor(data, date);
    final sessions = sessionsOn(data, date);
    final done = sessions.any((s) => s.completed);
    return SectionCard(
      title: 'Lịch tập hôm nay',
      icon: Icons.fitness_center,
      trailing: TextButton(onPressed: () => appNav.value = 2, child: const Text('Mở')),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (p.movedOutTo != null) Text('Buổi tập hôm nay đã dời sang ${fmtDate(p.movedOutTo!)}.', style: mutedStyle(context)),
        if (p.items.isEmpty && p.movedOutTo == null) Text('Không có buổi tập theo kế hoạch.', style: mutedStyle(context)),
        for (final it in p.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Expanded(
                child: Text('${it.day.title}${it.movedIn ? ' (dời từ ${fmtDayMonth(it.sourceDate)})' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Tag(_typeLabel(it.day.type)),
            ]),
          ),
        if (done)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Row(children: [Icon(Icons.check_circle, size: 18), SizedBox(width: 6), Text('Đã hoàn thành buổi tập')]),
          ),
      ]),
    );
  }
}

String _typeLabel(String t) => switch (t) {
      'strength' => 'Sức mạnh',
      'cardio' => 'Cardio',
      'light' => 'Nhẹ',
      _ => 'Nghỉ',
    };

class _MealsTodayCard extends StatelessWidget {
  final AppData data;
  final String date;
  const _MealsTodayCard({required this.data, required this.date});
  @override
  Widget build(BuildContext context) {
    final logged = data.mealLogs.where((m) => m.date == date).map((m) => m.slot).toSet();
    return SectionCard(
      title: 'Các bữa ăn',
      icon: Icons.restaurant,
      trailing: TextButton(onPressed: () => appNav.value = 3, child: const Text('Ghi')),
      child: Column(children: [
        for (final s in slots)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(logged.contains(s) ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18, color: logged.contains(s) ? Theme.of(context).colorScheme.primary : null),
              const SizedBox(width: 8),
              SizedBox(width: 74, child: Text('${slotTime[s]} ', style: mutedStyle(context))),
              Expanded(child: Text(mealOptionById(data, plannedMealId(data, date, s))?.name ?? slotLabel[s]!)),
            ]),
          ),
      ]),
    );
  }
}

class _CareTodayCard extends StatelessWidget {
  final AppData data;
  final String date;
  const _CareTodayCard({required this.data, required this.date});
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    Widget row(String key, String label, int nav) => CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: careDone(data, date, key),
          onChanged: (v) => st.update((d) => setCare(d, date, key, v == true)),
          title: Text(label),
          secondary: IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Mở',
            onPressed: () => appNav.value = nav,
          ),
        );
    return SectionCard(
      title: 'Routine chăm sóc',
      icon: Icons.spa_outlined,
      child: Column(children: [
        row('skin-am', 'Da – buổi sáng', 5),
        row('skin-pm', 'Da – buổi tối', 5),
        row('hair', 'Tóc – theo kế hoạch đã xác nhận', 6),
      ]),
    );
  }
}
