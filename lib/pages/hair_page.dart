import 'package:flutter/material.dart';

import '../logic/date_utils.dart';
import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/medications.dart';
import '../widgets/meds_today.dart';
import '../widgets/photo_tracker.dart';

class HairPage extends StatefulWidget {
  const HairPage({super.key});
  @override
  State<HairPage> createState() => _HairPageState();
}

class _HairPageState extends State<HairPage> {
  int tab = 0;
  String date = todayStr();

  @override
  Widget build(BuildContext context) {
    return PageBody(children: [
      const PageHeader(title: 'Chăm sóc tóc', subtitle: 'Theo dõi tuân thủ & thay đổi theo thời gian'),
      const InfoBanner(
        'App không chẩn đoán từ ảnh và không hứa hẹn phục hồi nang tóc. Không tự tăng liều, đổi tần suất hay tự bắt đầu lại đơn cũ — '
        'mọi thay đổi điều trị cần trao đổi với bác sĩ. Ăn đủ năng lượng, protein và vi chất từ thực phẩm hỗ trợ sức khỏe chung, '
        'không phải phương pháp điều trị rụng tóc.',
        tone: Tone.warn,
        icon: Icons.health_and_safety_outlined,
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Hôm nay')),
            ButtonSegment(value: 1, label: Text('Xu hướng')),
            ButtonSegment(value: 2, label: Text('Ảnh')),
            ButtonSegment(value: 3, label: Text('Thuốc')),
          ],
          selected: {tab},
          onSelectionChanged: (s) => setState(() => tab = s.first),
        ),
      ),
      const SizedBox(height: 12),
      if (tab == 0) ...[
        DateNavigator(date: date, allowFuture: false, onChanged: (v) => setState(() => date = v)),
        _TodayView(date: date),
        _HairLogForm(date: date, key: ValueKey('hair-$date')),
      ],
      if (tab == 1) const _HairTrend(),
      if (tab == 2) const PhotoTracker(area: 'hair'),
      if (tab == 3) const MedicationManager(area: 'hair'),
    ]);
  }
}

class _TodayView extends StatelessWidget {
  final String date;
  const _TodayView({required this.date});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final last = lastHairWash(d, shiftDate(date, -1));
    final every = d.goals.hairWashEveryDays;
    String washText;
    if (every == null) {
      washText = 'Chưa đặt lịch gội. Đặt theo hướng dẫn hiện hành (bác sĩ hoặc nhãn dầu gội).';
    } else if (last == null) {
      washText = 'Lịch gội: mỗi $every ngày. Chưa có lần gội nào được ghi.';
    } else {
      final since = daysBetween(last, date);
      washText = since >= every
          ? 'Theo lịch (mỗi $every ngày), hôm nay là ngày gội. Lần trước: ${fmtDate(last)}.'
          : 'Lần gội trước: ${fmtDate(last)} ($since ngày trước). Lịch: mỗi $every ngày.';
    }
    final meds = d.medications.where((m) => m.area == 'hair' && medAppliesOn(m, date)).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (d.profile.hairRoutineNote.isNotEmpty)
        InfoBanner('Phác đồ bạn đã ghi: ${d.profile.hairRoutineNote}', icon: Icons.notes),
      SectionCard(
        title: 'Routine tóc hôm nay',
        icon: Icons.content_cut,
        trailing: Switch(
          value: careDone(d, date, 'hair'),
          onChanged: (v) => st.update((dd) => setCare(dd, date, 'hair', v)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Bật công tắc khi đã làm xong routine tóc theo kế hoạch đã xác nhận.', style: mutedStyle(context)),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.shower_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(washText)),
            TextButton(
              onPressed: () async {
                final v = await promptText(context,
                    title: 'Gội đầu mỗi bao nhiêu ngày?',
                    initial: every?.toString() ?? '',
                    hint: 'Theo hướng dẫn hiện hành, VD: 1, 2. Để trống để bỏ lịch.');
                if (v == null) return;
                if (v.isEmpty) {
                  st.update((dd) => dd.goals.hairWashEveryDays = null);
                  return;
                }
                final n = int.tryParse(v);
                if (n == null || n < 1 || n > 14) {
                  if (context.mounted) showSnack(context, 'Nhập số ngày từ 1 đến 14', error: true);
                  return;
                }
                st.update((dd) => dd.goals.hairWashEveryDays = n);
              },
              child: const Text('Đặt lịch'),
            ),
          ]),
          const Divider(height: 24),
          Text('Thuốc / sản phẩm đã xác nhận', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (meds.isEmpty && d.medications.every((m) => m.area != 'hair'))
            Text('Chưa có. Vào tab "Thuốc" để thêm những gì bạn đang dùng theo chỉ định hiện hành.', style: mutedStyle(context))
          else
            MedsTodayList(area: 'hair', date: date),
        ]),
      ),
    ]);
  }
}

