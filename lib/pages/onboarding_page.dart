import 'package:flutter/material.dart';

import '../logic/date_utils.dart';
import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Thiết lập ngắn khi mở app lần đầu. Mọi câu đều có thể bỏ qua và sửa lại sau trong Cài đặt.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int step = 0;
  static const total = 11;

  late final AppData d0 = AppScope.read(context).data;
  late final name = TextEditingController(text: d0.profile.name);
  late Set<String> goals = {...d0.profile.goals};
  late String location = d0.profile.trainingLocation;
  late int perWeek = d0.profile.workoutsPerWeek.clamp(2, 3).toInt();
  late String wake = d0.profile.usualWakeTime;
  late String sleep = d0.profile.usualSleepTime;
  late final food = TextEditingController(text: d0.profile.foodRestrictions);
  late final budget = TextEditingController(text: '${d0.goals.monthlyBudget}');
  late final skin = TextEditingController(text: d0.profile.skinRoutineNote);
  late final hair = TextEditingController(text: d0.profile.hairRoutineNote);
  bool wantsMeds = false;
  late Set<String> priority = {...d0.profile.priorityHabits};
  String? err;

  @override
  void dispose() {
    for (final c in [name, food, budget, skin, hair]) {
      c.dispose();
    }
    super.dispose();
  }

  void _finish() {
    final b = parseMoney(budget.text);
    AppScope.read(context).update((d) {
      d.profile
        ..name = name.text.trim()
        ..goals = goals.isEmpty ? ['balanced'] : goals.toList()
        ..trainingLocation = location
        ..workoutsPerWeek = perWeek
        ..usualWakeTime = wake
        ..usualSleepTime = sleep
        ..foodRestrictions = food.text.trim()
        ..skinRoutineNote = skin.text.trim()
        ..hairRoutineNote = hair.text.trim()
        ..priorityHabits = priority.toList()
        ..fitnessGoal = goals.contains('muscle') ? 'muscle' : (goals.contains('health') ? 'health' : 'balanced')
        ..onboardedAt = nowIso();
      if (b != null && b > 0) d.goals.monthlyBudget = b;
      // Giờ thức mục tiêu: dùng giờ thức hiện tại nếu hợp lý (05:00–09:00)
      if (hmToMin(wake) >= 5 * 60 && hmToMin(wake) <= 9 * 60) {
        d.goals.wakeTime = wake;
        for (final h in d.habits) {
          if (h.id == 'hb_wake') h.time = wake;
        }
      }
      applyStrengthDays(d, perWeek);
      for (final h in d.habits) {
        if (priority.contains(h.id)) h.important = true;
      }
    });
  }

  void _next() {
    if (step == 5 && budget.text.trim().isNotEmpty && parseMoney(budget.text) == null) {
      setState(() => err = 'Số tiền không hợp lệ');
      return;
    }
    setState(() => err = null);
    if (step < total - 1) {
      setState(() => step++);
    } else {
      _finish();
    }
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) =>
      FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap());

  Widget _body(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (step) {
      case 0:
        return _Q(
          title: 'Chào bạn 👋',
          desc: 'Vài câu hỏi ngắn để thiết lập. Câu nào chưa muốn trả lời cứ bấm "Bỏ qua" — có thể sửa lại trong Cài đặt.\n\n'
              'Dữ liệu chỉ lưu trên máy này.',
          child: TextField(controller: name, decoration: const InputDecoration(labelText: 'Bạn muốn được gọi là gì? (tùy chọn)')),
        );
      case 1:
        const opts = {
          'muscle': 'Tăng cơ',
          'health': 'Cải thiện sức khỏe',
          'skin': 'Cải thiện da',
          'hair': 'Chăm sóc tóc',
          'balanced': 'Kết hợp',
        };
        return _Q(
          title: '1. Mục tiêu chính',
          desc: 'Chọn một hoặc nhiều.',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in opts.entries)
              _chip(e.value, goals.contains(e.key), () => setState(() => goals.contains(e.key) ? goals.remove(e.key) : goals.add(e.key))),
          ]),
        );
      case 2:
        return _Q(
          title: '2. Bạn tập ở đâu?',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in const {'home': 'Tại nhà', 'gym': 'Phòng gym', 'mixed': 'Kết hợp'}.entries)
              ChoiceChip(label: Text(e.value), selected: location == e.key, onSelected: (_) => setState(() => location = e.key)),
          ]),
        );
      case 3:
        return _Q(
          title: '3. Số buổi tập sức mạnh mỗi tuần',
          desc: 'Mới bắt đầu thì 2–3 buổi là đủ, kèm cardio nhẹ/vừa vào các ngày khác.',
          child: SegmentedButton<int>(
            segments: const [ButtonSegment(value: 2, label: Text('2 buổi')), ButtonSegment(value: 3, label: Text('3 buổi'))],
            selected: {perWeek},
            onSelectionChanged: (s) => setState(() => perWeek = s.first),
          ),
        );
      case 4:
        final lateMin = minutesLate(sleep, d0.goals.sleepTime);
        return _Q(
          title: '4. Giờ thức dậy & đi ngủ hiện tại',
          desc: 'Giờ thực tế bạn đang theo, không phải giờ lý tưởng.',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: TimeButton(label: 'Thường thức dậy', value: wake, onChanged: (v) => setState(() => wake = v))),
              const SizedBox(width: 8),
              Expanded(child: TimeButton(label: 'Thường đi ngủ', value: sleep, onChanged: (v) => setState(() => sleep = v))),
            ]),
            const SizedBox(height: 12),
            if (lateMin > 45)
              InfoBanner(
                'Bạn đang ngủ muộn hơn mục tiêu ${d0.goals.sleepTime} khoảng ${lateMin ~/ 60 > 0 ? '${lateMin ~/ 60} giờ ' : ''}${lateMin % 60} phút. '
                'App sẽ gợi ý dịch sớm dần 15–30 phút mỗi vài ngày thay vì thay đổi đột ngột.',
              ),
          ]),
        );
      case 5:
        return _Q(
          title: '5. Ngân sách chăm sóc bản thân / tháng',
          desc: 'Tham khảo 700.000–1.500.000 ₫.',
          child: TextField(
            controller: budget,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'VNĐ / tháng', suffixText: '₫', errorText: err),
          ),
        );
      case 6:
        return _Q(
          title: '6. Thực phẩm không thích, dị ứng hoặc hạn chế',
          child: TextField(controller: food, maxLines: 2, decoration: const InputDecoration(hintText: 'VD: không ăn được hải sản…')),
        );
      case 7:
        return _Q(
          title: '7. Routine chăm sóc da hiện tại',
          desc: 'Ghi những gì bạn đang làm thật sự. Không cần liệt kê thuốc ở đây.',
          child: TextField(controller: skin, maxLines: 3, decoration: const InputDecoration(hintText: 'VD: sáng rửa mặt + kem chống nắng…')),
        );
      case 8:
        return _Q(
          title: '8. Phác đồ chăm sóc tóc hiện tại đã được xác nhận',
          desc: 'Chỉ ghi những gì bác sĩ đang hướng dẫn bạn ở thời điểm hiện tại.',
          child: TextField(controller: hair, maxLines: 3, decoration: const InputDecoration(hintText: 'Để trống nếu chưa xác nhận')),
        );
      case 9:
        return _Q(
          title: '9. Quản lý thuốc trong app?',
          desc: 'App có ghi nhận tên thuốc từ các đơn khám cũ, nhưng KHÔNG tự đánh dấu là đang dùng. '
              'Bạn có thể thêm thuốc đang dùng (kèm cách dùng hiện hành) ở mục Chăm sóc da / tóc → Thuốc.',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: wantsMeds,
              onChanged: (v) => setState(() => wantsMeds = v),
              title: const Text('Có, tôi muốn theo dõi việc dùng thuốc'),
            ),
            if (wantsMeds)
              const InfoBanner(
                'Sau khi thiết lập xong, vào "Chăm sóc da" hoặc "Chăm sóc tóc" → tab "Thuốc" để thêm. '
                'Chỉ những mục bạn xác nhận mới xuất hiện trong nhắc nhở.',
                tone: Tone.success,
              ),
          ]),
        );
      default:
        final habits = [...d0.habits]..sort((a, b) => a.order.compareTo(b.order));
        return _Q(
          title: '10. Ưu tiên trong 30 ngày đầu',
          desc: 'Chọn 2–3 thói quen muốn tập trung. Chúng sẽ được đánh dấu "Quan trọng".',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final h in habits)
              FilterChip(
                label: Text(h.title),
                selected: priority.contains(h.id),
                selectedColor: cs.primaryContainer,
                onSelected: (v) => setState(() => v ? priority.add(h.id) : priority.remove(h.id)),
              ),
          ]),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Text('Thiết lập ${step + 1}/$total', style: mutedStyle(context)),
                  const Spacer(),
                  TextButton(onPressed: _finish, child: const Text('Bỏ qua tất cả')),
                ]),
                LinearProgressIndicator(value: (step + 1) / total),
                const SizedBox(height: 24),
                Expanded(child: SingleChildScrollView(child: _body(context))),
                Row(children: [
                  if (step > 0) TextButton(onPressed: () => setState(() => step--), child: const Text('Quay lại')),
                  const Spacer(),
                  if (step > 0 && step < total - 1)
                    TextButton(onPressed: () => setState(() => step++), child: const Text('Bỏ qua')),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _next, child: Text(step == total - 1 ? 'Bắt đầu' : 'Tiếp')),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Q extends StatelessWidget {
  final String title;
  final String? desc;
  final Widget child;
  const _Q({required this.title, this.desc, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      if (desc != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(desc!, style: const TextStyle(height: 1.45))),
      const SizedBox(height: 20),
      child,
    ]);
  }
}
