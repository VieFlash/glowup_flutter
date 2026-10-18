import '../models/models.dart';
import 'date_utils.dart';
import 'format.dart';

// =================== Thói quen ===================

bool habitAppliesOn(Habit h, String date) =>
    h.active && (h.weekdays.isEmpty || h.weekdays.contains(weekdayOf(date)));

List<Habit> habitsForDate(AppData s, String date) {
  final l = s.habits.where((h) => habitAppliesOn(h, date)).toList();
  l.sort((a, b) => a.order.compareTo(b.order));
  return l;
}

String completionKey(String date, String habitId) => '$date:$habitId';

String? habitStatus(AppData s, String date, String habitId) => s.completions[completionKey(date, habitId)]?.status;

class DayProgress {
  final int total, done, skipped, na;

  /// Mẫu số: nhiệm vụ áp dụng, không tính "không áp dụng" và "bỏ qua"
  final int counted;
  final double? rate;
  const DayProgress(this.total, this.done, this.skipped, this.na, this.counted, this.rate);
}

DayProgress dayProgress(AppData s, String date) {
  final hs = habitsForDate(s, date);
  var done = 0, skipped = 0, na = 0;
  for (final h in hs) {
    final st = habitStatus(s, date, h.id);
    if (st == 'done') {
      done++;
    } else if (st == 'skipped') {
      skipped++;
    } else if (st == 'na') {
      na++;
    }
  }
  final counted = hs.length - skipped - na;
  return DayProgress(hs.length, done, skipped, na, counted, counted > 0 ? done / counted : null);
}

/// Ngày "duy trì" = hoàn thành ít nhất 50% nhiệm vụ áp dụng.
const double streakThreshold = 0.5;

int currentStreak(AppData s, [String? from]) {
  bool ok(String d) {
    final p = dayProgress(s, d);
    return p.rate != null && p.rate! >= streakThreshold;
  }

  final start = from ?? todayStr();
  // Hôm nay chưa kết thúc: nếu chưa đạt thì bắt đầu đếm từ hôm qua.
  var d = ok(start) ? start : shiftDate(start, -1);
  var n = 0;
  for (var i = 0; i < 730 && ok(d); i++) {
    n++;
    d = shiftDate(d, -1);
  }
  return n;
}

double? rangeHabitRate(AppData s, String start, String end) {
  var done = 0, counted = 0;
  final t = todayStr();
  for (final d in eachDate(start, end)) {
    if (d.compareTo(t) > 0) break;
    final p = dayProgress(s, d);
    done += p.done;
    counted += p.counted;
  }
  return counted > 0 ? done / counted : null;
}

// =================== Tập luyện ===================

class PlannedWorkout {
  final WorkoutDay day;

  /// Ngày gốc trong kế hoạch (khác ngày hiện tại nếu đã dời)
  final String sourceDate;
  final bool movedIn;
  const PlannedWorkout(this.day, this.sourceDate, this.movedIn);
}

WorkoutDay? workoutDayFor(AppData s, int weekday) {
  for (final d in s.workoutPlan.days) {
    if (d.weekday == weekday) return d;
  }
  return null;
}

/// Buổi tập dự kiến của [date], đã tính các lần dời lịch.
({List<PlannedWorkout> items, String? movedOutTo}) plannedWorkoutsFor(AppData s, String date) {
  final items = <PlannedWorkout>[];
  WorkoutMove? moveOut;
  for (final m in s.workoutMoves) {
    if (m.fromDate == date) moveOut = m;
  }
  if (moveOut == null) {
    final day = workoutDayFor(s, weekdayOf(date));
    if (day != null) items.add(PlannedWorkout(day, date, false));
  }
  for (final m in s.workoutMoves.where((x) => x.toDate == date)) {
    final day = workoutDayFor(s, weekdayOf(m.fromDate));
    if (day != null) items.add(PlannedWorkout(day, m.fromDate, true));
  }
  return (items: items, movedOutTo: moveOut?.toDate);
}

List<WorkoutSession> sessionsOn(AppData s, String date) => s.workoutSessions.where((w) => w.date == date).toList();

