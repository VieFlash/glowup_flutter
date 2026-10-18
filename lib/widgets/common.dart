import 'package:flutter/material.dart';

import '../logic/date_utils.dart';

// ---------------------------------------------------------------------------
// Bố cục chung
// ---------------------------------------------------------------------------

/// Nội dung trang: cuộn dọc, giới hạn chiều rộng để đẹp trên desktop.
class PageBody extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;
  const PageBody({super.key, required this.children, this.maxWidth = 920});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final IconData? icon;
  const SectionCard({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
        ),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: cs.primary),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            if (subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(subtitle!, style: mutedStyle(context)),
                              ),
                          ],
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle? mutedStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle!, style: mutedStyle(context)),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thông báo / trạng thái
// ---------------------------------------------------------------------------

enum Tone { info, warn, danger, success }

class InfoBanner extends StatelessWidget {
  final String text;
  final Tone tone;
  final IconData? icon;
  final Widget? action;
  const InfoBanner(this.text, {super.key, this.tone = Tone.info, this.icon, this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Color bg, fg;
    IconData ic;
    switch (tone) {
      case Tone.warn:
        bg = dark ? const Color(0xFF3A2E1A) : const Color(0xFFFFF4E0);
        fg = dark ? const Color(0xFFF5D08A) : const Color(0xFF7A4B00);
        ic = Icons.info_outline;
      case Tone.danger:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        ic = Icons.warning_amber_rounded;
      case Tone.success:
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        ic = Icons.check_circle_outline;
      case Tone.info:
        bg = cs.secondaryContainer.withOpacity(0.6);
        fg = cs.onSecondaryContainer;
        ic = Icons.lightbulb_outline;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? ic, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: fg, fontSize: 13, height: 1.35))),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, shape: BoxShape.circle),
            child: Icon(icon, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(message!, textAlign: TextAlign.center, style: mutedStyle(context)),
            ),
          if (action != null) Padding(padding: const EdgeInsets.only(top: 12), child: action!),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final IconData? icon;
  const StatTile({super.key, required this.label, required this.value, this.hint, this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[Icon(icon, size: 14, color: cs.onSurfaceVariant), const SizedBox(width: 4)],
            Expanded(child: Text(label, style: mutedStyle(context), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          if (hint != null && hint!.isNotEmpty) Text(hint!, style: mutedStyle(context)?.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

/// Lưới các ô thống kê, tự điều chỉnh số cột theo chiều rộng.
class StatGrid extends StatelessWidget {
  final List<Widget> children;
  const StatGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 700 ? 4 : (c.maxWidth > 420 ? 3 : 2);
      const gap = 8.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: children.map((e) => SizedBox(width: w, child: e)).toList(),
      );
    });
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color? color;
  const Tag(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
    );
  }
}

// ---------------------------------------------------------------------------
// Hộp thoại
// ---------------------------------------------------------------------------

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Xác nhận',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return r ?? false;
}

void showSnack(BuildContext context, String msg, {bool error = false}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg),
    behavior: SnackBarBehavior.floating,
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
  ));
}

/// Hộp thoại nhập văn bản đơn giản.
Future<String?> promptText(BuildContext context,
    {required String title, String initial = '', String? hint, int maxLines = 1}) async {
  final ctrl = TextEditingController(text: initial);
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Lưu')),
      ],
    ),
  );
  return r;
}

// ---------------------------------------------------------------------------
// Ô nhập liệu
// ---------------------------------------------------------------------------

