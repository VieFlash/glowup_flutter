import 'package:flutter/material.dart';

import '../logic/date_utils.dart';
import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});
  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  bool month = false;
  String anchor = todayStr();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final g = d.goals;
    final r = month ? monthRange(anchor) : weekRange(anchor);
    final days = eachDate(r.start, r.end);
    final stats = sleepStats(d, r.start, r.end);
    final byDate = {for (final l in d.sleepLogs) l.date: l};
    final suggestion = sleepShiftSuggestion(d);
    final list = [...d.sleepLogs]..sort((a, b) => b.date.compareTo(a.date));
    final hasToday = byDate.containsKey(todayStr());

    return PageBody(children: [
      PageHeader(
        title: 'Giấc ngủ',
        subtitle: 'Mục tiêu: lên giường ${g.bedTime} · ngủ ${g.sleepTime} · dậy ${g.wakeTime} · ~${fmtNum(g.sleepHours)} giờ',
        actions: [
          FilledButton.icon(
            onPressed: () => showSleepEditor(context, hasToday ? byDate[todayStr()] : null),
            icon: Icon(hasToday ? Icons.edit : Icons.add),
            label: Text(hasToday ? 'Sửa đêm qua' : 'Ghi đêm qua'),
          ),
        ],
      ),
      if (suggestion != null)
        InfoBanner(
          'Gần đây bạn thường ngủ muộn hơn mục tiêu khoảng ${suggestion.avgLateMin} phút. '
          'Thay vì ép thay đổi đột ngột, thử đặt mục tiêu trung gian ${suggestion.stepTarget} trong vài ngày, '
          'rồi dịch sớm thêm 15–30 phút mỗi vài ngày. Giữ giờ thức dậy ổn định.',
          tone: Tone.info,
          icon: Icons.trending_down,
        ),
      SectionCard(
        title: 'Thói quen trước khi ngủ',
        icon: Icons.nightlight_outlined,
        child: Text(
          '• Từ khoảng 21:30: giảm ánh sáng, hạn chế điện thoại và việc căng thẳng.\n'
          '• Hạn chế cà phê, trà đặc, nước tăng lực vào buổi chiều tối nếu thấy khó ngủ.\n'
          '• Tổng thời lượng, sự đều đặn và chất lượng giấc ngủ quan trọng hơn một mốc giờ cụ thể.',
          style: const TextStyle(height: 1.5),
        ),
      ),
      SectionCard(
        title: month ? fmtMonth(anchor) : 'Tuần ${fmtDayMonth(r.start)} – ${fmtDayMonth(r.end)}',
        icon: Icons.bar_chart,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              onPressed: () => setState(() => anchor = month ? shiftMonth(anchor, -1) : shiftDate(anchor, -7)),
              icon: const Icon(Icons.chevron_left)),
          IconButton(
              onPressed: () => setState(() => anchor = month ? shiftMonth(anchor, 1) : shiftDate(anchor, 7)),
              icon: const Icon(Icons.chevron_right)),
        ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<bool>(
            segments: const [ButtonSegment(value: false, label: Text('Tuần')), ButtonSegment(value: true, label: Text('Tháng'))],
            selected: {month},
            onSelectionChanged: (s) => setState(() => month = s.first),
          ),
          const SizedBox(height: 12),
          StatGrid(children: [
            StatTile(label: 'TB thời lượng', value: fmtHours(stats.avgHours)),
            StatTile(label: 'Ngủ đúng giờ', value: fmtPct(stats.onTimeRate), hint: '≤15 phút so với ${g.sleepTime}'),
            StatTile(label: 'Chất lượng TB', value: stats.avgQuality == null ? '—' : '${fmtNum(stats.avgQuality)}/5', hint: 'tự đánh giá'),
            StatTile(label: 'Số đêm đã ghi', value: '${stats.count}/${days.length}'),
          ]),
          const SizedBox(height: 16),
          if (stats.count == 0)
            const EmptyState(icon: Icons.bedtime_outlined, title: 'Chưa có dữ liệu trong khoảng này')
          else
            SimpleBarChart(
              values: [for (final day in days) byDate[day] == null ? null : sleepDurationHours(byDate[day]!.sleepTime, byDate[day]!.wakeTime)],
              labels: [for (final day in days) month ? '${fromLocalDate(day).day}' : weekdayShort[weekdayOf(day)]],
              goal: g.sleepHours,
              goalLabel: 'Mục tiêu ${fmtNum(g.sleepHours)}g',
              maxY: 12,
              yFormat: (v) => '${v.round()}g',
            ),
        ]),
      ),
      SectionCard(
        title: 'Nhật ký',
        icon: Icons.list_alt,
        trailing: TextButton.icon(
          onPressed: () => showSleepEditor(context, null),
          icon: const Icon(Icons.add),
          label: const Text('Thêm'),
        ),
        child: list.isEmpty
            ? const EmptyState(
                icon: Icons.bedtime_outlined,
                title: 'Chưa ghi đêm nào',
                message: 'Mỗi sáng ghi giờ ngủ – thức để thấy xu hướng thật.')
            : Column(children: [
                for (final l in list.take(60))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${fmtDate(l.date)} · ${fmtHours(sleepDurationHours(l.sleepTime, l.wakeTime))}'),
                    subtitle: Text([
                      'Lên giường ${l.bedTime} · ngủ ${l.sleepTime} · dậy ${l.wakeTime}',
                      'Chất lượng ${l.quality}/5',
                      if (l.lateReason.isNotEmpty) 'Lý do: ${l.lateReason}',
                    ].join('\n')),
                    isThreeLine: true,
                    leading: Icon(sleptOnTime(d, l) ? Icons.check_circle_outline : Icons.schedule,
                        color: sleptOnTime(d, l) ? Theme.of(context).colorScheme.primary : null),
                    onTap: () => showSleepEditor(context, l),
                  ),
              ]),
      ),
    ]);
  }
}

