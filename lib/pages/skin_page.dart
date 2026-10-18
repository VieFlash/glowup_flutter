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
import '../widgets/routine_checklist.dart';

class SkinPage extends StatefulWidget {
  const SkinPage({super.key});
  @override
  State<SkinPage> createState() => _SkinPageState();
}

class _SkinPageState extends State<SkinPage> {
  int tab = 0;
  String date = todayStr();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    return PageBody(children: [
      const PageHeader(title: 'Chăm sóc da', subtitle: 'Routine đơn giản, đều đặn — theo dõi bằng dữ liệu'),
      if (!d.priorRxAcknowledged) const _ConfirmStatusCard(),
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
        _RoutineView(date: date),
        _SkinLogForm(date: date, key: ValueKey('skin-$date')),
      ],
      if (tab == 1) const _TrendView(),
      if (tab == 2) const PhotoTracker(area: 'skin'),
      if (tab == 3) const MedicationManager(area: 'skin'),
    ]);
  }
}

class _ConfirmStatusCard extends StatelessWidget {
  const _ConfirmStatusCard();
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return SectionCard(
      title: 'Xác nhận tình trạng hiện tại',
      icon: Icons.fact_check_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text(
          'Tình trạng ban đầu bạn mô tả: da tiết nhiều dầu, có mụn ở trán và má, có thâm sau mụn, bề mặt da chưa đều.\n\n'
          'App có lưu tên các thuốc từ đơn khám cũ (Adapalene 0,1%, CANOVA RIVESCAL DS, Zinc gluconate 10 mg) '
          'nhưng KHÔNG coi đó là phác đồ hiện tại. Bước "thuốc điều trị" trong routine tối chỉ hiện những gì bạn tự xác nhận '
          'ở tab "Thuốc".',
          style: TextStyle(height: 1.45),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(
            onPressed: () => st.update((d) => d.priorRxAcknowledged = true),
            child: const Text('Tôi đã hiểu'),
          ),
        ]),
      ]),
    );
  }
}

class _RoutineView extends StatelessWidget {
  final String date;
  const _RoutineView({required this.date});
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final skinMeds = d.medications.where((m) => m.area == 'skin' && medAppliesOn(m, date)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (d.profile.skinRoutineNote.isNotEmpty)
        InfoBanner('Routine hiện tại của bạn: ${d.profile.skinRoutineNote}', icon: Icons.notes),
      SectionCard(
        title: 'Buổi sáng',
        icon: Icons.wb_sunny_outlined,
        trailing: careDone(d, date, 'skin-am') ? const Icon(Icons.check_circle, color: Colors.green) : null,
        child: RoutineChecklist(date: date, routineKey: 'skin-am', steps: const [
          RoutineStep('clean', 'Làm sạch da nhẹ nhàng', 'Sữa rửa mặt dịu nhẹ, không chà xát mạnh'),
          RoutineStep('moist', 'Dưỡng ẩm', 'Kết cấu nhẹ, không gây bít tắc (non-comedogenic)'),
          RoutineStep('spf', 'Chống nắng phổ rộng SPF 30+', 'Thoa lại nếu ra ngoài lâu'),
        ]),
      ),
      SectionCard(
        title: 'Buổi tối',
        icon: Icons.nights_stay_outlined,
        trailing: careDone(d, date, 'skin-pm') ? const Icon(Icons.check_circle, color: Colors.green) : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          RoutineChecklist(date: date, routineKey: 'skin-pm', steps: [
            const RoutineStep('clean', 'Làm sạch da nhẹ nhàng'),
            RoutineStep(
              'treat',
              'Thuốc điều trị theo hướng dẫn hiện hành của bác sĩ',
              skinMeds.isEmpty
                  ? 'Chưa có thuốc nào được xác nhận cho hôm nay — có thể đánh dấu bước này là xong/bỏ qua.'
                  : skinMeds.map((m) => m.name).join(', '),
            ),
            const RoutineStep('moist', 'Dưỡng ẩm phù hợp'),
          ]),
          const InfoBanner('Không tự thêm nhiều hoạt chất mới cùng lúc. Thử từng sản phẩm một và theo dõi phản ứng.', tone: Tone.warn),
          if (skinMeds.isNotEmpty) MedsTodayList(area: 'skin', date: date),
        ]),
      ),
    ]);
  }
}

class _SkinLogForm extends StatefulWidget {
  final String date;
  const _SkinLogForm({super.key, required this.date});
  @override
  State<_SkinLogForm> createState() => _SkinLogFormState();
}