Exercise? exerciseById(AppData s, String id) {
  for (final e in s.exercises) {
    if (e.id == id) return e;
  }
  return null;
}

int sessionMinutes(WorkoutSession w, List<Exercise> exercises) {
  if (w.durationMin != null && w.durationMin! > 0) return w.durationMin!;
  var m = 0;
  for (final el in w.exercises) {
    Exercise? ex;
    for (final e in exercises) {
      if (e.id == el.exerciseId) ex = e;
    }
    if (ex != null && ex.measure == 'duration') {
      for (final st in el.sets) {
        if (st.done) m += st.actual ?? 0;
      }
    }
  }
  return m;
}

/// Gợi ý tăng tiến: nếu 2 buổi gần nhất đều đạt mức tối đa ở mọi hiệp.
String? progressionHint(AppData s, Exercise ex) {
  final recent = s.workoutSessions.where((w) => w.completed && w.exercises.any((e) => e.exerciseId == ex.id)).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  if (recent.length < 2) return null;
  final allMax = recent.take(2).every((w) {
    final el = w.exercises.firstWhere((e) => e.exerciseId == ex.id);
    return !el.usedEasier &&
        el.sets.length >= ex.sets &&
        el.sets.every((st) => st.done && (st.actual ?? 0) >= ex.targetMax);
  });
  if (!allMax) return null;
  if (ex.measure == 'time') {
    return 'Bạn đã giữ tốt ${ex.targetMax} giây ở 2 buổi gần nhất. Có thể thử tăng 5–10 giây.';
  }
  if (ex.measure == 'duration') return 'Có thể thử tăng thêm 5 phút hoặc tăng nhẹ tốc độ.';
  return 'Bạn đạt ${ex.targetMax} lần ở mọi hiệp trong 2 buổi gần nhất. Có thể tăng 1–2 lần mỗi hiệp hoặc chuyển sang biến thể khó hơn.';
}

/// Điều chỉnh số buổi sức mạnh trong tuần (2 hoặc 3). Thứ 6 đổi giữa "Toàn thân A" và "Vận động nhẹ".
void applyStrengthDays(AppData s, int perWeek) {
  final fri = workoutDayFor(s, 5);
  if (fri == null) return;
  if (perWeek <= 2) {
    fri.title = 'Vận động nhẹ';
    fri.type = 'light';
    fri.exerciseIds = ['ex_light_walk'];
    fri.note = 'Bạn chọn 2 buổi sức mạnh/tuần — hôm nay vận động nhẹ.';
  } else {
    fri.title = 'Toàn thân A';
    fri.type = 'strength';
    fri.exerciseIds = ['ex_pushup', 'ex_squat', 'ex_row', 'ex_plank'];
    fri.note = 'Điều chỉnh số hiệp và số lần theo thể lực.';
  }
  s.workoutPlan.updatedAt = nowIso();
}

// =================== Dinh dưỡng ===================

const slots = ['breakfast', 'lunch', 'snack', 'dinner'];
const slotLabel = {'breakfast': 'Bữa sáng', 'lunch': 'Bữa trưa', 'snack': 'Bữa phụ', 'dinner': 'Bữa tối'};
const slotTime = {'breakfast': '07:30', 'lunch': '12:00', 'snack': '15:30', 'dinner': '19:00'};

class NutritionTarget {
  final int? kcal;
  final int? proteinG;
  final List<int>? proteinRange;
  final String method;
  final bool isEstimate;
  const NutritionTarget(this.kcal, this.proteinG, this.proteinRange, this.method, this.isEstimate);
}

const _activityFactor = {'sedentary': 1.2, 'light': 1.375, 'moderate': 1.55, 'active': 1.725};

