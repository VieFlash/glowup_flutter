import 'package:flutter/material.dart';

import '../logic/date_utils.dart';
import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});
  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  String anchor = todayStr();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final r = monthRange(anchor);
    final sum = spendIn(d, r.start, r.end);
    final budget = d.goals.monthlyBudget;
    final ratio = budget <= 0 ? null : sum.total / budget;
    final warn = ratio != null && ratio * 100 >= d.goals.budgetWarnPercent;
    final over = ratio != null && ratio > 1;
    final list = d.expenses.where((e) => inRange(e.date, r.start, r.end)).toList()..sort((a, b) => b.date.compareTo(a.date));
    final medSpent = sum.byCat['medicine'] ?? 0;

    return PageBody(children: [
      PageHeader(
        title: 'Ngân sách',
        subtitle: 'Tham khảo 700.000–1.500.000 ₫/tháng',
        actions: [
          FilledButton.icon(
            onPressed: () => showExpenseEditor(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Thêm khoản'),
          ),
        ],
      ),
      Row(children: [
        IconButton(onPressed: () => setState(() => anchor = shiftMonth(anchor, -1)), icon: const Icon(Icons.chevron_left)),
        Expanded(child: Text(fmtMonth(anchor), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600))),
        IconButton(onPressed: () => setState(() => anchor = shiftMonth(anchor, 1)), icon: const Icon(Icons.chevron_right)),
      ]),
      const SizedBox(height: 8),
      SectionCard(
        title: 'Tổng chi tháng',
        icon: Icons.account_balance_wallet_outlined,
        trailing: TextButton(onPressed: () => _editBudget(context), child: const Text('Sửa ngân sách')),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LabeledBar(
            label: '${fmtVnd(sum.total)} / ${fmtVnd(budget)}',
            valueText: fmtPct(ratio),
            value: ratio,
            color: over ? Theme.of(context).colorScheme.error : (warn ? Colors.orange : null),
          ),
          StatGrid(children: [
            StatTile(label: 'Còn lại', value: fmtVnd(budget - sum.total)),
            StatTile(label: 'Thiết yếu', value: fmtVnd(sum.essential)),
            StatTile(label: 'Không thiết yếu', value: fmtVnd(sum.nonEssential)),
            StatTile(label: 'Số khoản', value: '${sum.count}'),
          ]),
          if (over)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: InfoBanner(
                'Đã vượt ngân sách. Ưu tiên cắt giảm khoản không thiết yếu (mỹ phẩm mới, thực phẩm bổ sung, đồ ăn vặt). '
                'Không tự giảm liều hoặc ngừng thuốc để tiết kiệm — nếu chi phí điều trị quá cao, hãy hỏi bác sĩ/dược sĩ về lựa chọn phù hợp hơn.',
                tone: Tone.danger,
              ),
            )
          else if (warn)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: InfoBanner('Đã dùng trên ${d.goals.budgetWarnPercent}% ngân sách tháng. Cân nhắc trước các khoản không thiết yếu.',
                  tone: Tone.warn),
            ),
          if (medSpent > 0 && budget > 0 && medSpent > budget * 0.6)
            const InfoBanner(
              'Thuốc theo đơn chiếm phần lớn ngân sách. Nếu khó duy trì, hãy trao đổi với bác sĩ/dược sĩ thay vì tự ngừng hoặc giảm liều.',
              tone: Tone.warn,
            ),
        ]),
      ),
      SectionCard(
        title: 'Theo danh mục',
        icon: Icons.pie_chart_outline,
        child: sum.total == 0
            ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'Chưa có khoản chi tháng này')
            : Column(children: [
                for (final e in expenseLabel.entries)
                  if ((sum.byCat[e.key] ?? 0) > 0)
                    LabeledBar(
                      label: e.value,
                      valueText: fmtVnd(sum.byCat[e.key]),
                      value: (sum.byCat[e.key] ?? 0) / sum.total,
                    ),
              ]),
      ),
      SectionCard(
        title: 'Các khoản chi',
        icon: Icons.receipt_long_outlined,
        child: list.isEmpty
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Chưa có khoản chi',
                action: FilledButton.tonal(onPressed: () => showExpenseEditor(context, null), child: const Text('Thêm khoản đầu tiên')),
              )
            : Column(children: [
                for (final e in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.title),
                    subtitle: Text('${fmtDate(e.date)} · ${expenseLabel[e.category] ?? 'Khác'}${e.essential ? '' : ' · không thiết yếu'}'),
                    trailing: Text(fmtVnd(e.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => showExpenseEditor(context, e),
                  ),
              ]),
      ),
      Text(
        'Gợi ý: ưu tiên những thứ thực sự cần (thực phẩm, sản phẩm cơ bản, thuốc theo đơn). Không cần mua nhiều mỹ phẩm hay thực phẩm bổ sung.',
        style: mutedStyle(context),
      ),
    ]);
  }

  Future<void> _editBudget(BuildContext context) async {
    final st = AppScope.read(context);
    final v = await promptText(context, title: 'Ngân sách tháng (VNĐ)', initial: '${st.data.goals.monthlyBudget}');
    if (v == null) return;
    final n = parseMoney(v);
    if (n == null || n <= 0) {
      if (context.mounted) showSnack(context, 'Số tiền không hợp lệ', error: true);
      return;
    }
    st.update((d) => d.goals.monthlyBudget = n);
  }
}

