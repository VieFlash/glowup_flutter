import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/date_utils.dart';
import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

const _typeLabel = {'strength': 'Sức mạnh', 'cardio': 'Cardio', 'light': 'Vận động nhẹ', 'rest': 'Nghỉ'};
const _locLabel = {'home': 'Tại nhà', 'gym': 'Phòng gym', 'mixed': 'Kết hợp'};
const _goalLabel = {'muscle': 'Tăng cơ', 'health': 'Cải thiện sức khỏe', 'balanced': 'Vóc dáng cân đối'};

String sessionIdFor(String date, String sourceDate) => 'ws_${date}_$sourceDate';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});
  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  String date = todayStr();
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return PageBody(children: [
      const PageHeader(title: 'Tập luyện', subtitle: 'Bắt đầu nhẹ, tăng dần — làm được bao nhiêu ghi bấy nhiêu'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Buổi tập'), icon: Icon(Icons.play_circle_outline)),
            ButtonSegment(value: 1, label: Text('Kế hoạch'), icon: Icon(Icons.calendar_view_week)),
            ButtonSegment(value: 2, label: Text('Lịch sử'), icon: Icon(Icons.history)),
          ],
          selected: {tab},
          onSelectionChanged: (s) => setState(() => tab = s.first),
        ),
      ),
      const SizedBox(height: 12),
      if (tab == 0) ...[
        DateNavigator(date: date, onChanged: (v) => setState(() => date = v)),
        _SessionsForDate(date: date),
      ],
      if (tab == 1) const _PlanView(),
      if (tab == 2) const _HistoryView(),
    ]);
  }
}

// ============================================================================
// Buổi tập theo ngày
// ============================================================================

class _SessionsForDate extends StatelessWidget {
  final String date;
  const _SessionsForDate({required this.date});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final p = plannedWorkoutsFor(d, date);
    final future = date.compareTo(todayStr()) > 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const InfoBanner(
        'Khởi động 5–7 phút trước khi tập (xoay khớp, đi bộ tại chỗ, squat nhẹ). '
        'Dừng ngay nếu đau bất thường, chóng mặt, tức ngực hoặc khó thở không bình thường — nghỉ ngơi và hỏi ý kiến bác sĩ nếu triệu chứng kéo dài.',
        tone: Tone.warn,
        icon: Icons.health_and_safety_outlined,
      ),
      if (p.movedOutTo != null)
        SectionCard(
          child: Row(children: [
            Expanded(child: Text('Buổi tập của ngày này đã dời sang ${fmtLong(p.movedOutTo!)}.')),
            TextButton(
              onPressed: () => st.update((dd) => dd.workoutMoves.removeWhere((m) => m.fromDate == date)),
              child: const Text('Hoàn tác'),
            ),
          ]),
        ),
      if (p.items.isEmpty && p.movedOutTo == null)
        const SectionCard(child: EmptyState(icon: Icons.event_busy, title: 'Không có buổi tập theo kế hoạch')),
      for (final it in p.items)
        _SessionCard(date: date, planned: it, future: future, key: ValueKey(sessionIdFor(date, it.sourceDate))),
    ]);
  }
}

class _SessionCard extends StatelessWidget {
  final String date;
  final PlannedWorkout planned;
  final bool future;
  const _SessionCard({super.key, required this.date, required this.planned, required this.future});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final id = sessionIdFor(date, planned.sourceDate);
    WorkoutSession? session;
    for (final w in d.workoutSessions) {
      if (w.id == id) session = w;
    }
    final day = planned.day;
    final exercises = day.exerciseIds.map((e) => exerciseById(d, e)).whereType<Exercise>().toList();
    final loc = d.profile.trainingLocation;