/// Ước tính năng lượng bằng công thức Mifflin–St Jeor × hệ số vận động.
/// Protein: 1,2–1,6 g/kg (mục tiêu tăng cơ: 1,6–2,0 g/kg). Chỉ là ước tính, có thể ghi đè.
NutritionTarget nutritionTarget(AppData s) {
  final p = s.profile;
  final g = s.goals;
  int? kcal;
  List<int>? range;
  if (p.weightKg != null && p.heightCm != null && p.age != null) {
    final sexConst = p.sex == 'male' ? 5 : (p.sex == 'female' ? -161 : -78);
    final bmr = 10 * p.weightKg! + 6.25 * p.heightCm! - 5 * p.age! + sexConst;
    final adj = p.nutritionGoal == 'gain' ? 250 : (p.nutritionGoal == 'lose' ? -300 : 0);
    kcal = (((bmr * (_activityFactor[p.activityLevel] ?? 1.375)) + adj) / 10).round() * 10;
    final muscle = p.fitnessGoal == 'muscle' || p.nutritionGoal == 'gain';
    final lo = muscle ? 1.6 : 1.2;
    final hi = muscle ? 2.0 : 1.6;
    range = [(p.weightKg! * lo).round(), (p.weightKg! * hi).round()];
  }
  final protein = g.proteinOverride ?? (range == null ? null : ((range[0] + range[1]) / 2).round());
  final method = g.kcalOverride != null
      ? 'Mục tiêu do bạn tự đặt'
      : 'Ước tính theo Mifflin–St Jeor × hệ số vận động${p.sex == 'unspecified' ? ' (chưa chọn giới tính: dùng giá trị trung bình)' : ''}';
  return NutritionTarget(g.kcalOverride ?? kcal, protein, range, method, g.kcalOverride == null);
}

MealOption? mealOptionById(AppData s, String? id) {
  if (id == null) return null;
  for (final o in s.mealOptions) {
    if (o.id == id) return o;
  }
  return null;
}

/// Món dự kiến: lấy từ kế hoạch; nếu chưa chọn thì xoay vòng theo ngày để đỡ nhàm chán.
String? plannedMealId(AppData s, String date, String slot) {
  final chosen = s.mealPlan.byDate[date]?[slot];
  if (chosen != null && mealOptionById(s, chosen) != null) return chosen;
  final opts = s.mealOptions.where((o) => o.slot == slot).toList();
  if (opts.isEmpty) return null;
  final n = fromLocalDate(date).difference(DateTime(2024, 1, 1)).inDays.abs();
  return opts[n % opts.length].id;
}

class MealTotals {
  final int count;
  final int? kcal;
  final int? proteinG;
  final bool partial;
  final int cost;
  const MealTotals(this.count, this.kcal, this.proteinG, this.partial, this.cost);
}

MealTotals mealTotals(AppData s, String date) {
  final logs = s.mealLogs.where((m) => m.date == date).toList();
  final k = logs.where((l) => l.kcal != null).toList();
  final pr = logs.where((l) => l.proteinG != null).toList();
  return MealTotals(
    logs.length,
    k.isEmpty ? null : k.fold<int>(0, (a, l) => a + l.kcal!),
    pr.isEmpty ? null : pr.fold<int>(0, (a, l) => a + l.proteinG!),
    k.length < logs.length || pr.length < logs.length,
    logs.fold<int>(0, (a, l) => a + (l.costVnd ?? 0)),
  );
}

// =================== Giấc ngủ ===================

class SleepStats {
  final int count;
  final double? avgHours;
  final double? onTimeRate;
  final double? avgQuality;
  const SleepStats(this.count, this.avgHours, this.onTimeRate, this.avgQuality);
}

/// Ngủ "đúng giờ" = bắt đầu ngủ không trễ quá 15 phút so với mục tiêu.
bool sleptOnTime(AppData s, SleepLog l) => minutesLate(l.sleepTime, s.goals.sleepTime) <= 15;

SleepStats sleepStats(AppData s, String start, String end) {
  final logs = s.sleepLogs.where((l) => inRange(l.date, start, end)).toList();
  final onTime = logs.where((l) => sleptOnTime(s, l)).length;
  return SleepStats(
    logs.length,
    avg(logs.map((l) => sleepDurationHours(l.sleepTime, l.wakeTime))),
    logs.isEmpty ? null : onTime / logs.length,
    avg(logs.map((l) => l.quality)),
  );
}