Future<void> showSleepEditor(BuildContext context, SleepLog? log) async {
  final st = AppScope.read(context);
  final g = st.data.goals;
  var date = log?.date ?? todayStr();
  var bed = log?.bedTime ?? g.bedTime;
  var sleep = log?.sleepTime ?? g.sleepTime;
  var wake = log?.wakeTime ?? nowHm();
  var quality = log?.quality ?? 3;
  final reason = TextEditingController(text: log?.lateReason ?? '');
  String? err;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final dur = sleepDurationHours(sleep, wake);
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text(log == null ? 'Ghi giấc ngủ' : 'Sửa giấc ngủ', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              DateButton(label: 'Ngày thức dậy', value: date, last: todayStr(), onChanged: (v) => setS(() => date = v)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TimeButton(label: 'Lên giường', value: bed, onChanged: (v) => setS(() => bed = v))),
                const SizedBox(width: 8),
                Expanded(child: TimeButton(label: 'Bắt đầu ngủ (ước tính)', value: sleep, onChanged: (v) => setS(() => sleep = v))),
              ]),
              const SizedBox(height: 12),
              TimeButton(label: 'Thức dậy', value: wake, onChanged: (v) => setS(() => wake = v)),
              const SizedBox(height: 8),
              Text('Thời lượng: ${fmtHours(dur)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              RatingSelector(label: 'Chất lượng giấc ngủ', value: quality, hints: const ['rất tệ', 'rất tốt'], onChanged: (v) => setS(() => quality = v)),
              TextField(
                controller: reason,
                decoration: const InputDecoration(labelText: 'Nguyên nhân ngủ muộn (nếu có)', hintText: 'VD: làm việc muộn, dùng điện thoại…'),
              ),
              if (err != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(err!, style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
              const SizedBox(height: 16),
              Row(children: [
                if (log != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
                    onPressed: () async {
                      final ok = await confirmDialog(ctx,
                          title: 'Xóa bản ghi?', message: 'Giấc ngủ ngày ${fmtDate(log.date)}', confirmText: 'Xóa', danger: true);
                      if (!ok) return;
                      st.update((dd) => dd.sleepLogs.removeWhere((e) => e.id == log.id));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa'),
                  ),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                FilledButton(
                  onPressed: () {
                    if (dur > 16) {
                      setS(() => err = 'Thời lượng trên 16 giờ — kiểm tra lại giờ ngủ/thức.');
                      return;
                    }
                    if (minutesLate(sleep, bed) < 0) {
                      setS(() => err = 'Giờ bắt đầu ngủ không thể sớm hơn giờ lên giường.');
                      return;
                    }
                    final dup = st.data.sleepLogs.any((e) => e.date == date && e.id != log?.id);
                    if (dup) {
                      setS(() => err = 'Ngày ${fmtDate(date)} đã có bản ghi. Hãy sửa bản ghi đó.');
                      return;
                    }
                    st.update((dd) {
                      if (log == null) {
                        dd.sleepLogs.add(SleepLog(
                            id: uid('sl'),
                            date: date,
                            bedTime: bed,
                            sleepTime: sleep,
                            wakeTime: wake,
                            quality: quality,
                            lateReason: reason.text.trim()));
                      } else {
                        final x = dd.sleepLogs.firstWhere((e) => e.id == log.id);
                        x
                          ..date = date
                          ..bedTime = bed
                          ..sleepTime = sleep
                          ..wakeTime = wake
                          ..quality = quality
                          ..lateReason = reason.text.trim()
                          ..updatedAt = nowIso();
                      }
                      // Đánh dấu nhiệm vụ của NGÀY HÔM TRƯỚC (đêm ngủ) và sáng thức dậy
                      final prev = shiftDate(date, -1);
                      if (minutesLate(sleep, dd.goals.sleepTime) <= 0) setHabitStatus(dd, prev, 'hb_sleep', 'done');
                      if (minutesLate(wake, dd.goals.wakeTime) <= 15 && hmToMin(wake) < 12 * 60) {
                        setHabitStatus(dd, date, 'hb_wake', 'done');
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Lưu'),
                ),
              ]),
            ]),
          ),
        );
      },
    ),
  );
}
