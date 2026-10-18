import '../models/models.dart';

const String _t0 = '2026-01-01T00:00:00.000';

List<Habit> defaultHabits() {
  Habit h(String id, String title, String cat, int order, {String? time, bool important = false}) => Habit(
        id: id,
        title: title,
        category: cat,
        order: order,
        time: time,
        important: important,
        createdAt: _t0,
        updatedAt: _t0,
      );
  return [
    h('hb_wake', 'Thức dậy đúng giờ', 'sleep', 1, time: '07:00'),
    h('hb_breakfast', 'Ăn sáng đủ chất', 'nutrition', 2, time: '07:30', important: true),
    h('hb_water', 'Uống nước đều trong ngày', 'nutrition', 3),
    h('hb_workout', 'Hoàn thành buổi tập hoặc đi bộ theo kế hoạch', 'workout', 4, time: '18:00', important: true),
    h('hb_protein', 'Ăn đủ protein', 'nutrition', 5),
    h('hb_skin', 'Thực hiện routine chăm sóc da', 'skin', 6, time: '20:00', important: true),
    h('hb_hair', 'Thực hiện routine chăm sóc tóc theo kế hoạch đã xác nhận', 'hair', 7, time: '20:00'),
    h('hb_winddown', 'Chuẩn bị đi ngủ lúc 22:30', 'sleep', 8, time: '22:30'),
    h('hb_sleep', 'Ngủ trước 23:00', 'sleep', 9, time: '23:00', important: true),
  ];
}

List<ScheduleItem> defaultRoutine() => [
      ScheduleItem(id: 'rt_wake', time: '07:00', title: 'Thức dậy, uống nước, vệ sinh cá nhân', kind: 'wake'),
      ScheduleItem(id: 'rt_breakfast', time: '07:30', title: 'Ăn sáng', kind: 'meal'),
      ScheduleItem(
          id: 'rt_work', time: '08:00', endTime: '12:00', title: 'Làm việc, nghỉ vận động ngắn định kỳ', kind: 'work'),
      ScheduleItem(id: 'rt_lunch', time: '12:00', title: 'Ăn trưa', kind: 'meal'),
      ScheduleItem(id: 'rt_nap', time: '12:30', endTime: '13:00', title: 'Nghỉ trưa nếu có thể', kind: 'rest'),
      ScheduleItem(id: 'rt_snack', time: '15:30', title: 'Ăn phụ nếu đói', kind: 'meal'),
      ScheduleItem(
          id: 'rt_workout', time: '18:00', endTime: '18:45', title: 'Tập luyện theo lịch hoặc đi bộ', kind: 'workout'),
      ScheduleItem(id: 'rt_dinner', time: '19:00', title: 'Ăn tối', kind: 'meal'),
      ScheduleItem(id: 'rt_care', time: '20:00', title: 'Vệ sinh cá nhân, chăm sóc da và tóc theo routine', kind: 'care'),
      ScheduleItem(
          id: 'rt_winddown',
          time: '21:30',
          title: 'Giảm ánh sáng, hạn chế điện thoại và công việc căng thẳng',
          kind: 'winddown'),
      ScheduleItem(id: 'rt_bed', time: '22:30', title: 'Lên giường', kind: 'sleep'),
      ScheduleItem(id: 'rt_sleep', time: '23:00', title: 'Ngủ', kind: 'sleep'),
    ];