class _HairLogForm extends StatefulWidget {
  final String date;
  const _HairLogForm({super.key, required this.date});
  @override
  State<_HairLogForm> createState() => _HairLogFormState();
}

class _HairLogFormState extends State<_HairLogForm> {
  HairLog? existing;
  int shedding = 3;
  bool itch = false, redness = false, flaking = false, irritation = false, washed = false;
  final note = TextEditingController();
  bool init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (init) return;
    init = true;
    for (final l in AppScope.read(context).data.hairLogs) {
      if (l.date == widget.date) existing = l;
    }
    final e = existing;
    if (e != null) {
      shedding = e.shedding;
      itch = e.itch;
      redness = e.redness;
      flaking = e.flaking;
      irritation = e.irritation;
      washed = e.washed;
      note.text = e.note;
    }
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  void _save() {
    AppScope.read(context).update((d) {
      final idx = d.hairLogs.indexWhere((l) => l.date == widget.date);
      final l = idx < 0 ? HairLog(id: uid('hr'), date: widget.date) : d.hairLogs[idx];
      l
        ..shedding = shedding
        ..itch = itch
        ..redness = redness
        ..flaking = flaking
        ..irritation = irritation
        ..washed = washed
        ..routineDone = careDone(d, widget.date, 'hair')
        ..note = note.text.trim()
        ..updatedAt = nowIso();
      if (idx < 0) d.hairLogs.add(l);
      existing = l;
    });
    setState(() {});
    showSnack(context, 'Đã lưu nhật ký tóc ${fmtDate(widget.date)}');
  }

  @override
  Widget build(BuildContext context) {
    final concern = redness || irritation;
    return SectionCard(
      title: 'Nhật ký tóc & da đầu',
      icon: Icons.edit_note,
      subtitle: existing == null ? 'Chưa ghi ngày này' : 'Đã ghi — chỉnh và lưu lại nếu cần',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        RatingSelector(
          label: 'Mức độ rụng tóc (tự đánh giá)',
          value: shedding,
          hints: const ['rất ít', 'rất nhiều'],
          onChanged: (v) => setState(() => shedding = v),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilterChip(label: const Text('Ngứa'), selected: itch, onSelected: (v) => setState(() => itch = v)),
          FilterChip(label: const Text('Đỏ'), selected: redness, onSelected: (v) => setState(() => redness = v)),
          FilterChip(label: const Text('Bong tróc'), selected: flaking, onSelected: (v) => setState(() => flaking = v)),
          FilterChip(label: const Text('Kích ứng'), selected: irritation, onSelected: (v) => setState(() => irritation = v)),
          FilterChip(
            avatar: const Icon(Icons.shower_outlined, size: 16),
            label: const Text('Đã gội đầu'),
            selected: washed,
            onSelected: (v) => setState(() => washed = v),
          ),
        ]),
        if (concern)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: InfoBanner(
              'Nếu đỏ/kích ứng da đầu kéo dài, nặng dần, hoặc có phản ứng bất thường khác, hãy liên hệ bác sĩ. Không tự thay đổi thuốc.',
              tone: Tone.danger,
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Ghi chú (thay đổi sức khỏe, chế độ ăn, căng thẳng…)'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          if (existing != null)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () async {
                final ok = await confirmDialog(context,
                    title: 'Xóa nhật ký tóc?', message: 'Ngày ${fmtDate(widget.date)}', confirmText: 'Xóa', danger: true);
                if (!ok || !mounted) return;
                AppScope.read(context).update((d) => d.hairLogs.removeWhere((l) => l.date == widget.date));
                setState(() {
                  existing = null;
                  shedding = 3;
                  itch = redness = flaking = irritation = washed = false;
                  note.clear();
                });
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Xóa'),
            ),
          const Spacer(),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Lưu nhật ký')),
        ]),
      ]),
    );
  }
}

