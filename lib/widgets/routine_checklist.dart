import 'package:flutter/material.dart';

import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'common.dart';

class RoutineStep {
  final String key;
  final String label;
  final String? hint;
  const RoutineStep(this.key, this.label, [this.hint]);
}

/// Checklist các bước của một routine. Khi tất cả bước xong, routine được đánh dấu hoàn thành.
class RoutineChecklist extends StatelessWidget {
  final String date;
  final String routineKey; // vd 'skin-am'
  final List<RoutineStep> steps;
  final void Function(AppData d, bool allDone)? onAllDoneChanged;
  const RoutineChecklist({
    super.key,
    required this.date,
    required this.routineKey,
    required this.steps,
    this.onAllDoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final routineDone = careDone(d, date, routineKey);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final s in steps)
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: routineDone || careDone(d, date, '$routineKey:${s.key}'),
          onChanged: (v) => st.update((dd) {
            if (routineDone && v != true) {
              // Bỏ dấu một bước khi cả routine đã được đánh dấu: chuyển sang chế độ từng bước.
              setCare(dd, date, routineKey, false);
              for (final x in steps) {
                setCare(dd, date, '$routineKey:${x.key}', x.key != s.key);
              }
            } else {
              setCare(dd, date, '$routineKey:${s.key}', v == true);
            }
            final all = steps.every((x) => careDone(dd, date, '$routineKey:${x.key}'));
            setCare(dd, date, routineKey, all);
            onAllDoneChanged?.call(dd, all);
          }),
          title: Text(s.label),
          subtitle: s.hint == null ? null : Text(s.hint!, style: mutedStyle(context)),
        ),
    ]);
  }
}