List<Exercise> defaultExercises() => [
      Exercise(
        id: 'ex_pushup',
        name: 'Chống đẩy',
        instructions:
            'Hai tay rộng hơn vai, thân thẳng từ đầu đến gót. Hạ ngực xuống gần sàn, khuỷu tay chếch khoảng 45°, rồi đẩy lên. Thở ra khi đẩy.',
        measure: 'reps',
        sets: 3,
        targetMin: 8,
        targetMax: 12,
        restSec: 75,
        difficulty: 'Trung bình',
        easierVersion: 'Chống đẩy tựa tay lên bàn/ghế chắc chắn hoặc chống gối.',
        gymAlternative: 'Đẩy ngực với máy (chest press) hoặc tạ đơn trên ghế phẳng.',
      ),
      Exercise(
        id: 'ex_squat',
        name: 'Squat',
        instructions:
            'Chân rộng bằng vai, mũi chân hơi mở. Đẩy hông ra sau như ngồi xuống ghế, lưng thẳng, gối đi theo hướng mũi chân. Đứng lên bằng lực cả bàn chân.',
        measure: 'reps',
        sets: 3,
        targetMin: 12,
        targetMax: 15,
        restSec: 75,
        difficulty: 'Dễ',
        easierVersion: 'Ngồi xuống – đứng lên từ ghế (box squat).',
        gymAlternative: 'Goblet squat với tạ đơn hoặc máy đạp chân (leg press).',
      ),
      Exercise(
        id: 'ex_row',
        name: 'Kéo ba lô có sách',
        instructions:
            'Cho sách vào ba lô. Gập người khoảng 45°, lưng thẳng, gối hơi chùng. Kéo ba lô về phía bụng, siết bả vai, hạ xuống có kiểm soát.',
        measure: 'reps',
        sets: 3,
        targetMin: 10,
        targetMax: 12,
        restSec: 75,
        difficulty: 'Dễ',
        easierVersion: 'Bớt sách trong ba lô hoặc kéo một tay, tay kia tựa ghế.',
        gymAlternative: 'Kéo cáp ngồi (seated row) hoặc kéo xà máy (lat pulldown).',
      ),
      Exercise(
        id: 'ex_plank',
        name: 'Plank',
        instructions: 'Chống cẳng tay dưới vai, thân thẳng, siết bụng và mông. Không võng lưng, không nhô hông. Thở đều.',
        measure: 'time',
        sets: 3,
        targetMin: 20,
        targetMax: 40,
        restSec: 60,
        difficulty: 'Trung bình',
        easierVersion: 'Plank chống gối, hoặc chia thành các lần 10–15 giây.',
      ),
      Exercise(
        id: 'ex_lunge',
        name: 'Lunge',
        instructions:
            'Bước một chân ra trước, hạ người đến khi hai gối gần vuông góc. Gối trước không đổ vào trong. Đẩy về vị trí cũ rồi đổi chân.',
        measure: 'reps',
        sets: 3,
        targetMin: 8,
        targetMax: 10,
        perSide: true,
        restSec: 75,
        difficulty: 'Trung bình',
        easierVersion: 'Split squat tại chỗ, vịn ghế/tường để giữ thăng bằng.',
        gymAlternative: 'Lunge với tạ đơn nhẹ.',
      ),
      Exercise(
        id: 'ex_bridge',
        name: 'Glute bridge',
        instructions:
            'Nằm ngửa, gập gối, bàn chân đặt trên sàn. Siết mông nâng hông đến khi thân và đùi thẳng hàng, giữ 1 giây rồi hạ xuống.',
        measure: 'reps',
        sets: 3,
        targetMin: 12,
        targetMax: 15,
        restSec: 60,
        difficulty: 'Dễ',
        easierVersion: 'Giảm biên độ nâng hông, giảm số lần.',
        gymAlternative: 'Hip thrust với tạ nhẹ.',
      ),
      Exercise(
        id: 'ex_sideplank',
        name: 'Plank nghiêng',
        instructions: 'Nằm nghiêng, chống cẳng tay dưới vai, nâng hông để thân thẳng. Giữ rồi đổi bên.',
        measure: 'time',
        sets: 2,
        targetMin: 20,
        targetMax: 30,
        perSide: true,
        restSec: 45,
        difficulty: 'Trung bình',
        easierVersion: 'Plank nghiêng chống gối.',
      ),
      Exercise(
        id: 'ex_brisk',
        name: 'Đi bộ nhanh',
        instructions: 'Đi với tốc độ thở hơi nhanh nhưng vẫn nói chuyện được. Có thể chia 2 lần 15–20 phút nếu bận.',
        measure: 'duration',
        sets: 1,
        targetMin: 30,
        targetMax: 40,
        restSec: 0,
        difficulty: 'Dễ',
        easierVersion: 'Đi bộ tốc độ thường 15–20 phút.',
        gymAlternative: 'Máy chạy bộ dốc nhẹ hoặc xe đạp tập.',
      ),
      Exercise(
        id: 'ex_cardio_mix',
        name: 'Đi bộ nhanh / đạp xe / chạy nhẹ',
        instructions: 'Chọn hình thức bạn thích. Giữ cường độ vừa phải, vẫn nói chuyện ngắt quãng được.',
        measure: 'duration',
        sets: 1,
        targetMin: 30,
        targetMax: 30,
        restSec: 0,
        difficulty: 'Dễ',
        easierVersion: 'Xen kẽ 2 phút đi nhanh – 1 phút đi chậm.',
        gymAlternative: 'Xe đạp tập, máy elliptical hoặc máy chạy bộ.',
      ),
      Exercise(
        id: 'ex_light_walk',
        name: 'Đi bộ thư giãn / hoạt động yêu thích',
        instructions: 'Đi bộ, đá bóng nhẹ, cầu lông… miễn là bạn thấy thoải mái.',
        measure: 'duration',
        sets: 1,
        targetMin: 30,
        targetMax: 45,
        restSec: 0,
        difficulty: 'Dễ',
        easierVersion: 'Đi bộ 15–20 phút.',
      ),
      Exercise(
        id: 'ex_stretch',
        name: 'Giãn cơ nhẹ',
        instructions: 'Giãn đùi trước/sau, hông, ngực, vai. Mỗi tư thế 20–30 giây, không gồng, không đau.',
        measure: 'duration',
        sets: 1,
        targetMin: 10,
        targetMax: 15,
        restSec: 0,
        difficulty: 'Dễ',
        easierVersion: 'Chỉ 5 phút giãn vùng cảm thấy cứng.',
      ),
    ];