Future<void> showExpenseEditor(BuildContext context, Expense? e) async {
  final st = AppScope.read(context);
  final title = TextEditingController(text: e?.title ?? '');
  final amount = TextEditingController(text: e?.amount.toString() ?? '');
  var date = e?.date ?? todayStr();
  var cat = e?.category ?? 'food';
  var essential = e?.essential ?? true;
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
            Text(e == null ? 'Thêm khoản chi' : 'Sửa khoản chi', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Nội dung')),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tiền (VNĐ)', hintText: 'VD: 150000', suffixText: '₫'),
            ),
            const SizedBox(height: 12),
            DateButton(label: 'Ngày mua', value: date, onChanged: (v) => setS(() => date = v)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: cat,
              decoration: const InputDecoration(labelText: 'Danh mục'),
              items: [for (final x in expenseLabel.entries) DropdownMenuItem(value: x.key, child: Text(x.value))],
              onChanged: (v) => setS(() {
                cat = v ?? cat;
                if (cat == 'medicine' || cat == 'food') essential = true;
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: essential,
              onChanged: (v) => setS(() => essential = v),
              title: const Text('Khoản thiết yếu'),
            ),
            if (err != null) Text(err!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            const SizedBox(height: 8),
            Row(children: [
              if (e != null)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
                  onPressed: () async {
                    final ok = await confirmDialog(ctx, title: 'Xóa khoản chi?', message: e.title, confirmText: 'Xóa', danger: true);
                    if (!ok) return;
                    st.update((d) => d.expenses.removeWhere((x) => x.id == e.id));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa'),
                ),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              FilledButton(
                onPressed: () {
                  final n = parseMoney(amount.text);
                  if (title.text.trim().isEmpty) {
                    setS(() => err = 'Vui lòng nhập nội dung');
                    return;
                  }
                  if (n == null || n <= 0 || n > 1000000000) {
                    setS(() => err = 'Số tiền không hợp lệ');
                    return;
                  }
                  st.update((d) {
                    if (e == null) {
                      d.expenses.add(Expense(
                          id: uid('ex'), date: date, amount: n, category: cat, title: title.text.trim(), essential: essential));
                    } else {
                      final x = d.expenses.firstWhere((y) => y.id == e.id);
                      x
                        ..title = title.text.trim()
                        ..amount = n
                        ..date = date
                        ..category = cat
                        ..essential = essential
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