/// Nếu thường ngủ muộn hơn mục tiêu > 45 phút: gợi ý mục tiêu trung gian sớm hơn 15–30 phút.
({int avgLateMin, String stepTarget})? sleepShiftSuggestion(AppData s) {
  final recent = [...s.sleepLogs]..sort((a, b) => b.date.compareTo(a.date));
  final last = recent.take(7).toList();
  double? lateMin;
  if (last.length >= 3) {
    lateMin = avg(last.map((l) => minutesLate(l.sleepTime, s.goals.sleepTime)));
  } else if (isValidHm(s.profile.usualSleepTime)) {
    lateMin = minutesLate(s.profile.usualSleepTime, s.goals.sleepTime).toDouble();
  }
  if (lateMin == null || lateMin <= 45) return null;
  final step = hmToMin(s.goals.sleepTime) + lateMin.round() - 20;
  return (avgLateMin: lateMin.round(), stepTarget: minToHm((step / 5).round() * 5));
}

// =================== Thuốc ===================

bool medAppliesOn(MedicationPlan m, String date) =>
    m.active && m.confirmedCurrent && (m.weekdays.isEmpty || m.weekdays.contains(weekdayOf(date)));

String medKey(String date, String medId, String time) => '$date:$medId:$time';

List<String> medTimes(MedicationPlan m) => m.timesOfDay.isEmpty ? ['--:--'] : m.timesOfDay;

({int due, int taken, double? rate}) medAdherence(AppData s, String start, String end, [String? area]) {
  var due = 0, taken = 0;
  final t = todayStr();
  for (final d in eachDate(start, end)) {
    if (d.compareTo(t) > 0) break;
    for (final m in s.medications) {
      if (area != null && m.area != area) continue;
      if (!medAppliesOn(m, d)) continue;
      if (m.confirmedAt != null && m.confirmedAt!.length >= 10 && d.compareTo(m.confirmedAt!.substring(0, 10)) < 0) {
        continue;
      }
      for (final time in medTimes(m)) {
        final st = s.medLogs[medKey(d, m.id, time)]?.status;
        if (st == 'skipped') continue;
        due++;
        if (st == 'taken') taken++;
      }
    }
  }
  return (due: due, taken: taken, rate: due == 0 ? null : taken / due);
}

// =================== Ngân sách ===================

const expenseLabel = {
  'food': 'Thực phẩm',
  'skincare': 'Chăm sóc da',
  'haircare': 'Chăm sóc tóc',
  'medicine': 'Thuốc theo đơn',
  'equipment': 'Dụng cụ tập',
  'other': 'Khác',
};

class SpendSummary {
  final int total, essential, nonEssential, count;
  final Map<String, int> byCat;
  const SpendSummary(this.total, this.essential, this.nonEssential, this.count, this.byCat);
}

SpendSummary spendIn(AppData s, String start, String end) {
  final items = s.expenses.where((e) => inRange(e.date, start, end));
  final byCat = <String, int>{};
  var ess = 0, non = 0, n = 0;
  for (final e in items) {
    byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
    if (e.essential) {
      ess += e.amount;
    } else {
      non += e.amount;
    }
    n++;
  }
  return SpendSummary(ess + non, ess, non, n, byCat);
}

// =================== Báo cáo ===================

