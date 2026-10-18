import 'package:flutter/material.dart';

import '../logic/date_utils.dart';
import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool month = false;
  String anchor = todayStr();

  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context).data;
    final r = month ? monthRange(anchor) : weekRange(anchor);
    final prevAnchor = month ? shiftMonth(anchor, -1) : shiftDate(anchor, -7);
    final pr = month ? monthRange(prevAnchor) : weekRange(prevAnchor);
    final rep = buildReport(d, r.start, r.end);
    final prev = buildReport(d, pr.start, pr.end);
    final days = eachDate(r.start, r.end);
    final t = todayStr();
    final cs = Theme.of(context).colorScheme;
    final byDateSkin = {for (final l in d.skinLogs) l.date: l};
    final byDateHair = {for (final l in d.hairLogs) l.date: l};
    final budget = d.goals.monthlyBudget;
    final sp = spendIn(d, r.start, r.end);

    String delta(num? cur, num? old, {bool pct = false, String unit = ''}) {
      if (cur == null || old == null) return '';
      final diff = cur - old;
      if (diff.abs() < 0.005) return 'như kỳ trước';
      final s = pct ? '${(diff * 100).round().abs()} điểm %' : '${fmtNum(diff.abs())}$unit';
      return '${diff > 0 ? '▲' : '▼'} $s so với kỳ trước';
    }

    return PageBody(children: [
      const PageHeader(title: 'Báo cáo', subtitle: 'Mọi số liệu tính từ dữ liệu bạn đã ghi'),
      SegmentedButton<bool>(
        segments: const [ButtonSegment(value: false, label: Text('Tuần')), ButtonSegment(value: true, label: Text('Tháng'))],
        selected: {month},
        onSelectionChanged: (s) => setState(() => month = s.first),
      ),
      Row(children: [
        IconButton(
            onPressed: () => setState(() => anchor = month ? shiftMonth(anchor, -1) : shiftDate(anchor, -7)),
            icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(month ? fmtMonth(anchor) : '${fmtDate(r.start)} – ${fmtDate(r.end)}',
              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        IconButton(
            onPressed: r.end.compareTo(t) >= 0
                ? null
                : () => setState(() => anchor = month ? shiftMonth(anchor, 1) : shiftDate(anchor, 7)),
            icon: const Icon(Icons.chevron_right)),
      ]),
      const InfoBanner(
        'Không có "điểm sức khỏe" tổng hợp — mỗi chỉ số được hiển thị riêng. Các mức da/tóc/giấc ngủ là tự đánh giá.',
        icon: Icons.info_outline,
      ),
      if (rep.daysElapsed == 0)
        const SectionCard(child: EmptyState(icon: Icons.insights, title: 'Khoảng thời gian này chưa bắt đầu'))
      else ...[
        SectionCard(
          title: 'Sức khỏe & thói quen',
          icon: Icons.favorite_outline,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            StatGrid(children: [
              StatTile(
                  label: 'Hoàn thành nhiệm vụ',
                  value: fmtPct(rep.habitCompletionRate),
                  hint: delta(rep.habitCompletionRate, prev.habitCompletionRate, pct: true)),
              StatTile(label: 'Buổi tập hoàn thành', value: '${rep.workoutsDone}', hint: delta(rep.workoutsDone, prev.workoutsDone)),
              StatTile(label: 'Thời lượng vận động', value: '${rep.activeMinutes} phút', hint: 'từ buổi tập đã ghi'),
              StatTile(
                  label: 'Ngủ trung bình',
                  value: fmtHours(rep.avgSleepHours),
                  hint: rep.sleepLogs == 0 ? 'chưa ghi' : '${rep.sleepLogs} đêm đã ghi'),
              StatTile(label: 'Ngủ đúng giờ', value: fmtPct(rep.onTimeSleepRate), hint: '≤15 phút so với ${d.goals.sleepTime}'),
              StatTile(
                  label: 'Ngày ghi đủ ≥3 bữa',
                  value: '${rep.mealDaysLogged}/${rep.daysElapsed}',
                  hint: 'mức độ duy trì chế độ ăn'),
            ]),
            const SizedBox(height: 16),
            Text('Tỷ lệ hoàn thành nhiệm vụ theo ngày', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SimpleBarChart(
              values: [
                for (final x in days)
                  x.compareTo(t) > 0 ? null : (dayProgress(d, x).rate == null ? null : dayProgress(d, x).rate! * 100),
              ],
              labels: [for (final x in days) month ? '${fromLocalDate(x).day}' : weekdayShort[weekdayOf(x)]],
              maxY: 100,
              goal: streakThreshold * 100,
              goalLabel: 'Ngưỡng duy trì 50%',
              yFormat: (v) => '${v.round()}%',
            ),
            const SizedBox(height: 16),
            Text('Thời lượng ngủ (giờ)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final byDate = {for (final l in d.sleepLogs) l.date: l};
              return SimpleBarChart(
                values: [
                  for (final x in days) byDate[x] == null ? null : sleepDurationHours(byDate[x]!.sleepTime, byDate[x]!.wakeTime),
                ],
                labels: [for (final x in days) month ? '${fromLocalDate(x).day}' : weekdayShort[weekdayOf(x)]],
                maxY: 12,
                goal: d.goals.sleepHours,
                goalLabel: 'Mục tiêu',
                color: cs.secondary,
                yFormat: (v) => '${v.round()}g',
              );
            }),
          ]),
        ),
        SectionCard(
          title: 'Da (tự đánh giá 1–5)',
          icon: Icons.face_outlined,
          subtitle: '${rep.skinLogs} ngày có ghi nhận',
          child: rep.skinLogs == 0
              ? const EmptyState(icon: Icons.face_outlined, title: 'Chưa có nhật ký da trong kỳ')
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  StatGrid(children: [
                    StatTile(label: 'Dầu TB', value: fmtNum(rep.avgOil), hint: delta(rep.avgOil, prev.avgOil)),
                    StatTile(label: 'Mụn TB', value: fmtNum(rep.avgAcne), hint: delta(rep.avgAcne, prev.avgAcne)),
                    StatTile(label: 'Kích ứng TB', value: fmtNum(rep.avgIrritation), hint: delta(rep.avgIrritation, prev.avgIrritation)),
                  ]),
                  const SizedBox(height: 12),
                  SimpleLineChart(
                    labels: [for (final x in days) fmtDayMonth(x)],
                    series: [
                      ChartSeries('Dầu', cs.primary, [for (final x in days) byDateSkin[x]?.oil.toDouble()]),
                      ChartSeries('Mụn', cs.tertiary, [for (final x in days) byDateSkin[x]?.acne.toDouble()]),
                      ChartSeries('Kích ứng', cs.error, [for (final x in days) byDateSkin[x]?.irritation.toDouble()]),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Xem ảnh so sánh theo thời gian ở mục Chăm sóc da → Ảnh.', style: mutedStyle(context)),
                ]),
        ),
        SectionCard(
          title: 'Tóc',
          icon: Icons.content_cut_outlined,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            StatGrid(children: [
              StatTile(label: 'Ngày làm routine tóc', value: fmtPct(rep.hairRoutineRate), hint: delta(rep.hairRoutineRate, prev.hairRoutineRate, pct: true)),
              StatTile(label: 'Tuân thủ thuốc đã xác nhận', value: fmtPct(rep.medAdherenceRate), hint: 'gồm cả thuốc da'),
              StatTile(label: 'Rụng tóc TB (tự đánh giá)', value: fmtNum(rep.avgShedding), hint: '${rep.hairLogs} ngày ghi'),
            ]),
            if (rep.hairLogs > 0) ...[
              const SizedBox(height: 12),
              SimpleLineChart(
                labels: [for (final x in days) fmtDayMonth(x)],
                series: [ChartSeries('Rụng tóc', cs.tertiary, [for (final x in days) byDateHair[x]?.shedding.toDouble()])],
              ),
            ],
            const SizedBox(height: 6),
            Text('So sánh ảnh cùng góc và ánh sáng ở mục Chăm sóc tóc → Ảnh.', style: mutedStyle(context)),
          ]),
        ),
        SectionCard(
          title: 'Ngân sách',
          icon: Icons.account_balance_wallet_outlined,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            StatGrid(children: [
              StatTile(label: 'Tổng chi', value: fmtVnd(rep.spent), hint: delta(rep.spent, prev.spent, unit: ' ₫')),
              if (month) StatTile(label: 'Còn lại so với ngân sách', value: fmtVnd(budget - rep.spent)),
              StatTile(label: 'Thiết yếu', value: fmtVnd(sp.essential)),
            ]),
            const SizedBox(height: 12),
            if (sp.total > 0)
              for (final e in expenseLabel.entries)
                if ((sp.byCat[e.key] ?? 0) > 0)
                  LabeledBar(label: e.value, valueText: fmtVnd(sp.byCat[e.key]), value: (sp.byCat[e.key] ?? 0) / sp.total),
          ]),
        ),
        _MiniTable(rep: rep, prev: prev),
      ],
    ]);
  }
}