WorkoutPlan defaultWorkoutPlan() => WorkoutPlan(
      id: 'plan_starter',
      name: 'Khởi đầu toàn thân',
      updatedAt: _t0,
      days: [
        WorkoutDay(
            weekday: 1, title: 'Toàn thân A', type: 'strength', exerciseIds: ['ex_pushup', 'ex_squat', 'ex_row', 'ex_plank']),
        WorkoutDay(weekday: 2, title: 'Cardio', type: 'cardio', exerciseIds: ['ex_brisk']),
        WorkoutDay(
            weekday: 3,
            title: 'Toàn thân B',
            type: 'strength',
            exerciseIds: ['ex_lunge', 'ex_bridge', 'ex_pushup', 'ex_row', 'ex_sideplank']),
        WorkoutDay(weekday: 4, title: 'Cardio', type: 'cardio', exerciseIds: ['ex_cardio_mix']),
        WorkoutDay(
            weekday: 5,
            title: 'Toàn thân A',
            type: 'strength',
            exerciseIds: ['ex_pushup', 'ex_squat', 'ex_row', 'ex_plank'],
            note: 'Điều chỉnh số hiệp và số lần theo thể lực.'),
        WorkoutDay(weekday: 6, title: 'Vận động nhẹ', type: 'light', exerciseIds: ['ex_light_walk']),
        WorkoutDay(
            weekday: 0,
            title: 'Nghỉ ngơi',
            type: 'rest',
            exerciseIds: ['ex_stretch'],
            note: 'Đi lại nhẹ nhàng, giãn cơ nếu cần.'),
      ],
    );