class _SkinLogFormState extends State<_SkinLogForm> {
  SkinLog? existing;
  int oil = 3, acne = 3, irritation = 1;
  final spots = TextEditingController();
  final products = TextEditingController();
  final note = TextEditingController();
  String? err;
  bool init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (init) return;
    init = true;
    final d = AppScope.read(context).data;
    for (final l in d.skinLogs) {
      if (l.date == widget.date) existing = l;
    }
    final e = existing;
    if (e != null) {
      oil = e.oil;
      acne = e.acne;
      irritation = e.irritation;
      spots.text = e.newSpots?.toString() ?? '';
      products.text = e.productsUsed;
      note.text = e.note;
    }
  }

  @override
  void dispose() {
    spots.dispose();
    products.dispose();
    note.dispose();
    super.dispose();
  }

  void _save() {
    final st = AppScope.read(context);
    int? ns;
    try {
      ns = parseOptionalInt(spots.text, max: 200);
    } on FormatException {
      setState(() => err = 'Số mụn mới phải là số nguyên 0–200');
      return;
    }
    setState(() => err = null);
    st.update((d) {
      final idx = d.skinLogs.indexWhere((l) => l.date == widget.date);
      if (idx < 0) {
        final l = SkinLog(
          id: uid('sk'),
          date: widget.date,
          oil: oil,
          acne: acne,
          irritation: irritation,
          newSpots: ns,
          productsUsed: products.text.trim(),
          note: note.text.trim(),
        );
        d.skinLogs.add(l);
        existing = l;
      } else {
        d.skinLogs[idx]
          ..oil = oil
          ..acne = acne
          ..irritation = irritation
          ..newSpots = ns
          ..productsUsed = products.text.trim()
          ..note = note.text.trim()
          ..updatedAt = nowIso();
      }
    });
    setState(() {});
    showSnack(context, 'Đã lưu nhật ký da ${fmtDate(widget.date)}');
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Nhật ký da',
      icon: Icons.edit_note,
      subtitle: existing == null ? 'Chưa ghi ngày này' : 'Đã ghi — chỉnh và lưu lại nếu cần',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        RatingSelector(label: 'Mức độ dầu', value: oil, hints: const ['ít', 'rất nhiều'], onChanged: (v) => setState(() => oil = v)),
        RatingSelector(label: 'Mức độ mụn', value: acne, hints: const ['ít', 'rất nhiều'], onChanged: (v) => setState(() => acne = v)),
        RatingSelector(
            label: 'Đỏ / kích ứng', value: irritation, hints: const ['không', 'rất nặng'], onChanged: (v) => setState(() => irritation = v)),
        if (irritation >= 4)
          const InfoBanner(
            'Kích ứng mạnh: tạm dừng sản phẩm mới, giữ routine tối giản (làm sạch dịu nhẹ + dưỡng ẩm) và liên hệ bác sĩ, '
            'nhất là khi sưng, rát nhiều, phồng rộp hoặc da xấu đi rõ rệt. Không tự thay đổi tần suất thuốc.',
            tone: Tone.danger,
          ),
        TextField(
          controller: spots,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số mụn mới (tùy chọn)'),
        ),
        const SizedBox(height: 12),
        TextField(controller: products, decoration: const InputDecoration(labelText: 'Sản phẩm đã dùng')),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Ghi chú (giấc ngủ, thực phẩm, yếu tố nghi ngờ…)',
            hintText: 'VD: uống sữa bò, ngủ muộn, căng thẳng…',
          ),
        ),
        if (err != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 12),
        Row(children: [
          if (existing != null)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () async {
                final ok = await confirmDialog(context,
                    title: 'Xóa nhật ký da?', message: 'Ngày ${fmtDate(widget.date)}', confirmText: 'Xóa', danger: true);
                if (!ok || !mounted) return;
                AppScope.read(context).update((d) => d.skinLogs.removeWhere((l) => l.date == widget.date));
                setState(() {
                  existing = null;
                  oil = 3;
                  acne = 3;
                  irritation = 1;
                  spots.clear();
                  products.clear();
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

class _TrendView extends StatefulWidget {
  const _TrendView();
  @override
  State<_TrendView> createState() => _TrendViewState();
}

class _TrendViewState extends State<_TrendView> {
  int days = 30;
  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context).data;
    final t = todayStr();
    final start = shiftDate(t, -(days - 1));
    final range = eachDate(start, t);
    final byDate = {for (final l in d.skinLogs) l.date: l};
    final logs = d.skinLogs.where((l) => inRange(l.date, start, t)).toList();
    final cs = Theme.of(context).colorScheme;
    // So sánh nửa đầu / nửa sau
    final half = shiftDate(start, days ~/ 2);
    double? a(Iterable<SkinLog> xs, int Function(SkinLog) f) => avg(xs.map(f));
    final first = logs.where((l) => l.date.compareTo(half) < 0);
    final second = logs.where((l) => l.date.compareTo(half) >= 0);
    String cmp(int Function(SkinLog) f) {
      final x = a(first, f), y = a(second, f);
      if (x == null || y == null) return 'chưa đủ dữ liệu';
      return '${fmtNum(x)} → ${fmtNum(y)}';
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 14, label: Text('14 ngày')),
          ButtonSegment(value: 30, label: Text('30 ngày')),
          ButtonSegment(value: 90, label: Text('90 ngày')),
        ],
        selected: {days},
        onSelectionChanged: (s) => setState(() => days = s.first),
      ),
      const SizedBox(height: 12),
      SectionCard(
        title: 'Xu hướng (tự đánh giá 1–5)',
        icon: Icons.show_chart,
        subtitle: '${logs.length} ngày có ghi nhận',
        child: logs.isEmpty
            ? const EmptyState(icon: Icons.show_chart, title: 'Chưa có dữ liệu', message: 'Ghi nhật ký da ở tab "Hôm nay".')
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SimpleLineChart(
                  labels: [for (final x in range) fmtDayMonth(x)],
                  series: [
                    ChartSeries('Dầu', cs.primary, [for (final x in range) byDate[x]?.oil.toDouble()]),
                    ChartSeries('Mụn', cs.tertiary, [for (final x in range) byDate[x]?.acne.toDouble()]),
                    ChartSeries('Kích ứng', cs.error, [for (final x in range) byDate[x]?.irritation.toDouble()]),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Trung bình nửa đầu → nửa sau giai đoạn:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('Dầu: ${cmp((l) => l.oil)}\nMụn: ${cmp((l) => l.acne)}\nKích ứng: ${cmp((l) => l.irritation)}'),
                const SizedBox(height: 8),
                Text('Đây là dữ liệu tự đánh giá, chỉ mang tính tham khảo. Thay đổi trên da thường cần vài tuần mới thấy rõ.',
                    style: mutedStyle(context)),
              ]),
      ),
    ]);
  }
}