class _HairTrend extends StatefulWidget {
  const _HairTrend();
  @override
  State<_HairTrend> createState() => _HairTrendState();
}

class _HairTrendState extends State<_HairTrend> {
  int weeks = 12;
  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context).data;
    final t = todayStr();
    final start = shiftDate(t, -(weeks * 7 - 1));
    // Gộp theo tuần
    final labels = <String>[];
    final shed = <double?>[];
    final routine = <double?>[];
    var ws = weekRange(start).start;
    while (ws.compareTo(t) <= 0) {
      final we = shiftDate(ws, 6);
      final logs = d.hairLogs.where((l) => inRange(l.date, ws, we));
      labels.add(fmtDayMonth(ws));
      shed.add(avg(logs.map((l) => l.shedding)));
      final effEnd = we.compareTo(t) > 0 ? t : we;
      final daysIn = eachDate(ws, effEnd).length;
      final doneDays = eachDate(ws, effEnd).where((x) => careDone(d, x, 'hair')).length;
      routine.add(daysIn == 0 ? null : doneDays / daysIn * 100);
      ws = shiftDate(ws, 7);
    }
    final adh = medAdherence(d, start, t, 'hair');
    final cs = Theme.of(context).colorScheme;
    final hasData = shed.any((x) => x != null) || routine.any((x) => x != null && x > 0);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 4, label: Text('4 tuần')),
          ButtonSegment(value: 8, label: Text('8 tuần')),
          ButtonSegment(value: 12, label: Text('12 tuần')),
          ButtonSegment(value: 26, label: Text('26 tuần')),
        ],
        selected: {weeks},
        onSelectionChanged: (s) => setState(() => weeks = s.first),
      ),
      const SizedBox(height: 12),
      StatGrid(children: [
        StatTile(label: 'Tuân thủ thuốc đã xác nhận', value: fmtPct(adh.rate), hint: adh.due == 0 ? 'chưa có lịch' : '${adh.taken}/${adh.due} lần'),
        StatTile(label: 'Số ngày ghi nhật ký', value: '${d.hairLogs.where((l) => inRange(l.date, start, t)).length}'),
      ]),
      const SizedBox(height: 12),
      SectionCard(
        title: 'Mức rụng tóc tự đánh giá (TB theo tuần)',
        icon: Icons.show_chart,
        child: !hasData
            ? const EmptyState(icon: Icons.show_chart, title: 'Chưa có dữ liệu')
            : SimpleLineChart(labels: labels, series: [ChartSeries('Rụng tóc', cs.tertiary, shed)]),
      ),
      SectionCard(
        title: 'Tỷ lệ ngày làm routine tóc (%)',
        icon: Icons.bar_chart,
        child: !hasData
            ? const EmptyState(icon: Icons.bar_chart, title: 'Chưa có dữ liệu')
            : SimpleBarChart(values: routine, labels: labels, maxY: 100, yFormat: (v) => '${v.round()}%'),
      ),
      Text(
        'Thay đổi về tóc thường cần nhiều tháng mới đánh giá được. So sánh ảnh cùng góc, cùng ánh sáng ở tab "Ảnh" sau 4, 8, 12 tuần.',
        style: mutedStyle(context),
      ),
    ]);
  }
}