    return SectionCard(
      title: day.title + (planned.movedIn ? ' (dời từ ${fmtDayMonth(planned.sourceDate)})' : ''),
      subtitle: [_typeLabel[day.type] ?? '', if (day.note != null) day.note!].join(' · '),
      icon: Icons.fitness_center,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (session?.completed == true) const Icon(Icons.check_circle, color: Colors.green),
        if (!planned.movedIn && session == null)
          IconButton(
            tooltip: 'Dời sang ngày khác',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => showMoveWorkoutDialog(context, date),
          ),
        if (planned.movedIn)
          IconButton(
            tooltip: 'Hủy dời lịch',
            icon: const Icon(Icons.undo),
            onPressed: () => st.update((dd) => dd.workoutMoves.removeWhere((m) => m.fromDate == planned.sourceDate)),
          ),
      ]),
      child: session == null
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final ex in exercises)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const Icon(Icons.circle, size: 6),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ex.name)),
                    Text(ex.targetText, style: mutedStyle(context)),
                  ]),
                ),
              const SizedBox(height: 8),
              if (future)
                Text('Buổi tập trong tương lai — có thể bắt đầu ghi khi đến ngày.', style: mutedStyle(context))
              else
                FilledButton.icon(
                  onPressed: () => st.update((dd) {
                    dd.workoutSessions.add(WorkoutSession(
                      id: id,
                      date: date,
                      plannedWeekday: day.weekday,
                      title: day.title,
                      type: day.type,
                      exercises: [
                        for (final ex in exercises)
                          ExerciseLog(exerciseId: ex.id, sets: List.generate(ex.sets, (_) => SetLog())),
                      ],
                    ));
                  }),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Bắt đầu ghi buổi tập'),
                ),
            ])
          : _SessionEditor(session: session, location: loc),
    );
  }
}

class _SessionEditor extends StatelessWidget {
  final WorkoutSession session;
  final String location;
  const _SessionEditor({required this.session, required this.location});

  void _mut(AppState st, void Function(WorkoutSession w) fn) {
    st.update((dd) {
      final w = dd.workoutSessions.firstWhere((x) => x.id == session.id);
      fn(w);
      w.updatedAt = nowIso();
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: session.warmupDone,
        onChanged: (v) => _mut(st, (w) => w.warmupDone = v == true),
        title: const Text('Đã khởi động 5–7 phút'),
      ),
      for (var i = 0; i < session.exercises.length; i++)
        Builder(builder: (context) {
          final el = session.exercises[i];
          final ex = exerciseById(d, el.exerciseId);
          if (ex == null) return const SizedBox();
          return _ExerciseBlock(
            ex: ex,
            log: el,
            location: location,
            hint: progressionHint(d, ex),
            onChange: (fn) => _mut(st, (w) => fn(w.exercises[i])),
          );
        }),
      const Divider(height: 24),
      Text('Sau buổi tập', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      _IntField(
        label: 'Thời lượng (phút, tùy chọn)',
        value: session.durationMin,
        onChanged: (v) => _mut(st, (w) => w.durationMin = v),
        max: 600,
      ),
      const SizedBox(height: 8),
      RatingSelector(
        label: 'Cảm nhận',
        value: session.feeling ?? 3,
        hints: const ['rất mệt', 'rất tốt'],
        onChanged: (v) => _mut(st, (w) => w.feeling = v),
      ),
      _NoteField(
        initial: session.note,
        onChanged: (v) => _mut(st, (w) => w.note = v),
      ),
      const SizedBox(height: 12),
      Row(children: [
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () async {
            final ok = await confirmDialog(context,
                title: 'Xóa bản ghi buổi tập?', message: 'Các số liệu đã ghi của buổi này sẽ bị xóa.', confirmText: 'Xóa', danger: true);
            if (ok) st.update((dd) => dd.workoutSessions.removeWhere((x) => x.id == session.id));
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Xóa'),
        ),
        const Spacer(),
        session.completed
            ? OutlinedButton.icon(
                onPressed: () => _mut(st, (w) => w.completed = false),
                icon: const Icon(Icons.edit),
                label: const Text('Mở lại'),
              )
            : FilledButton.icon(
                onPressed: () {
                  _mut(st, (w) => w.completed = true);
                  st.update((dd) => setHabitStatus(dd, session.date, 'hb_workout', 'done'));
                  showSnack(context, 'Đã lưu buổi tập. Làm tốt lắm!');
                },
                icon: const Icon(Icons.check),
                label: const Text('Hoàn thành buổi tập'),
              ),
      ]),
      if (!session.completed)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Không cần hoàn thành mọi hiệp — cứ đánh dấu hoàn thành với những gì bạn đã làm.',
              style: mutedStyle(context), textAlign: TextAlign.right),
        ),
    ]);
  }
}