/// Chọn giờ 'HH:mm'
Future<String?> pickTime(BuildContext context, String initial) async {
  final m = isValidHm(initial) ? hmToMin(initial) : 0;
  final t = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    builder: (ctx, child) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  if (t == null) return null;
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// Chọn ngày, trả về 'yyyy-MM-dd'
Future<String?> pickDate(BuildContext context, String initial, {String? first, String? last}) async {
  final d = await showDatePicker(
    context: context,
    initialDate: fromLocalDate(initial),
    firstDate: first != null ? fromLocalDate(first) : DateTime(2020),
    lastDate: last != null ? fromLocalDate(last) : DateTime(2100),
  );
  return d == null ? null : toLocalDate(d);
}

class TimeButton extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const TimeButton({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final v = await pickTime(context, value);
        if (v != null) onChanged(v);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.schedule, size: 18)),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class DateButton extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? last;
  const DateButton({super.key, required this.label, required this.value, required this.onChanged, this.last});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final v = await pickDate(context, value, last: last);
        if (v != null) onChanged(v);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today, size: 16)),
        child: Text(fmtDate(value), style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Thanh chuyển ngày: ‹ Thứ 2, 19/10 ›
class DateNavigator extends StatelessWidget {
  final String date;
  final ValueChanged<String> onChanged;
  final bool allowFuture;
  const DateNavigator({super.key, required this.date, required this.onChanged, this.allowFuture = true});

  @override
  Widget build(BuildContext context) {
    final t = todayStr();
    final isToday = date == t;
    final canNext = allowFuture || date.compareTo(t) < 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          IconButton.outlined(
            tooltip: 'Ngày trước',
            onPressed: () => onChanged(shiftDate(date, -1)),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final v = await pickDate(context, date, last: allowFuture ? null : t);
                if (v != null) onChanged(v);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(isToday ? 'Hôm nay' : weekdayLong[weekdayOf(date)],
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(fmtDate(date), style: mutedStyle(context)),
                  ],
                ),
              ),
            ),
          ),
          if (!isToday)
            TextButton(onPressed: () => onChanged(t), child: const Text('Hôm nay')),
          IconButton.outlined(
            tooltip: 'Ngày sau',
            onPressed: canNext ? () => onChanged(shiftDate(date, 1)) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/// Chọn mức 1–5
class RatingSelector extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final List<String>? hints; // nhãn cho mức 1 và 5
  const RatingSelector({super.key, required this.label, required this.value, required this.onChanged, this.hints});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
            if (hints != null) Text('1 = ${hints![0]} · 5 = ${hints![1]}', style: mutedStyle(context)),
          ]),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [for (var i = 1; i <= 5; i++) ButtonSegment(value: i, label: Text('$i'))],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}

class WeekdayPicker extends StatelessWidget {
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;
  const WeekdayPicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final wd in weekOrder)
          FilterChip(
            label: Text(weekdayShort[wd]),
            selected: selected.contains(wd),
            onSelected: (v) {
              final next = [...selected];
              if (v) {
                next.add(wd);
              } else {
                next.remove(wd);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class ProgressRing extends StatelessWidget {
  final double? value; // 0..1
  final double size;
  final Widget center;
  const ProgressRing({super.key, required this.value, this.size = 96, required this.center});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (value ?? 0).clamp(0.0, 1.0),
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
          center,
        ],
      ),
    );
  }
}

/// Thanh tiến độ ngang có nhãn.
class LabeledBar extends StatelessWidget {
  final String label;
  final String valueText;
  final double? value;
  final Color? color;
  const LabeledBar({super.key, required this.label, required this.valueText, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text(label)),
            Text(valueText, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (value ?? 0).clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Phân tích số nguyên tùy chọn; trả về null nếu rỗng, ném FormatException nếu sai.
int? parseOptionalInt(String s, {int min = 0, int max = 1 << 30}) {
  final t = s.trim();
  if (t.isEmpty) return null;
  final v = int.tryParse(t);
  if (v == null || v < min || v > max) throw const FormatException();
  return v;
}

/// Phân tích số thực tùy chọn (chấp nhận dấu phẩy).
double? parseOptionalDouble(String s, {double min = 0, double max = 1e9}) {
  final t = s.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  final v = double.tryParse(t);
  if (v == null || v < min || v > max) throw const FormatException();
  return v;
}