WeeklyReport buildReport(AppData s, String start, String end) {
  final t = todayStr();
  final effectiveEnd = end.compareTo(t) > 0 ? t : end;
  final days = start.compareTo(effectiveEnd) > 0 ? 0 : eachDate(start, effectiveEnd).length;
  final sessions = s.workoutSessions.where((w) => w.completed && inRange(w.date, start, end)).toList();
  final sl = sleepStats(s, start, end);
  final skin = s.skinLogs.where((l) => inRange(l.date, start, end)).toList();
  final hair = s.hairLogs.where((l) => inRange(l.date, start, end)).toList();
  final mealDays = <String>{};
  final countByDay = <String, int>{};
  for (final m in s.mealLogs.where((m) => inRange(m.date, start, end))) {
    countByDay[m.date] = (countByDay[m.date] ?? 0) + 1;
  }
  countByDay.forEach((k, v) {
    if (v >= 3) mealDays.add(k);
  });
  return WeeklyReport(
    start: start,
    end: end,
    habitCompletionRate: rangeHabitRate(s, start, end),
    workoutsDone: sessions.length,
    activeMinutes: sessions.fold<int>(0, (a, w) => a + sessionMinutes(w, s.exercises)),
    avgSleepHours: sl.avgHours,
    onTimeSleepRate: sl.onTimeRate,
    sleepLogs: sl.count,
    mealDaysLogged: mealDays.length,
    daysElapsed: days,
    avgOil: avg(skin.map((l) => l.oil)),
    avgAcne: avg(skin.map((l) => l.acne)),
    avgIrritation: avg(skin.map((l) => l.irritation)),
    skinLogs: skin.length,
    avgShedding: avg(hair.map((l) => l.shedding)),
    hairLogs: hair.length,
    hairRoutineRate: days == 0
        ? null
        : eachDate(start, effectiveEnd).where((d) => s.careChecks['$d:hair'] == true).length / days,
    medAdherenceRate: medAdherence(s, start, end).rate,
    spent: spendIn(s, start, end).total,
  );
}

// =================== Routine chăm sóc ===================

bool careDone(AppData s, String date, String key) => s.careChecks['$date:$key'] == true;

/// Lần gội gần nhất (theo nhật ký tóc)
String? lastHairWash(AppData s, [String? upTo]) {
  final t = upTo ?? todayStr();
  String? best;
  for (final l in s.hairLogs) {
    if (l.washed && l.date.compareTo(t) <= 0 && (best == null || l.date.compareTo(best) > 0)) best = l.date;
  }
  return best;
}

// =================== Ghi nhãn ===================

const photoAngleLabel = {
  'face-front': 'Mặt – chính diện',
  'face-left': 'Mặt – bên trái',
  'face-right': 'Mặt – bên phải',
  'hair-front': 'Tóc – chính diện',
  'hair-left': 'Tóc – bên trái',
  'hair-right': 'Tóc – bên phải',
  'hair-crown': 'Tóc – đỉnh đầu',
};

const habitCategoryLabel = {
  'sleep': 'Giấc ngủ',
  'nutrition': 'Dinh dưỡng',
  'workout': 'Tập luyện',
  'skin': 'Da',
  'hair': 'Tóc',
  'other': 'Khác',
};

// =================== Thao tác ghi dữ liệu dùng chung ===================

/// Đặt trạng thái nhiệm vụ trong ngày; [status] = null để bỏ đánh dấu.
void setHabitStatus(AppData d, String date, String habitId, String? status) {
  final key = completionKey(date, habitId);
  if (status == null) {
    d.completions.remove(key);
  } else {
    d.completions[key] = HabitCompletion(id: key, date: date, habitId: habitId, status: status);
  }
}

void setCare(AppData d, String date, String key, bool v) {
  if (v) {
    d.careChecks['$date:$key'] = true;
  } else {
    d.careChecks.remove('$date:$key');
  }
  // Đồng bộ với nhiệm vụ trong ngày
  void sync(String habitId, bool done) {
    final cur = habitStatus(d, date, habitId);
    if (done && cur == null) setHabitStatus(d, date, habitId, 'done');
    if (!done && cur == 'done') setHabitStatus(d, date, habitId, null);
  }

  if (key == 'skin-am' || key == 'skin-pm') {
    sync('hb_skin', careDone(d, date, 'skin-am') && careDone(d, date, 'skin-pm'));
  } else if (key == 'hair') {
    sync('hb_hair', v);
  }
}

void setMedStatus(AppData d, String date, String medId, String time, String? status) {
  final key = medKey(date, medId, time);
  if (status == null) {
    d.medLogs.remove(key);
  } else {
    d.medLogs[key] = MedicationAdherenceLog(id: key, date: date, medicationId: medId, time: time, status: status);
  }
}