/// Số liệu kcal/protein là ƯỚC TÍNH thô cho khẩu phần thông thường, có thể sửa.
List<MealOption> defaultMealOptions() {
  MealOption m(String id, String slot, String name, int kcal, int p, List<String> ing, {bool cheap = true}) =>
      MealOption(id: id, slot: slot, name: name, kcal: kcal, proteinG: p, ingredients: ing, cheap: cheap);
  return [
    m('mo_b1', 'breakfast', '2 trứng + bánh mì nguyên cám + 1 quả chuối', 400, 18, ['Trứng gà', 'Bánh mì nguyên cám', 'Chuối']),
    m('mo_b2', 'breakfast', 'Yến mạch + sữa đậu nành không đường + trái cây', 350, 15,
        ['Yến mạch', 'Sữa đậu nành không đường', 'Trái cây']),
    m('mo_b3', 'breakfast', 'Phở/bún thịt nạc, thêm rau', 450, 22, ['Bánh phở/bún', 'Thịt nạc', 'Rau thơm'], cheap: false),
    m('mo_b4', 'breakfast', 'Bánh mì trứng ốp + dưa leo, cà chua', 400, 17, ['Bánh mì', 'Trứng gà', 'Dưa leo', 'Cà chua']),
    m('mo_l1', 'lunch', 'Cơm + cá kho + rau luộc + canh', 600, 30, ['Gạo', 'Cá', 'Rau xanh']),
    m('mo_l2', 'lunch', 'Cơm + gà luộc/xào + rau + canh', 620, 35, ['Gạo', 'Thịt gà', 'Rau xanh']),
    m('mo_l3', 'lunch', 'Cơm + đậu phụ sốt cà chua + trứng + rau', 580, 25,
        ['Gạo', 'Đậu phụ', 'Cà chua', 'Trứng gà', 'Rau xanh']),
    m('mo_l4', 'lunch', 'Cơm + thịt nạc rang + rau muống + canh', 620, 28, ['Gạo', 'Thịt nạc', 'Rau muống']),
    m('mo_s1', 'snack', 'Ổi hoặc cam + một nắm nhỏ hạt không tẩm đường', 200, 5, ['Ổi/Cam', 'Lạc/hạt không tẩm']),
    m('mo_s2', 'snack', 'Sữa chua không đường + chuối', 200, 8, ['Sữa chua không đường', 'Chuối']),
    m('mo_s3', 'snack', 'Khoai lang luộc + 1 quả trứng', 250, 9, ['Khoai lang', 'Trứng gà']),
    m('mo_s4', 'snack', 'Sữa đậu nành không đường + lạc rang', 220, 10, ['Sữa đậu nành không đường', 'Lạc']),
    m('mo_d1', 'dinner', 'Cơm + cá + canh rau', 550, 28, ['Gạo', 'Cá', 'Rau xanh']),
    m('mo_d2', 'dinner', 'Cơm + trứng chiên ít dầu + đậu phụ + rau', 560, 24, ['Gạo', 'Trứng gà', 'Đậu phụ', 'Rau xanh']),
    m('mo_d3', 'dinner', 'Cơm + thịt gà + canh bí', 580, 32, ['Gạo', 'Thịt gà', 'Bí xanh']),
    m('mo_d4', 'dinner', 'Bún/miến gà + rau', 450, 25, ['Bún/miến', 'Thịt gà', 'Rau thơm'], cheap: false),
  ];
}

/// Thông tin từ ĐƠN CŨ — chỉ để tham khảo. KHÔNG tự động thêm vào danh sách thuốc đang dùng.
class PriorRx {
  final String name;
  final String area;
  final String caution;
  const PriorRx(this.name, this.area, this.caution);
}

const List<PriorRx> priorPrescriptions = [
  PriorRx('Adapalene 0,1% (DIPALEN GEL)', 'skin',
      'Có thể gây khô, đỏ, bong tróc giai đoạn đầu. Chỉ dùng theo hướng dẫn hiện hành của bác sĩ; nếu đã ngừng lâu hoặc da đã thay đổi, hỏi lại bác sĩ trước khi dùng lại.'),
  PriorRx('CANOVA RIVESCAL DS', 'skin',
      'App không suy đoán thành phần hay cách dùng. Hãy xem nhãn sản phẩm và chỉ định của bác sĩ.'),
  PriorRx('Zinc gluconate 10 mg (CONIPA PURE)', 'skin', 'Chỉ dùng theo chỉ định hiện hành; không tự tăng liều.'),
  PriorRx('Minoxidil 5% (bôi)', 'hair',
      'Không tự tăng liều hoặc thay đổi tần suất. Ghi đúng cách dùng bác sĩ đang hướng dẫn.'),
  PriorRx('Finasteride 1 mg (uống)', 'hair',
      'Lịch dùng ghi trong đơn cũ có vẻ không phải lịch thông thường — hãy xác nhận lại với bác sĩ/dược sĩ. App không tự đổi sang dùng hằng ngày.'),
  PriorRx('Morr F5', 'hair',
      'Cần kiểm tra thành phần chính xác trên bao bì. Nếu có chứa finasteride, hỏi bác sĩ trước khi dùng cùng finasteride uống.'),
  PriorRx('Dầu gội Rudondo New', 'hair', 'Gội theo hướng dẫn trên nhãn/bác sĩ. Ghi lại tần suất gội bạn được dặn.'),
];

