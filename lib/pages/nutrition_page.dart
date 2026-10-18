import 'package:flutter/material.dart';

import '../logic/date_utils.dart';
import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});
  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  int tab = 0;
  String date = todayStr();

  @override
  Widget build(BuildContext context) {
    return PageBody(children: [
      const PageHeader(title: 'Dinh dưỡng', subtitle: 'Ăn đủ, đa dạng, không ăn kiêng cực đoan'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Theo ngày')),
            ButtonSegment(value: 1, label: Text('Thực đơn tuần')),
            ButtonSegment(value: 2, label: Text('Thư viện món')),
            ButtonSegment(value: 3, label: Text('Hướng dẫn')),
          ],
          selected: {tab},
          onSelectionChanged: (s) => setState(() => tab = s.first),
        ),
      ),
      const SizedBox(height: 12),
      if (tab == 0) ...[
        DateNavigator(date: date, onChanged: (v) => setState(() => date = v)),
        _DayView(date: date),
      ],
      if (tab == 1) _WeekView(anchor: date),
      if (tab == 2) const _LibraryView(),
      if (tab == 3) const _GuideView(),
    ]);
  }
}

// ============================================================================
// Theo ngày
// ============================================================================

class _DayView extends StatelessWidget {
  final String date;
  const _DayView({required this.date});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final target = nutritionTarget(d);
    final totals = mealTotals(d, date);
    final water = d.water[date] ?? 0;
    final logs = d.mealLogs.where((m) => m.date == date).toList()
      ..sort((a, b) => slots.indexOf(a.slot).compareTo(slots.indexOf(b.slot)));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(
        title: 'Tổng trong ngày',
        icon: Icons.donut_large,
        subtitle: 'Số liệu từ bữa ăn bạn ghi — đều là ƯỚC TÍNH',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LabeledBar(
            label: 'Năng lượng',
            valueText: '${totals.kcal == null ? '—' : '~${totals.kcal}'} / ${target.kcal == null ? '—' : '~${target.kcal}'} kcal',
            value: totals.kcal == null || target.kcal == null ? 0 : totals.kcal! / target.kcal!,
          ),
          LabeledBar(
            label: 'Protein',
            valueText: '${totals.proteinG == null ? '—' : '~${totals.proteinG}'} / ${target.proteinG == null ? '—' : '~${target.proteinG}'} g',
            value: totals.proteinG == null || target.proteinG == null ? 0 : totals.proteinG! / target.proteinG!,
          ),
          if (totals.partial)
            Text('Một số bữa chưa có số liệu nên tổng có thể thấp hơn thực tế.', style: mutedStyle(context)),
          Text(target.method, style: mutedStyle(context)?.copyWith(fontSize: 11)),
          if (target.proteinRange != null && d.goals.proteinOverride == null)
            Text('Protein tham khảo: ${target.proteinRange![0]}–${target.proteinRange![1]} g/ngày.',
                style: mutedStyle(context)?.copyWith(fontSize: 11)),
          Text('Điều chỉnh theo cảm giác đói/no và mức vận động thực tế. Có thể tự đặt mục tiêu trong Cài đặt.',
              style: mutedStyle(context)?.copyWith(fontSize: 11)),
          if (totals.cost > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Chi phí ăn uống đã ghi: ${fmtVnd(totals.cost)}'),
            ),
        ]),
      ),
      SectionCard(
        title: 'Nước uống',
        icon: Icons.water_drop_outlined,
        subtitle: 'Mục tiêu ${d.goals.waterGlasses} cốc (~250 ml/cốc)',
        child: Row(children: [
          IconButton.filledTonal(
            onPressed: water > 0 ? () => st.update((dd) => dd.water[date] = water - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Column(children: [
              Text('$water / ${d.goals.waterGlasses}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: (water / (d.goals.waterGlasses == 0 ? 1 : d.goals.waterGlasses)).clamp(0.0, 1.0)),
            ]),
          ),
          IconButton.filled(
            onPressed: () => st.update((dd) {
              dd.water[date] = water + 1;
              if (water + 1 >= dd.goals.waterGlasses) setHabitStatus(dd, date, 'hb_water', 'done');
            }),
            icon: const Icon(Icons.add),
          ),
        ]),
      ),
      SectionCard(
        title: 'Thực đơn dự kiến',
        icon: Icons.menu_book_outlined,
        subtitle: 'Nhấn "Đổi món" để thay; "Đã ăn" để ghi nhanh',
        child: Column(children: [
          for (final s in slots)
            Builder(builder: (context) {
              final opt = mealOptionById(d, plannedMealId(d, date, s));
              final logged = logs.any((l) => l.slot == s);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 74,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(slotLabel[s]!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(slotTime[s]!, style: mutedStyle(context)),
                    ]),
                  ),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(opt?.name ?? 'Chưa có món'),
                      if (opt != null && (opt.kcal != null || opt.proteinG != null))
                        Text('~${opt.kcal ?? '?'} kcal · ~${opt.proteinG ?? '?'} g protein (ước tính)', style: mutedStyle(context)),
                      Wrap(spacing: 4, children: [
                        TextButton(
                          onPressed: () => _chooseOption(context, date, s),
                          child: const Text('Đổi món'),
                        ),
                        if (opt != null)
                          logged
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text('✓ Đã ghi'),
                                )
                              : TextButton(
                                  onPressed: () => st.update((dd) {
                                    dd.mealLogs.add(MealLog(
                                      id: uid('ml'),
                                      date: date,
                                      slot: s,
                                      description: opt.name,
                                      kcal: opt.kcal,
                                      proteinG: opt.proteinG,
                                      fromOptionId: opt.id,
                                    ));
                                    if (s == 'breakfast') setHabitStatus(dd, date, 'hb_breakfast', 'done');
                                  }),
                                  child: const Text('Đã ăn'),
                                ),
                      ]),
                    ]),
                  ),
                ]),
              );
            }),
        ]),
      ),
      SectionCard(
        title: 'Bữa ăn đã ghi',
        icon: Icons.edit_note,
        trailing: FilledButton.tonalIcon(
          onPressed: () => showMealLogEditor(context, date, null),
          icon: const Icon(Icons.add),
          label: const Text('Ghi bữa'),
        ),
        child: logs.isEmpty
            ? const EmptyState(icon: Icons.restaurant, title: 'Chưa ghi bữa nào', message: 'Ghi lại những gì bạn thực sự ăn.')
            : Column(children: [
                for (final l in logs)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.description),
                    subtitle: Text([
                      slotLabel[l.slot] ?? '',
                      if (l.kcal != null) '~${l.kcal} kcal',
                      if (l.proteinG != null) '~${l.proteinG} g protein',
                      if (l.costVnd != null) fmtVnd(l.costVnd),
                    ].join(' · ')),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => showMealLogEditor(context, date, l),
                  ),
              ]),
      ),
    ]);
  }

  Future<void> _chooseOption(BuildContext context, String date, String slot) async {
    final st = AppScope.read(context);
    final opts = st.data.mealOptions.where((o) => o.slot == slot).toList();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Chọn món cho ${slotLabel[slot]!.toLowerCase()}', style: Theme.of(ctx).textTheme.titleMedium),
          ),
          for (final o in opts)
            ListTile(
              title: Text(o.name),
              subtitle: Text('~${o.kcal ?? '?'} kcal · ~${o.proteinG ?? '?'} g protein${o.cheap ? ' · Giá rẻ' : ''}'),
              onTap: () => Navigator.pop(ctx, o.id),
            ),
          if (opts.isEmpty) const ListTile(title: Text('Chưa có món nào trong thư viện cho bữa này.')),
        ],
      ),
    );
    if (chosen == null) return;
    st.update((dd) {
      dd.mealPlan.byDate.putIfAbsent(date, () => {})[slot] = chosen;
    });
  }
}

