// =====================================================================
// Kiểu dữ liệu của ứng dụng.
// Ngày địa phương luôn lưu dạng chuỗi 'yyyy-MM-dd' (LocalDate) để tránh
// lệch ngày do múi giờ. Giờ trong ngày lưu dạng 'HH:mm'.
// =====================================================================

typedef Json = Map<String, dynamic>;

// ---------------- JSON helpers ----------------
Json asJson(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<T> listOf<T>(dynamic v, T Function(Json) f) {
  if (v is! List) return <T>[];
  return v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList();
}

List<String> strList(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];
List<int> intList(dynamic v) => v is List ? v.whereType<num>().map((e) => e.toInt()).toList() : <int>[];
String str(dynamic v, [String d = '']) => v == null ? d : v.toString();
String? strN(dynamic v) => v?.toString();
int intV(dynamic v, [int d = 0]) => v is num ? v.toInt() : (int.tryParse('${v ?? ''}') ?? d);
int? intN(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
double dblV(dynamic v, [double d = 0]) => v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? d);
double? dblN(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
bool boolV(dynamic v, [bool d = false]) => v is bool ? v : d;

Map<String, T> mapOf<T>(dynamic v, T Function(dynamic) f) {
  if (v is! Map) return <String, T>{};
  final out = <String, T>{};
  v.forEach((k, val) => out[k.toString()] = f(val));
  return out;
}

String nowIso() => DateTime.now().toIso8601String();

// ---------------- Hồ sơ & mục tiêu ----------------
class UserProfile {
  String name;
  int? age;
  double? heightCm;
  double? weightKg;

  /// 'male' | 'female' | 'unspecified'
  String sex;

  /// 'muscle' | 'health' | 'skin' | 'hair' | 'balanced'
  List<String> goals;

  /// 'home' | 'gym' | 'mixed'
  String trainingLocation;

  /// 'muscle' | 'health' | 'balanced'
  String fitnessGoal;
  int workoutsPerWeek;

  /// 'sedentary' | 'light' | 'moderate' | 'active'
  String activityLevel;

  /// 'maintain' | 'gain' | 'lose'
  String nutritionGoal;
  String foodRestrictions;
  String usualSleepTime;
  String usualWakeTime;
  String skinRoutineNote;
  String hairRoutineNote;
  List<String> priorityHabits;
  String? onboardedAt;

  UserProfile({
    this.name = '',
    this.age = 23,
    this.heightCm = 172,
    this.weightKg = 64,
    this.sex = 'unspecified',
    List<String>? goals,
    this.trainingLocation = 'home',
    this.fitnessGoal = 'balanced',
    this.workoutsPerWeek = 3,
    this.activityLevel = 'light',
    this.nutritionGoal = 'maintain',
    this.foodRestrictions = '',
    this.usualSleepTime = '23:00',
    this.usualWakeTime = '07:00',
    this.skinRoutineNote = '',
    this.hairRoutineNote = '',
    List<String>? priorityHabits,
    this.onboardedAt,
  })  : goals = goals ?? ['balanced'],
        priorityHabits = priorityHabits ?? [];

  factory UserProfile.fromJson(Json j) {
    final d = UserProfile();
    return UserProfile(
      name: str(j['name']),
      age: j.containsKey('age') ? intN(j['age']) : d.age,
      heightCm: j.containsKey('heightCm') ? dblN(j['heightCm']) : d.heightCm,
      weightKg: j.containsKey('weightKg') ? dblN(j['weightKg']) : d.weightKg,
      sex: str(j['sex'], d.sex),
      goals: j['goals'] is List ? strList(j['goals']) : d.goals,
      trainingLocation: str(j['trainingLocation'], d.trainingLocation),
      fitnessGoal: str(j['fitnessGoal'], d.fitnessGoal),
      workoutsPerWeek: intV(j['workoutsPerWeek'], d.workoutsPerWeek),
      activityLevel: str(j['activityLevel'], d.activityLevel),
      nutritionGoal: str(j['nutritionGoal'], d.nutritionGoal),
      foodRestrictions: str(j['foodRestrictions']),
      usualSleepTime: str(j['usualSleepTime'], d.usualSleepTime),
      usualWakeTime: str(j['usualWakeTime'], d.usualWakeTime),
      skinRoutineNote: str(j['skinRoutineNote']),
      hairRoutineNote: str(j['hairRoutineNote']),
      priorityHabits: strList(j['priorityHabits']),
      onboardedAt: strN(j['onboardedAt']),
    );
  }

  Json toJson() => {
        'name': name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'sex': sex,
        'goals': goals,
        'trainingLocation': trainingLocation,
        'fitnessGoal': fitnessGoal,
        'workoutsPerWeek': workoutsPerWeek,
        'activityLevel': activityLevel,
        'nutritionGoal': nutritionGoal,
        'foodRestrictions': foodRestrictions,
        'usualSleepTime': usualSleepTime,
        'usualWakeTime': usualWakeTime,
        'skinRoutineNote': skinRoutineNote,
        'hairRoutineNote': hairRoutineNote,
        'priorityHabits': priorityHabits,
        'onboardedAt': onboardedAt,
      };
}

class Goals {
  String bedTime;
  String sleepTime;
  String wakeTime;
  double sleepHours;
  int waterGlasses;
  int? kcalOverride;
  int? proteinOverride;
  int monthlyBudget;
  int budgetWarnPercent;

  /// Số ngày giữa các lần gội theo hướng dẫn hiện hành (null = chưa đặt)
  int? hairWashEveryDays;

  Goals({
    this.bedTime = '22:30',
    this.sleepTime = '23:00',
    this.wakeTime = '07:00',
    this.sleepHours = 8,
    this.waterGlasses = 8,
    this.kcalOverride,
    this.proteinOverride,
    this.monthlyBudget = 1200000,
    this.budgetWarnPercent = 85,
    this.hairWashEveryDays,
  });

  factory Goals.fromJson(Json j) {
    final d = Goals();
    return Goals(
      bedTime: str(j['bedTime'], d.bedTime),
      sleepTime: str(j['sleepTime'], d.sleepTime),
      wakeTime: str(j['wakeTime'], d.wakeTime),
      sleepHours: dblV(j['sleepHours'], d.sleepHours),
      waterGlasses: intV(j['waterGlasses'], d.waterGlasses),
      kcalOverride: intN(j['kcalOverride']),
      proteinOverride: intN(j['proteinOverride']),
      monthlyBudget: intV(j['monthlyBudget'], d.monthlyBudget),
      budgetWarnPercent: intV(j['budgetWarnPercent'], d.budgetWarnPercent),
      hairWashEveryDays: intN(j['hairWashEveryDays']),
    );
  }

  Json toJson() => {
        'bedTime': bedTime,
        'sleepTime': sleepTime,
        'wakeTime': wakeTime,
        'sleepHours': sleepHours,
        'waterGlasses': waterGlasses,
        'kcalOverride': kcalOverride,
        'proteinOverride': proteinOverride,
        'monthlyBudget': monthlyBudget,
        'budgetWarnPercent': budgetWarnPercent,
        'hairWashEveryDays': hairWashEveryDays,
      };
}

class AppSettings {
  /// 'system' | 'light' | 'dark'
  String theme;
  AppSettings({this.theme = 'system'});
  factory AppSettings.fromJson(Json j) => AppSettings(theme: str(j['theme'], 'system'));
  Json toJson() => {'theme': theme};
}

// ---------------- Thói quen ----------------
class Habit {
  String id;
  String title;

  /// 'sleep' | 'nutrition' | 'workout' | 'skin' | 'hair' | 'other'
  String category;
  String? time;
  bool important;
  bool active;

  /// 0=CN..6=T7; rỗng = mọi ngày
  List<int> weekdays;
  int order;
  String createdAt;
  String updatedAt;

  Habit({
    required this.id,
    required this.title,
    required this.category,
    this.time,
    this.important = false,
    this.active = true,
    List<int>? weekdays,
    this.order = 0,
    String? createdAt,
    String? updatedAt,
  })  : weekdays = weekdays ?? [],
        createdAt = createdAt ?? nowIso(),
        updatedAt = updatedAt ?? nowIso();

  factory Habit.fromJson(Json j) => Habit(
        id: str(j['id']),
        title: str(j['title']),
        category: str(j['category'], 'other'),
        time: strN(j['time']),
        important: boolV(j['important']),
        active: boolV(j['active'], true),
        weekdays: intList(j['weekdays']),
        order: intV(j['order']),
        createdAt: strN(j['createdAt']),
        updatedAt: strN(j['updatedAt']),
      );

  Json toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'time': time,
        'important': important,
        'active': active,
        'weekdays': weekdays,
        'order': order,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class HabitCompletion {
  String id; // '$date:$habitId'
  String date;
  String habitId;

  /// 'done' | 'skipped' | 'na'
  String status;
  String updatedAt;

  HabitCompletion({required this.id, required this.date, required this.habitId, required this.status, String? updatedAt})
      : updatedAt = updatedAt ?? nowIso();

  factory HabitCompletion.fromJson(Json j) => HabitCompletion(
        id: str(j['id']),
        date: str(j['date']),
        habitId: str(j['habitId']),
        status: str(j['status'], 'done'),
        updatedAt: strN(j['updatedAt']),
      );

  Json toJson() => {'id': id, 'date': date, 'habitId': habitId, 'status': status, 'updatedAt': updatedAt};
}

// ---------------- Lịch sinh hoạt ----------------
class ScheduleItem {
  String id;
  String time;
  String? endTime;
  String title;

  /// 'wake' | 'meal' | 'work' | 'rest' | 'workout' | 'care' | 'winddown' | 'sleep' | 'other'
  String kind;

  ScheduleItem({required this.id, required this.time, this.endTime, required this.title, this.kind = 'other'});

  factory ScheduleItem.fromJson(Json j) => ScheduleItem(
        id: str(j['id']),
        time: str(j['time'], '07:00'),
        endTime: strN(j['endTime']),
        title: str(j['title']),
        kind: str(j['kind'], 'other'),
      );

  Json toJson() => {'id': id, 'time': time, 'endTime': endTime, 'title': title, 'kind': kind};

  ScheduleItem copy() => ScheduleItem(id: id, time: time, endTime: endTime, title: title, kind: kind);
}

/// Lịch sinh hoạt mặc định của người dùng
class DailyRoutine {
  List<ScheduleItem> items;
  String updatedAt;
  DailyRoutine({required this.items, String? updatedAt}) : updatedAt = updatedAt ?? nowIso();
  factory DailyRoutine.fromJson(Json j) =>
      DailyRoutine(items: listOf(j['items'], ScheduleItem.fromJson), updatedAt: strN(j['updatedAt']));
  Json toJson() => {'items': items.map((e) => e.toJson()).toList(), 'updatedAt': updatedAt};
}

// ---------------- Tập luyện ----------------
class Exercise {
  String id;
  String name;
  String instructions;

  /// 'reps' | 'time' (giây) | 'duration' (phút)
  String measure;
  int sets;
  int targetMin;
  int targetMax;
  bool perSide;
  int restSec;

  /// 'Dễ' | 'Trung bình' | 'Khó'
  String difficulty;
  String easierVersion;
  String? gymAlternative;

  Exercise({
    required this.id,
    required this.name,
    required this.instructions,
    required this.measure,
    required this.sets,
    required this.targetMin,
    required this.targetMax,
    this.perSide = false,
    required this.restSec,
    required this.difficulty,
    required this.easierVersion,
    this.gymAlternative,
  });

  factory Exercise.fromJson(Json j) => Exercise(
        id: str(j['id']),
        name: str(j['name']),
        instructions: str(j['instructions']),
        measure: str(j['measure'], 'reps'),
        sets: intV(j['sets'], 1),
        targetMin: intV(j['targetMin']),
        targetMax: intV(j['targetMax']),
        perSide: boolV(j['perSide']),
        restSec: intV(j['restSec']),
        difficulty: str(j['difficulty'], 'Dễ'),
        easierVersion: str(j['easierVersion']),
        gymAlternative: strN(j['gymAlternative']),
      );

  Json toJson() => {
        'id': id,
        'name': name,
        'instructions': instructions,
        'measure': measure,
        'sets': sets,
        'targetMin': targetMin,
        'targetMax': targetMax,
        'perSide': perSide,
        'restSec': restSec,
        'difficulty': difficulty,
        'easierVersion': easierVersion,
        'gymAlternative': gymAlternative,
      };

  String get unit => measure == 'reps' ? 'lần' : (measure == 'time' ? 'giây' : 'phút');

  String get targetText {
    final range = targetMin == targetMax ? '$targetMin' : '$targetMin–$targetMax';
    final side = perSide ? ' mỗi bên' : '';
    if (measure == 'duration') return '$range phút';
    return '$sets × $range $unit$side';
  }
}

class WorkoutDay {
  int weekday; // 0=CN..6=T7

  String title;

  /// 'strength' | 'cardio' | 'light' | 'rest'
  String type;
  List<String> exerciseIds;
  String? note;

  WorkoutDay({required this.weekday, required this.title, required this.type, required this.exerciseIds, this.note});

  factory WorkoutDay.fromJson(Json j) => WorkoutDay(
        weekday: intV(j['weekday']),
        title: str(j['title']),
        type: str(j['type'], 'rest'),
        exerciseIds: strList(j['exerciseIds']),
        note: strN(j['note']),
      );

  Json toJson() => {'weekday': weekday, 'title': title, 'type': type, 'exerciseIds': exerciseIds, 'note': note};
}

class WorkoutPlan {
  String id;
  String name;
  List<WorkoutDay> days;
  String updatedAt;
  WorkoutPlan({required this.id, required this.name, required this.days, String? updatedAt})
      : updatedAt = updatedAt ?? nowIso();

  factory WorkoutPlan.fromJson(Json j) => WorkoutPlan(
        id: str(j['id']),
        name: str(j['name']),
        days: listOf(j['days'], WorkoutDay.fromJson),
        updatedAt: strN(j['updatedAt']),
      );

  Json toJson() => {'id': id, 'name': name, 'days': days.map((e) => e.toJson()).toList(), 'updatedAt': updatedAt};
}

class SetLog {
  int? actual;
  bool done;
  SetLog({this.actual, this.done = false});
  factory SetLog.fromJson(Json j) => SetLog(actual: intN(j['actual']), done: boolV(j['done']));
  Json toJson() => {'actual': actual, 'done': done};
}

class ExerciseLog {
  String exerciseId;
  List<SetLog> sets;
  bool usedEasier;
  ExerciseLog({required this.exerciseId, required this.sets, this.usedEasier = false});
  factory ExerciseLog.fromJson(Json j) => ExerciseLog(
        exerciseId: str(j['exerciseId']),
        sets: listOf(j['sets'], SetLog.fromJson),
        usedEasier: boolV(j['usedEasier']),
      );
  Json toJson() => {'exerciseId': exerciseId, 'sets': sets.map((e) => e.toJson()).toList(), 'usedEasier': usedEasier};
}

class WorkoutSession {
  String id;
  String createdAt;
  String updatedAt;
  String date;
  int plannedWeekday;
  String title;
  String type;
  List<ExerciseLog> exercises;
  bool warmupDone;
  int? durationMin;
  int? feeling; // 1..5
  String note;
  bool completed;

  WorkoutSession({
    required this.id,
    String? createdAt,
    String? updatedAt,
    required this.date,
    required this.plannedWeekday,
    required this.title,
    required this.type,
    required this.exercises,
    this.warmupDone = false,
    this.durationMin,
    this.feeling,
    this.note = '',
    this.completed = false,
  })  : createdAt = createdAt ?? nowIso(),
        updatedAt = updatedAt ?? nowIso();

  factory WorkoutSession.fromJson(Json j) => WorkoutSession(
        id: str(j['id']),
        createdAt: strN(j['createdAt']),
        updatedAt: strN(j['updatedAt']),
        date: str(j['date']),
        plannedWeekday: intV(j['plannedWeekday']),
        title: str(j['title']),
        type: str(j['type'], 'strength'),
        exercises: listOf(j['exercises'], ExerciseLog.fromJson),
        warmupDone: boolV(j['warmupDone']),
        durationMin: intN(j['durationMin']),
        feeling: intN(j['feeling']),
        note: str(j['note']),
        completed: boolV(j['completed']),
      );

  Json toJson() => {
        'id': id,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'date': date,
        'plannedWeekday': plannedWeekday,
        'title': title,
        'type': type,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'warmupDone': warmupDone,
        'durationMin': durationMin,
        'feeling': feeling,
        'note': note,
        'completed': completed,
      };
}

/// Dời buổi tập của ngày [fromDate] sang [toDate]
class WorkoutMove {
  String id;
  String fromDate;
  String toDate;
  String createdAt;
  WorkoutMove({required this.id, required this.fromDate, required this.toDate, String? createdAt})
      : createdAt = createdAt ?? nowIso();
  factory WorkoutMove.fromJson(Json j) => WorkoutMove(
      id: str(j['id']), fromDate: str(j['fromDate']), toDate: str(j['toDate']), createdAt: strN(j['createdAt']));
  Json toJson() => {'id': id, 'fromDate': fromDate, 'toDate': toDate, 'createdAt': createdAt};
}

// ---------------- Dinh dưỡng ----------------
/// Món trong thư viện thực đơn. slot: 'breakfast' | 'lunch' | 'snack' | 'dinner'
class MealOption {
  String id;
  String slot;
  String name;
  int? kcal;
  int? proteinG;
  bool cheap;
  List<String> ingredients;

  MealOption({
    required this.id,
    required this.slot,
    required this.name,
    this.kcal,
    this.proteinG,
    this.cheap = true,
    List<String>? ingredients,
  }) : ingredients = ingredients ?? [];

  factory MealOption.fromJson(Json j) => MealOption(
        id: str(j['id']),
        slot: str(j['slot'], 'lunch'),
        name: str(j['name']),
        kcal: intN(j['kcal']),
        proteinG: intN(j['proteinG']),
        cheap: boolV(j['cheap'], true),
        ingredients: strList(j['ingredients']),
      );

  Json toJson() => {
        'id': id,
        'slot': slot,
        'name': name,
        'kcal': kcal,
        'proteinG': proteinG,
        'cheap': cheap,
        'ingredients': ingredients,
      };
}

/// Thực đơn theo ngày: date -> slot -> mealOptionId
class MealPlan {
  Map<String, Map<String, String>> byDate;
  MealPlan({Map<String, Map<String, String>>? byDate}) : byDate = byDate ?? {};
  factory MealPlan.fromJson(Json j) =>
      MealPlan(byDate: mapOf(j['byDate'], (v) => mapOf<String>(v, (x) => x.toString())));
  Json toJson() => {'byDate': byDate};
}

class MealLog {
  String id;
  String createdAt;
  String updatedAt;
  String date;
  String slot;
  String description;
  int? kcal;
  int? proteinG;
  int? costVnd;
  String? fromOptionId;

  MealLog({
    required this.id,
    String? createdAt,
    String? updatedAt,
    required this.date,
    required this.slot,
    required this.description,
    this.kcal,
    this.proteinG,
    this.costVnd,
    this.fromOptionId,
  })  : createdAt = createdAt ?? nowIso(),
        updatedAt = updatedAt ?? nowIso();

  factory MealLog.fromJson(Json j) => MealLog(
        id: str(j['id']),
        createdAt: strN(j['createdAt']),
        updatedAt: strN(j['updatedAt']),
        date: str(j['date']),
        slot: str(j['slot'], 'lunch'),
        description: str(j['description']),
        kcal: intN(j['kcal']),
        proteinG: intN(j['proteinG']),
        costVnd: intN(j['costVnd']),
        fromOptionId: strN(j['fromOptionId']),
      );

  Json toJson() => {
        'id': id,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'date': date,
        'slot': slot,
        'description': description,
        'kcal': kcal,
        'proteinG': proteinG,
        'costVnd': costVnd,
        'fromOptionId': fromOptionId,
      };
}

// ---------------- Giấc ngủ ----------------
class SleepLog {
  String id;
  String createdAt;
  String updatedAt;

  /// Ngày thức dậy
  String date;
  String bedTime;
  String sleepTime;
  String wakeTime;
  int quality; // 1..5
  String lateReason;

  SleepLog({
    required this.id,
    String? createdAt,
    String? updatedAt,
    required this.date,
    required this.bedTime,
    required this.sleepTime,
    required this.wakeTime,
    this.quality = 3,
    this.lateReason = '',
  })  : createdAt = createdAt ?? nowIso(),
        updatedAt = updatedAt ?? nowIso();

  factory SleepLog.fromJson(Json j) => SleepLog(
        id: str(j['id']),
        createdAt: strN(j['createdAt']),
        updatedAt: strN(j['updatedAt']),
        date: str(j['date']),
        bedTime: str(j['bedTime'], '22:30'),
        sleepTime: str(j['sleepTime'], '23:00'),
        wakeTime: str(j['wakeTime'], '07:00'),
        quality: intV(j['quality'], 3),
        lateReason: str(j['lateReason']),
      );

  Json toJson() => {
        'id': id,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'date': date,
        'bedTime': bedTime,
        'sleepTime': sleepTime,
        'wakeTime': wakeTime,
        'quality': quality,
        'lateReason': lateReason,
      };
}

// ---------------- Da ----------------
class SkinLog {
  String id;
  String createdAt;
  String updatedAt;
  String date;
  int oil;
  int acne;
  int irritation;
  int? newSpots;
  String productsUsed;
  bool morningDone;
  bool eveningDone;
  String note;

  SkinLog({
    required this.id,
    String? createdAt,
    String? updatedAt,
    required this.date,
    this.oil = 3,
    this.acne = 3,
    this.irritation = 1,
    this.newSpots,
    this.productsUsed = '',
    this.morningDone = false,
    this.eveningDone = false,
    this.note = '',
  })  : createdAt = createdAt ?? nowIso(),
        updatedAt = updatedAt ?? nowIso();

  factory SkinLog.fromJson(Json j) => SkinLog(
        id: str(j['id']),
        createdAt: strN(j['createdAt']),
        updatedAt: strN(j['updatedAt']),
        date: str(j['date']),
        oil: intV(j['oil'], 3),
        acne: intV(j['acne'], 3),
        irritation: intV(j['irritation'], 1),
        newSpots: intN(j['newSpots']),
        productsUsed: str(j['productsUsed']),
        morningDone: boolV(j['morningDone']),
        eveningDone: boolV(j['eveningDone']),
        note: str(j['note']),
      );

  Json toJson() => {
        'id': id,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'date': date,
        'oil': oil,
        'acne': acne,
        'irritation': irritation,
        'newSpots': newSpots,
        'productsUsed': productsUsed,
        'morningDone': morningDone,
        'eveningDone': eveningDone,
        'note': note,
      };
}

// ---------------- Tóc ----------------
class HairLog {
  String id;
  String createdAt;
  String updatedAt;
  String date;
  int shedding; // 1..5 tự đánh giá
  bool itch;
  bool redness;
  bool flaking;
  bool irritation;
  bool washed;
  bool routineDone;
  String note;

  HairLog({
    required this.id,
    String? createdAt,
    String? updatedAt,
    required this.date,
    this.shedding = 3,
    this.itch = false,
    this.redness = false,
    this.flaking = false,
    this.irritation = false,
    this.washed = false,
    this.routineDone = false,
    this.note = '',
  })  : createdAt = createdAt ?? nowIso(),
        updatedAt = updatedAt ?? nowIso();

  factory HairLog.fromJson(Json j) => HairLog(
        id: str(j['id']),
        createdAt: strN(j['createdAt']),
        updatedAt: strN(j['updatedAt']),
        date: str(j['date']),
        shedding: intV(j['shedding'], 3),
        itch: boolV(j['itch']),
        redness: boolV(j['redness']),
        flaking: boolV(j['flaking']),
        irritation: boolV(j['irritation']),
        washed: boolV(j['washed']),
        routineDone: boolV(j['routineDone']),
        note: str(j['note']),
      );

  Json toJson() => {
        'id': id,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'date': date,
        'shedding': shedding,
        'itch': itch,
        'redness': redness,
        'flaking': flaking,
        'irritation': irritation,
        'washed': washed,
        'routineDone': routineDone,
        'note': note,
      };
}

// ---------------- Thuốc ----------------
class MedicationPlan {
  String id;
  String createdAt;
  String updatedAt;
  String name;

  /// 'skin' | 'hair' | 'other'
  String area;

  /// Do người dùng tự ghi theo hướng dẫn hiện hành của bác sĩ
  String instructions;
  List<String> timesOfDay;

  /// 0..6; rỗng = mỗi ngày. Do người dùng nhập, app không tự đề xuất.
  List<int> weekdays;
  bool confirmedCurrent;
  String? confirmedAt;
  bool active;
  String prescribedBy;
  String note;

  MedicationPlan({
    required this.id,
    String? createdAt,
    String? updatedAt,
    required this.name,
    this.area = 'other',
    this.instructions = '',
    List<String>? timesOfDay,
    List<int>? weekdays,
    this.confirmedCurrent = false,
    this.confirmedAt,
    this.active = true,
    this.prescribedBy = '',
    this.note = '',
  })  : timesOfDay = timesOfDay ?? [],
        weekdays = weekdays ?? [],
        createdAt = createdAt ?? nowIso(),
        updatedAt = updatedAt ?? nowIso();

  factory MedicationPlan.fromJson(Json j) => MedicationPlan(
        id: str(j['id']),
        createdAt: strN(j['createdAt']),
        updatedAt: strN(j['updatedAt']),
        name: str(j['name']),
        area: str(j['area'], 'other'),
        instructions: str(j['instructions']),
        timesOfDay: strList(j['timesOfDay']),
        weekdays: intList(j['weekdays']),
        confirmedCurrent: boolV(j['confirmedCurrent']),
        confirmedAt: strN(j['confirmedAt']),
        active: boolV(j['active'], true),
        prescribedBy: str(j['prescribedBy']),
        note: str(j['note']),
      );

  Json toJson() => {
        'id': id,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'name': name,
        'area': area,
        'instructions': instructions,
        'timesOfDay': timesOfDay,
        'weekdays': weekdays,
        'confirmedCurrent': confirmedCurrent,
        'confirmedAt': confirmedAt,
        'active': active,
        'prescribedBy': prescribedBy,
        'note': note,
      };
}

class MedicationAdherenceLog {
  String id; // '$date:$medId:$time'
  String date;
  String medicationId;
  String time;

  /// 'taken' | 'missed' | 'skipped'
  String status;
  String updatedAt;

  MedicationAdherenceLog({
    required this.id,
    required this.date,
    required this.medicationId,
    required this.time,
    required this.status,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? nowIso();

  factory MedicationAdherenceLog.fromJson(Json j) => MedicationAdherenceLog(
        id: str(j['id']),
        date: str(j['date']),
        medicationId: str(j['medicationId']),
        time: str(j['time']),
        status: str(j['status'], 'taken'),
        updatedAt: strN(j['updatedAt']),
      );

  Json toJson() =>
      {'id': id, 'date': date, 'medicationId': medicationId, 'time': time, 'status': status, 'updatedAt': updatedAt};
}

// ---------------- Ảnh ----------------
/// area: 'skin' | 'hair'
/// angle: 'face-front' | 'face-left' | 'face-right' | 'hair-front' | 'hair-left' | 'hair-right' | 'hair-crown'
class PhotoRecord {
  String id;
  String createdAt;
  String updatedAt;
  String date;
  String area;
  String angle;

  /// Tên file trong thư mục ảnh của ứng dụng
  String fileName;
  String note;
  String lighting;

  PhotoRecord({
    required this.id,
    String? createdAt,
    String? updatedAt,
    required this.date,
    required this.area,
    required this.angle,
    required this.fileName,
    this.note = '',
    this.lighting = '',
  })  : createdAt = createdAt ?? nowIso(),
        updatedAt = updatedAt ?? nowIso();

  factory PhotoRecord.fromJson(Json j) => PhotoRecord(
        id: str(j['id']),
        createdAt: strN(j['createdAt']),
        updatedAt: strN(j['updatedAt']),
        date: str(j['date']),
        area: str(j['area'], 'skin'),
        angle: str(j['angle'], 'face-front'),
        fileName: str(j['fileName']),
        note: str(j['note']),
        lighting: str(j['lighting']),
      );

  Json toJson() => {
        'id': id,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'date': date,
        'area': area,
        'angle': angle,
        'fileName': fileName,
        'note': note,
        'lighting': lighting,
      };
}

// ---------------- Chi tiêu ----------------
/// category: 'food' | 'skincare' | 'haircare' | 'medicine' | 'equipment' | 'other'
class Expense {
  String id;
  String createdAt;
  String updatedAt;
  String date;
  int amount;
  String category;
  String title;
  bool essential;

  Expense({
    required this.id,
    String? createdAt,
    String? updatedAt,
    required this.date,
    required this.amount,
    required this.category,
    required this.title,
    this.essential = true,
  })  : createdAt = createdAt ?? nowIso(),
        updatedAt = updatedAt ?? nowIso();

  factory Expense.fromJson(Json j) => Expense(
        id: str(j['id']),
        createdAt: strN(j['createdAt']),
        updatedAt: strN(j['updatedAt']),
        date: str(j['date']),
        amount: intV(j['amount']),
        category: str(j['category'], 'other'),
        title: str(j['title']),
        essential: boolV(j['essential'], true),
      );

  Json toJson() => {
        'id': id,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'date': date,
        'amount': amount,
        'category': category,
        'title': title,
        'essential': essential,
      };
}

// ---------------- Báo cáo (tính toán, không lưu) ----------------
class WeeklyReport {
  final String start;
  final String end;
  final double? habitCompletionRate;
  final int workoutsDone;
  final int activeMinutes;
  final double? avgSleepHours;
  final double? onTimeSleepRate;
  final int sleepLogs;
  final int mealDaysLogged;
  final int daysElapsed;
  final double? avgOil;
  final double? avgAcne;
  final double? avgIrritation;
  final int skinLogs;
  final double? avgShedding;
  final int hairLogs;
  final double? hairRoutineRate;
  final double? medAdherenceRate;
  final int spent;

  const WeeklyReport({
    required this.start,
    required this.end,
    required this.habitCompletionRate,
    required this.workoutsDone,
    required this.activeMinutes,
    required this.avgSleepHours,
    required this.onTimeSleepRate,
    required this.sleepLogs,
    required this.mealDaysLogged,
    required this.daysElapsed,
    required this.avgOil,
    required this.avgAcne,
    required this.avgIrritation,
    required this.skinLogs,
    required this.avgShedding,
    required this.hairLogs,
    required this.hairRoutineRate,
    required this.medAdherenceRate,
    required this.spent,
  });
}

// ---------------- Toàn bộ dữ liệu ----------------
class AppData {
  int version;
  UserProfile profile;
  Goals goals;
  AppSettings settings;
  List<Habit> habits;
  Map<String, HabitCompletion> completions;
  DailyRoutine routine;

  /// '$date:$itemId' -> true
  Map<String, bool> scheduleChecks;
  List<Exercise> exercises;
  WorkoutPlan workoutPlan;
  List<WorkoutSession> workoutSessions;
  List<WorkoutMove> workoutMoves;
  List<MealOption> mealOptions;
  MealPlan mealPlan;
  List<MealLog> mealLogs;

  /// date -> số cốc nước
  Map<String, int> water;

  /// '$weekStart:$item' -> đã mua
  Map<String, bool> shoppingChecked;

  /// Routine chăm sóc: '$date:skin-am' | '$date:skin-pm' | '$date:hair' -> đã làm
  Map<String, bool> careChecks;
  List<SleepLog> sleepLogs;
  List<SkinLog> skinLogs;
  List<HairLog> hairLogs;
  List<MedicationPlan> medications;
  Map<String, MedicationAdherenceLog> medLogs;
  List<PhotoRecord> photos;
  List<Expense> expenses;
  bool priorRxAcknowledged;

  AppData({
    this.version = 1,
    required this.profile,
    required this.goals,
    required this.settings,
    required this.habits,
    required this.completions,
    required this.routine,
    required this.scheduleChecks,
    required this.exercises,
    required this.workoutPlan,
    required this.workoutSessions,
    required this.workoutMoves,
    required this.mealOptions,
    required this.mealPlan,
    required this.mealLogs,
    required this.water,
    required this.shoppingChecked,
    required this.careChecks,
    required this.sleepLogs,
    required this.skinLogs,
    required this.hairLogs,
    required this.medications,
    required this.medLogs,
    required this.photos,
    required this.expenses,
    this.priorRxAcknowledged = false,
  });

  Json toJson() => {
        'version': version,
        'profile': profile.toJson(),
        'goals': goals.toJson(),
        'settings': settings.toJson(),
        'habits': habits.map((e) => e.toJson()).toList(),
        'completions': completions.map((k, v) => MapEntry(k, v.toJson())),
        'routine': routine.toJson(),
        'scheduleChecks': scheduleChecks,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'workoutPlan': workoutPlan.toJson(),
        'workoutSessions': workoutSessions.map((e) => e.toJson()).toList(),
        'workoutMoves': workoutMoves.map((e) => e.toJson()).toList(),
        'mealOptions': mealOptions.map((e) => e.toJson()).toList(),
        'mealPlan': mealPlan.toJson(),
        'mealLogs': mealLogs.map((e) => e.toJson()).toList(),
        'water': water,
        'shoppingChecked': shoppingChecked,
        'careChecks': careChecks,
        'sleepLogs': sleepLogs.map((e) => e.toJson()).toList(),
        'skinLogs': skinLogs.map((e) => e.toJson()).toList(),
        'hairLogs': hairLogs.map((e) => e.toJson()).toList(),
        'medications': medications.map((e) => e.toJson()).toList(),
        'medLogs': medLogs.map((k, v) => MapEntry(k, v.toJson())),
        'photos': photos.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'priorRxAcknowledged': priorRxAcknowledged,
      };
}