class _ExerciseBlock extends StatefulWidget {
  final Exercise ex;
  final ExerciseLog log;
  final String location;
  final String? hint;
  final void Function(void Function(ExerciseLog l)) onChange;
  const _ExerciseBlock({required this.ex, required this.log, required this.location, required this.hint, required this.onChange});
  @override
  State<_ExerciseBlock> createState() => _ExerciseBlockState();
}

class _ExerciseBlockState extends State<_ExerciseBlock> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final ex = widget.ex;
    final log = widget.log;
    final cs = Theme.of(context).colorScheme;
    final doneSets = log.sets.where((s) => s.done).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: () => setState(() => expanded = !expanded),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ex.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  Tag(ex.targetText),
                  if (ex.restSec > 0) Tag('Nghỉ ${ex.restSec}s', color: cs.secondary),
                  Tag(ex.difficulty, color: cs.tertiary),
                  Tag('$doneSets/${log.sets.length} hiệp', color: cs.outline),
                ]),
              ]),
            ),
            Icon(expanded ? Icons.expand_less : Icons.expand_more),
          ]),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          Text(ex.instructions),
          const SizedBox(height: 6),
          Text('Phiên bản dễ hơn: ${ex.easierVersion}', style: mutedStyle(context)),
          if (widget.location != 'home' && ex.gymAlternative != null)
            Text('Tại phòng gym: ${ex.gymAlternative}', style: mutedStyle(context)),
        ],
        if (widget.hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InfoBanner(widget.hint!, tone: Tone.success, icon: Icons.trending_up),
          ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: log.usedEasier,
          onChanged: (v) => widget.onChange((l) => l.usedEasier = v),
          title: const Text('Dùng phiên bản dễ hơn'),
        ),
        for (var i = 0; i < log.sets.length; i++)
          _SetRow(
            index: i,
            set: log.sets[i],
            unit: ex.unit,
            hint: ex.targetMin == ex.targetMax ? '${ex.targetMin}' : '${ex.targetMin}–${ex.targetMax}',
            restSec: ex.restSec,
            onChanged: (actual, done) => widget.onChange((l) {
              l.sets[i].actual = actual;
              l.sets[i].done = done;
            }),
          ),
        Row(children: [
          TextButton.icon(
            onPressed: () => widget.onChange((l) => l.sets.add(SetLog())),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm hiệp'),
          ),
          if (log.sets.length > 1)
            TextButton.icon(
              onPressed: () => widget.onChange((l) => l.sets.removeLast()),
              icon: const Icon(Icons.remove, size: 18),
              label: const Text('Bớt hiệp'),
            ),
        ]),
      ]),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int index;
  final SetLog set;
  final String unit;
  final String hint;
  final int restSec;
  final void Function(int? actual, bool done) onChanged;
  const _SetRow({
    required this.index,
    required this.set,
    required this.unit,
    required this.hint,
    required this.restSec,
    required this.onChanged,
  });
  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController ctrl = TextEditingController(text: widget.set.actual?.toString() ?? '');
  String? err;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  int? _parse() {
    final t = ctrl.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 56, child: Text('Hiệp ${widget.index + 1}')),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: '${widget.hint} ${widget.unit}', errorText: err, suffixText: widget.unit),
            onChanged: (_) {
              final t = ctrl.text.trim();
              final v = _parse();
              if (t.isNotEmpty && (v == null || v < 0 || v > 1000)) {
                setState(() => err = 'Số không hợp lệ');
                return;
              }
              setState(() => err = null);
              widget.onChanged(v, widget.set.done || v != null);
            },
          ),
        ),
        Checkbox(
          value: widget.set.done,
          onChanged: (v) {
            widget.onChanged(_parse(), v == true);
            if (v == true && widget.restSec > 0) showRestTimer(context, widget.restSec);
          },
        ),
        if (widget.restSec > 0)
          IconButton(
            tooltip: 'Bấm giờ nghỉ',
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => showRestTimer(context, widget.restSec),
          ),
      ]),
    );
  }
}