AppData createInitialData() => AppData(
      profile: UserProfile(),
      goals: Goals(),
      settings: AppSettings(),
      habits: defaultHabits(),
      completions: {},
      routine: DailyRoutine(items: defaultRoutine(), updatedAt: _t0),
      scheduleChecks: {},
      exercises: defaultExercises(),
      workoutPlan: defaultWorkoutPlan(),
      workoutSessions: [],
      workoutMoves: [],
      mealOptions: defaultMealOptions(),
      mealPlan: MealPlan(),
      mealLogs: [],
      water: {},
      shoppingChecked: {},
      careChecks: {},
      sleepLogs: [],
      skinLogs: [],
      hairLogs: [],
      medications: [],
      medLogs: {},
      photos: [],
      expenses: [],
    );

/// Đọc dữ liệu từ JSON, tự bổ sung trường còn thiếu bằng giá trị mặc định.
AppData appDataFromJson(Json j) {
  final d = createInitialData();
  List<T> orDefault<T>(String key, T Function(Json) f, List<T> def) => j[key] is List ? listOf(j[key], f) : def;
  return AppData(
    version: 1,
    profile: j['profile'] is Map ? UserProfile.fromJson(asJson(j['profile'])) : d.profile,
    goals: j['goals'] is Map ? Goals.fromJson(asJson(j['goals'])) : d.goals,
    settings: j['settings'] is Map ? AppSettings.fromJson(asJson(j['settings'])) : d.settings,
    habits: orDefault('habits', Habit.fromJson, d.habits),
    completions: mapOf(j['completions'], (v) => HabitCompletion.fromJson(asJson(v))),
    routine: j['routine'] is Map && asJson(j['routine'])['items'] is List
        ? DailyRoutine.fromJson(asJson(j['routine']))
        : d.routine,
    scheduleChecks: mapOf(j['scheduleChecks'], (v) => v == true),
    exercises: orDefault('exercises', Exercise.fromJson, d.exercises),
    workoutPlan: j['workoutPlan'] is Map && asJson(j['workoutPlan'])['days'] is List
        ? WorkoutPlan.fromJson(asJson(j['workoutPlan']))
        : d.workoutPlan,
    workoutSessions: listOf(j['workoutSessions'], WorkoutSession.fromJson),
    workoutMoves: listOf(j['workoutMoves'], WorkoutMove.fromJson),
    mealOptions: orDefault('mealOptions', MealOption.fromJson, d.mealOptions),
    mealPlan: j['mealPlan'] is Map ? MealPlan.fromJson(asJson(j['mealPlan'])) : d.mealPlan,
    mealLogs: listOf(j['mealLogs'], MealLog.fromJson),
    water: mapOf(j['water'], (v) => intV(v)),
    shoppingChecked: mapOf(j['shoppingChecked'], (v) => v == true),
    careChecks: mapOf(j['careChecks'], (v) => v == true),
    sleepLogs: listOf(j['sleepLogs'], SleepLog.fromJson),
    skinLogs: listOf(j['skinLogs'], SkinLog.fromJson),
    hairLogs: listOf(j['hairLogs'], HairLog.fromJson),
    medications: listOf(j['medications'], MedicationPlan.fromJson),
    medLogs: mapOf(j['medLogs'], (v) => MedicationAdherenceLog.fromJson(asJson(v))),
    photos: listOf(j['photos'], PhotoRecord.fromJson),
    expenses: listOf(j['expenses'], Expense.fromJson),
    priorRxAcknowledged: boolV(j['priorRxAcknowledged']),
  );
}