class _MiniTable extends StatelessWidget {
  final WeeklyReport rep, prev;
  const _MiniTable({required this.rep, required this.prev});
  @override
  Widget build(BuildContext context) {
    Widget row(String k, String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(flex: 3, child: Text(k)),
            Expanded(flex: 2, child: Text(b, textAlign: TextAlign.right, style: mutedStyle(context))),
            Expanded(flex: 2, child: Text(a, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        );
    return SectionCard(
      title: 'So sánh với kỳ trước',
      icon: Icons.compare_arrows,
      child: Column(children: [
        row('', 'Kỳ này', 'Kỳ trước'),
        const Divider(),
        row('Hoàn thành nhiệm vụ', fmtPct(rep.habitCompletionRate), fmtPct(prev.habitCompletionRate)),
        row('Buổi tập', '${rep.workoutsDone}', '${prev.workoutsDone}'),
        row('Ngủ TB', fmtHours(rep.avgSleepHours), fmtHours(prev.avgSleepHours)),
        row('Ngủ đúng giờ', fmtPct(rep.onTimeSleepRate), fmtPct(prev.onTimeSleepRate)),
        row('Mụn TB', fmtNum(rep.avgAcne), fmtNum(prev.avgAcne)),
        row('Rụng tóc TB', fmtNum(rep.avgShedding), fmtNum(prev.avgShedding)),
        row('Chi tiêu', fmtVnd(rep.spent), fmtVnd(prev.spent)),
      ]),
    );
  }
}