// ============================================================================
// Bộ đếm giờ nghỉ
// ============================================================================

Future<void> showRestTimer(BuildContext context, int seconds) {
  return showDialog(context: context, builder: (_) => _RestTimerDialog(seconds: seconds));
}

class _RestTimerDialog extends StatefulWidget {
  final int seconds;
  const _RestTimerDialog({required this.seconds});
  @override
  State<_RestTimerDialog> createState() => _RestTimerDialogState();
}

class _RestTimerDialogState extends State<_RestTimerDialog> {
  late int total = widget.seconds;
  late int left = widget.seconds;
  Timer? timer;
  bool paused = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || paused) return;
      setState(() => left = left > 0 ? left - 1 : 0);
      if (left == 0) timer?.cancel();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mm = (left ~/ 60).toString().padLeft(2, '0');
    final ss = (left % 60).toString().padLeft(2, '0');
    return AlertDialog(
      title: const Text('Nghỉ giữa hiệp'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ProgressRing(
          value: total == 0 ? 0 : left / total,
          size: 140,
          center: Text(left == 0 ? 'Xong!' : '$mm:$ss', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          OutlinedButton(
            onPressed: () => setState(() {
              left += 15;
              total += 15;
              if (!(timer?.isActive ?? false)) _start();
            }),
            child: const Text('+15s'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: left == 0 ? null : () => setState(() => paused = !paused),
            child: Text(paused ? 'Tiếp tục' : 'Tạm dừng'),
          ),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(left == 0 ? 'Đóng' : 'Bỏ qua')),
      ],
    );
  }
}

// ============================================================================
// Dời buổi tập
// ============================================================================

Future<void> showMoveWorkoutDialog(BuildContext context, String fromDate) async {
  final st = AppScope.read(context);
  final existing = st.data.workoutMoves.where((m) => m.fromDate == fromDate).toList();
  if (existing.isNotEmpty) {
    final ok = await confirmDialog(context,
        title: 'Hủy dời lịch?',
        message: 'Buổi tập ngày ${fmtDate(fromDate)} đang được dời sang ${fmtDate(existing.first.toDate)}. Đưa về ngày cũ?',
        confirmText: 'Đưa về');
    if (ok) st.update((d) => d.workoutMoves.removeWhere((m) => m.fromDate == fromDate));
    return;
  }
  final day = workoutDayFor(st.data, weekdayOf(fromDate));
  if (day == null || !context.mounted) return;
  final to = await showDatePicker(
    context: context,
    helpText: 'Dời "${day.title}" sang ngày',
    initialDate: fromLocalDate(shiftDate(fromDate, 1)),
    firstDate: fromLocalDate(shiftDate(fromDate, -7)),
    lastDate: fromLocalDate(shiftDate(fromDate, 14)),
  );
  if (to == null) return;
  final toStr = toLocalDate(to);
  if (toStr == fromDate) return;
  st.update((d) => d.workoutMoves.add(WorkoutMove(id: uid('mv'), fromDate: fromDate, toDate: toStr)));
  if (context.mounted) showSnack(context, 'Đã dời "${day.title}" sang ${fmtDate(toStr)}');
}

// ============================================================================
// Kế hoạch tuần
// ============================================================================