Future<void> showMealLogEditor(BuildContext context, String date, MealLog? log) async {
  final st = AppScope.read(context);
  var slot = log?.slot ?? 'lunch';
  final desc = TextEditingController(text: log?.description ?? '');
  final kcal = TextEditingController(text: log?.kcal?.toString() ?? '');
  final prot = TextEditingController(text: log?.proteinG?.toString() ?? '');
  final cost = TextEditingController(text: log?.costVnd?.toString() ?? '');
  String? err;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Text(log == null ? 'Ghi bữa ăn' : 'Sửa bữa ăn', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [for (final s in slots) ButtonSegment(value: s, label: Text(slotLabel[s]!.replaceAll('Bữa ', '')))],
              selected: {slot},
              onSelectionChanged: (s) => setS(() => slot = s.first),
            ),
            const SizedBox(height: 12),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'Đã ăn gì?'), maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: kcal,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'kcal (ước tính)'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: prot,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Protein g (ước tính)'))),
            ]),
            const SizedBox(height: 12),
            TextField(
                controller: cost,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Chi phí (VNĐ, tùy chọn)', hintText: 'VD: 35000')),
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
                    final ok = await confirmDialog(ctx, title: 'Xóa bữa ăn?', message: log.description, confirmText: 'Xóa', danger: true);
                    if (!ok) return;
                    st.update((dd) => dd.mealLogs.removeWhere((e) => e.id == log.id));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa'),
                ),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              FilledButton(
                onPressed: () {
                  if (desc.text.trim().isEmpty) {
                    setS(() => err = 'Vui lòng nhập món đã ăn');
                    return;
                  }
                  int? k, p, c;
                  try {
                    k = parseOptionalInt(kcal.text, max: 5000);
                    p = parseOptionalInt(prot.text, max: 300);
                  } on FormatException {
                    setS(() => err = 'kcal (0–5000) và protein (0–300) phải là số nguyên');
                    return;
                  }
                  if (cost.text.trim().isNotEmpty) {
                    c = parseMoney(cost.text);
                    if (c == null) {
                      setS(() => err = 'Chi phí không hợp lệ');
                      return;
                    }
                  }
                  st.update((dd) {
                    if (log == null) {
                      dd.mealLogs.add(MealLog(
                          id: uid('ml'), date: date, slot: slot, description: desc.text.trim(), kcal: k, proteinG: p, costVnd: c));
                    } else {
                      final x = dd.mealLogs.firstWhere((e) => e.id == log.id);
                      x
                        ..slot = slot
                        ..description = desc.text.trim()
                        ..kcal = k
                        ..proteinG = p
                        ..costVnd = c
                        ..updatedAt = nowIso();
                    }
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

// ============================================================================
// Thực đơn tuần + danh sách đi chợ
// ============================================================================

class _WeekView extends StatefulWidget {
  final String anchor;
  const _WeekView({required this.anchor});
  @override
  State<_WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<_WeekView> {
  late String anchor = widget.anchor;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final wk = weekRange(anchor);
    final days = eachDate(wk.start, wk.end);

    // Danh sách đi chợ: gộp nguyên liệu, đếm số lần dùng trong tuần.
    final shopping = <String, int>{};
    for (final day in days) {
      for (final s in slots) {
        final o = mealOptionById(d, plannedMealId(d, day, s));
        for (final ing in o?.ingredients ?? const <String>[]) {
          shopping[ing] = (shopping[ing] ?? 0) + 1;
        }
      }
    }
    final items = shopping.keys.toList()..sort();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        IconButton(onPressed: () => setState(() => anchor = shiftDate(anchor, -7)), icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text('Tuần ${fmtDayMonth(wk.start)} – ${fmtDayMonth(wk.end)}',
              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        IconButton(onPressed: () => setState(() => anchor = shiftDate(anchor, 7)), icon: const Icon(Icons.chevron_right)),
      ]),
      const InfoBanner('Món chưa chọn sẽ được xoay vòng tự động từ thư viện để đỡ nhàm chán. Nhấn vào món để đổi.'),
      for (final day in days)
        SectionCard(
          title: '${weekdayLong[weekdayOf(day)]} ${fmtDayMonth(day)}',
          child: Column(children: [
            for (final s in slots)
              Builder(builder: (context) {
                final chosen = d.mealPlan.byDate[day]?[s];
                final o = mealOptionById(d, plannedMealId(d, day, s));
                return InkWell(
                  onTap: () async {
                    final opts = d.mealOptions.where((x) => x.slot == s).toList();
                    final v = await showModalBottomSheet<String>(
                      context: context,
                      showDragHandle: true,
                      builder: (ctx) => ListView(shrinkWrap: true, children: [
                        for (final x in opts) ListTile(title: Text(x.name), onTap: () => Navigator.pop(ctx, x.id)),
                        if (chosen != null)
                          ListTile(
                            leading: const Icon(Icons.autorenew),
                            title: const Text('Dùng gợi ý tự động'),
                            onTap: () => Navigator.pop(ctx, '__auto__'),
                          ),
                      ]),
                    );
                    if (v == null) return;
                    st.update((dd) {
                      if (v == '__auto__') {
                        dd.mealPlan.byDate[day]?.remove(s);
                      } else {
                        dd.mealPlan.byDate.putIfAbsent(day, () => {})[s] = v;
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 74, child: Text(slotLabel[s]!, style: mutedStyle(context))),
                      Expanded(child: Text(o?.name ?? '—')),
                      if (chosen == null) Icon(Icons.autorenew, size: 14, color: Theme.of(context).colorScheme.outline),
                    ]),
                  ),
                );
              }),
          ]),
        ),
      SectionCard(
        title: 'Danh sách đi chợ',
        icon: Icons.shopping_basket_outlined,
        subtitle: 'Gộp từ thực đơn tuần (số trong ngoặc = số bữa dùng)',
        child: items.isEmpty
            ? const EmptyState(icon: Icons.shopping_basket_outlined, title: 'Chưa có nguyên liệu')
            : Column(children: [
                for (final it in items)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: d.shoppingChecked['${wk.start}:$it'] == true,
                    onChanged: (v) => st.update((dd) {
                      if (v == true) {
                        dd.shoppingChecked['${wk.start}:$it'] = true;
                      } else {
                        dd.shoppingChecked.remove('${wk.start}:$it');
                      }
                    }),
                    title: Text('$it (${shopping[it]})'),
                  ),
              ]),
      ),
    ]);
  }
}

// ============================================================================
// Thư viện món
// ============================================================================

class _LibraryView extends StatelessWidget {
  const _LibraryView();
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.tonalIcon(
          onPressed: () => _editOption(context, null),
          icon: const Icon(Icons.add),
          label: const Text('Thêm món'),
        ),
      ),
      const SizedBox(height: 8),
      const InfoBanner('kcal/protein của món mẫu là ước tính thô cho khẩu phần thông thường. Bạn có thể sửa cho sát khẩu phần thật.',
          tone: Tone.warn),
      for (final s in slots)
        SectionCard(
          title: slotLabel[s],
          child: Column(children: [
            for (final o in d.mealOptions.where((o) => o.slot == s))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(o.name),
                subtitle: Text('~${o.kcal ?? '?'} kcal · ~${o.proteinG ?? '?'} g protein${o.cheap ? ' · Giá rẻ' : ''}'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editOption(context, o),
              ),
          ]),
        ),
    ]);
  }

  Future<void> _editOption(BuildContext context, MealOption? o) async {
    final st = AppScope.read(context);
    var slot = o?.slot ?? 'lunch';
    final name = TextEditingController(text: o?.name ?? '');
    final kcal = TextEditingController(text: o?.kcal?.toString() ?? '');
    final prot = TextEditingController(text: o?.proteinG?.toString() ?? '');
    final ing = TextEditingController(text: o?.ingredients.join(', ') ?? '');
    var cheap = o?.cheap ?? true;
    String? err;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text(o == null ? 'Thêm món' : 'Sửa món', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [for (final s in slots) ButtonSegment(value: s, label: Text(slotLabel[s]!.replaceAll('Bữa ', '')))],
                selected: {slot},
                onSelectionChanged: (s) => setS(() => slot = s.first),
              ),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên món')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: kcal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'kcal'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: prot,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Protein (g)'))),
              ]),
              const SizedBox(height: 12),
              TextField(
                  controller: ing,
                  decoration: const InputDecoration(labelText: 'Nguyên liệu (cách nhau bằng dấu phẩy)')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: cheap,
                onChanged: (v) => setS(() => cheap = v),
                title: const Text('Giá rẻ, dễ mua'),
              ),
              if (err != null) Text(err!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              const SizedBox(height: 8),
              Row(children: [
                if (o != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
                    onPressed: () async {
                      final ok = await confirmDialog(ctx, title: 'Xóa món?', message: o.name, confirmText: 'Xóa', danger: true);
                      if (!ok) return;
                      st.update((dd) {
                        dd.mealOptions.removeWhere((e) => e.id == o.id);
                        for (final m in dd.mealPlan.byDate.values) {
                          m.removeWhere((k, v) => v == o.id);
                        }
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa'),
                  ),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                FilledButton(
                  onPressed: () {
                    if (name.text.trim().isEmpty) {
                      setS(() => err = 'Vui lòng nhập tên món');
                      return;
                    }
                    int? k, p;
                    try {
                      k = parseOptionalInt(kcal.text, max: 5000);
                      p = parseOptionalInt(prot.text, max: 300);
                    } on FormatException {
                      setS(() => err = 'kcal/protein phải là số nguyên hợp lệ');
                      return;
                    }
                    final ings = ing.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    st.update((dd) {
                      if (o == null) {
                        dd.mealOptions.add(MealOption(
                            id: uid('mo'), slot: slot, name: name.text.trim(), kcal: k, proteinG: p, cheap: cheap, ingredients: ings));
                      } else {
                        final x = dd.mealOptions.firstWhere((e) => e.id == o.id);
                        x
                          ..slot = slot
                          ..name = name.text.trim()
                          ..kcal = k
                          ..proteinG = p
                          ..cheap = cheap
                          ..ingredients = ings;
                      }
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
}

// ============================================================================
// Hướng dẫn
// ============================================================================

class _GuideView extends StatelessWidget {
  const _GuideView();
  @override
  Widget build(BuildContext context) {
    Widget list(List<String> xs) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final x in xs) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $x'))],
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(
        title: 'Nguyên tắc',
        icon: Icons.rule,
        child: list(const [
          'Ăn đủ năng lượng, không nhịn ăn cực đoan.',
          'Có protein trong các bữa chính.',
          'Ăn đa dạng rau củ và trái cây.',
          'Dùng nguồn chất béo tốt (cá, lạc, vừng, các loại hạt).',
          'Uống nước đều trong ngày.',
          'Hạn chế đồ ngọt và đồ uống có đường.',
          'Không cần bỏ hẳn cơm, tinh bột hay chất béo — chỉ cần khẩu phần phù hợp.',
        ]),
      ),
      SectionCard(
        title: 'Nên ưu tiên',
        icon: Icons.thumb_up_alt_outlined,
        child: list(const [
          'Protein: trứng, cá, gà, thịt nạc, đậu phụ, các loại đậu.',
          'Rau củ: rau xanh, cà chua, cà rốt, rau theo mùa.',
          'Trái cây: ổi, cam, táo, chuối và các loại khác.',
          'Chất béo tốt: cá, lạc, vừng, các loại hạt.',
          'Vi chất (sắt, kẽm, vitamin): thịt nạc, trứng, hải sản, đậu, rau lá xanh.',
        ]),
      ),
      SectionCard(
        title: 'Nên hạn chế',
        icon: Icons.do_not_disturb_on_outlined,
        child: list(const [
          'Nước ngọt, trà sữa, đồ uống nhiều đường.',
          'Đồ ăn nhanh, đồ chiên rán thường xuyên.',
          'Rượu bia.',
          'Caffeine buổi chiều tối nếu ảnh hưởng giấc ngủ.',
        ]),
      ),
      const InfoBanner(
        'Không có thực phẩm nào chắc chắn gây mụn hay rụng tóc ở tất cả mọi người. Với sữa bò: chỉ cần theo dõi '
        '(ghi chú ở Nhật ký da) nếu bạn nghi ngờ có liên quan — không bắt buộc kiêng. '
        'Ăn uống tốt hỗ trợ sức khỏe tổng thể, không thay thế điều trị da/tóc của bác sĩ.',
        tone: Tone.warn,
      ),
    ]);
  }
}