class _PlanView extends StatelessWidget {
  const _PlanView();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final p = d.profile;
    final todayWd = weekdayOf(todayStr());
    final strengthDays = d.workoutPlan.days.where((x) => x.type == 'strength').length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(
        title: 'Tùy chỉnh',
        icon: Icons.tune,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Địa điểm tập'),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in _locLabel.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: p.trainingLocation == e.key,
                onSelected: (_) => st.update((dd) => dd.profile.trainingLocation = e.key),
              ),
          ]),
          const SizedBox(height: 12),
          const Text('Mục tiêu'),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in _goalLabel.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: p.fitnessGoal == e.key,
                onSelected: (_) => st.update((dd) => dd.profile.fitnessGoal = e.key),
              ),
          ]),
          const SizedBox(height: 12),
          const Text('Số buổi sức mạnh mỗi tuần'),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: const [ButtonSegment(value: 2, label: Text('2 buổi')), ButtonSegment(value: 3, label: Text('3 buổi'))],
            selected: {strengthDays >= 3 ? 3 : 2},
            onSelectionChanged: (s) => st.update((dd) {
              applyStrengthDays(dd, s.first);
              dd.profile.workoutsPerWeek = s.first;
            }),
          ),
          const SizedBox(height: 8),
          Text(
            p.fitnessGoal == 'muscle'
                ? 'Mục tiêu tăng cơ: ưu tiên tăng dần số lần/hiệp và ăn đủ protein; cardio giữ ở mức vừa phải.'
                : p.fitnessGoal == 'health'
                    ? 'Cải thiện sức khỏe: ưu tiên đều đặn, có thể đi bộ thêm vào ngày nghỉ.'
                    : 'Vóc dáng cân đối: kết hợp sức mạnh toàn thân và cardio vừa.',
            style: mutedStyle(context),
          ),
        ]),
      ),
      for (final wd in weekOrder)
        Builder(builder: (context) {
          final day = workoutDayFor(d, wd);
          if (day == null) return const SizedBox();
          final exs = day.exerciseIds.map((e) => exerciseById(d, e)).whereType<Exercise>();
          return SectionCard(
            title: '${weekdayLong[wd]} — ${day.title}',
            subtitle: _typeLabel[day.type],
            icon: wd == todayWd ? Icons.today : null,
            trailing: IconButton(
              tooltip: 'Sửa ngày tập',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editDay(context, wd),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final ex in exs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Expanded(child: Text('• ${ex.name}')),
                    Text(ex.targetText, style: mutedStyle(context)),
                  ]),
                ),
              if (day.note != null) Text(day.note!, style: mutedStyle(context)),
            ]),
          );
        }),
      SectionCard(
        title: 'Thư viện bài tập',
        icon: Icons.menu_book_outlined,
        subtitle: 'Chỉnh số hiệp/lần cho phù hợp thể lực',
        child: Column(children: [
          for (final ex in d.exercises)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(ex.name),
              subtitle: Text('${ex.targetText} · nghỉ ${ex.restSec}s · ${ex.difficulty}'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editExercise(context, ex),
            ),
        ]),
      ),
    ]);
  }

  Future<void> _editDay(BuildContext context, int wd) async {
    final st = AppScope.read(context);
    final day = workoutDayFor(st.data, wd)!;
    final title = TextEditingController(text: day.title);
    var type = day.type;
    final ids = [...day.exerciseIds];
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text('Sửa ${weekdayLong[wd]}', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Tên buổi')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Loại'),
                items: [for (final e in _typeLabel.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setS(() => type = v ?? type),
              ),
              const SizedBox(height: 12),
              const Text('Bài tập'),
              for (final ex in st.data.exercises)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: ids.contains(ex.id),
                  onChanged: (v) => setS(() {
                    if (v == true) {
                      ids.add(ex.id);
                    } else {
                      ids.remove(ex.id);
                    }
                  }),
                  title: Text(ex.name),
                ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                FilledButton(
                  onPressed: () {
                    st.update((dd) {
                      final x = workoutDayFor(dd, wd)!;
                      x.title = title.text.trim().isEmpty ? x.title : title.text.trim();
                      x.type = type;
                      x.exerciseIds = ids;
                      dd.workoutPlan.updatedAt = nowIso();
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

  Future<void> _editExercise(BuildContext context, Exercise ex) async {
    final st = AppScope.read(context);
    final sets = TextEditingController(text: '${ex.sets}');
    final mn = TextEditingController(text: '${ex.targetMin}');
    final mx = TextEditingController(text: '${ex.targetMax}');
    final rest = TextEditingController(text: '${ex.restSec}');
    String? err;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(ex.name),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: sets, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số hiệp')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: mn,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Tối thiểu (${ex.unit})'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: mx,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Tối đa (${ex.unit})'))),
              ]),
              const SizedBox(height: 8),
              TextField(
                  controller: rest, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nghỉ (giây)')),
              if (err != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(err!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                final s = int.tryParse(sets.text.trim());
                final a = int.tryParse(mn.text.trim());
                final b = int.tryParse(mx.text.trim());
                final r = int.tryParse(rest.text.trim());
                if (s == null || a == null || b == null || r == null || s < 1 || s > 10 || a < 1 || b < a || r < 0 || r > 600) {
                  setS(() => err = 'Kiểm tra lại: số hiệp 1–10, tối đa ≥ tối thiểu, nghỉ 0–600 giây.');
                  return;
                }
                st.update((dd) {
                  final x = dd.exercises.firstWhere((e) => e.id == ex.id);
                  x
                    ..sets = s
                    ..targetMin = a
                    ..targetMax = b
                    ..restSec = r;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Lịch sử
// ============================================================================

class _HistoryView extends StatelessWidget {
  const _HistoryView();
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final list = [...d.workoutSessions]..sort((a, b) => b.date.compareTo(a.date));
    final wk = weekRange(todayStr());
    final weekDone = list.where((w) => w.completed && inRange(w.date, wk.start, wk.end)).length;
    if (list.isEmpty) {
      return const SectionCard(
        child: EmptyState(
          icon: Icons.history,
          title: 'Chưa có buổi tập nào được ghi',
          message: 'Mở tab "Buổi tập" và nhấn "Bắt đầu ghi buổi tập".',
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      StatGrid(children: [
        StatTile(label: 'Hoàn thành tuần này', value: '$weekDone buổi'),
        StatTile(label: 'Tổng số buổi đã ghi', value: '${list.where((w) => w.completed).length}'),
      ]),
      const SizedBox(height: 12),
      for (final w in list)
        SectionCard(
          title: '${fmtDate(w.date)} — ${w.title}',
          subtitle: [
            w.completed ? 'Hoàn thành' : 'Chưa hoàn thành',
            if (sessionMinutes(w, d.exercises) > 0) '${sessionMinutes(w, d.exercises)} phút',
            if (w.feeling != null) 'Cảm nhận ${w.feeling}/5',
          ].join(' · '),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final el in w.exercises)
              Builder(builder: (context) {
                final ex = exerciseById(d, el.exerciseId);
                final vals = el.sets.where((s) => s.done).map((s) => s.actual?.toString() ?? '✓').join(' · ');
                return Text('${ex?.name ?? el.exerciseId}${el.usedEasier ? ' (dễ hơn)' : ''}: ${vals.isEmpty ? '—' : '$vals ${ex?.unit ?? ''}'}');
              }),
            if (w.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Ghi chú: ${w.note}', style: mutedStyle(context))),
          ]),
        ),
    ]);
  }
}

// ============================================================================
// Ô nhập dùng lại
// ============================================================================

class _IntField extends StatefulWidget {
  final String label;
  final int? value;
  final int max;
  final ValueChanged<int?> onChanged;
  const _IntField({required this.label, required this.value, required this.onChanged, this.max = 100000});
  @override
  State<_IntField> createState() => _IntFieldState();
}

class _IntFieldState extends State<_IntField> {
  late final TextEditingController c = TextEditingController(text: widget.value?.toString() ?? '');
  String? err;
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: widget.label, errorText: err),
        onChanged: (t) {
          try {
            final v = parseOptionalInt(t, max: widget.max);
            setState(() => err = null);
            widget.onChanged(v);
          } on FormatException {
            setState(() => err = 'Nhập số nguyên từ 0 đến ${widget.max}');
          }
        },
      );
}

class _NoteField extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onChanged;
  const _NoteField({required this.initial, required this.onChanged});
  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final TextEditingController c = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: c,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'Ghi chú cảm nhận (đau mỏi, năng lượng…)'),
        onChanged: widget.onChanged,
      );
}
