import 'package:flutter/material.dart';

import '../app.dart';
import '../logic/date_utils.dart';
import '../logic/logic.dart';
import '../state/app_state.dart';
import 'common.dart';

/// Danh sách thuốc đã xác nhận cần dùng trong ngày, kèm nút ghi nhận.
/// [area] = null để hiện tất cả.
class MedsTodayList extends StatelessWidget {
  final String? area;
  final String? date;
  const MedsTodayList({super.key, this.area, this.date});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final day = date ?? todayStr();
    final meds = d.medications.where((m) => (area == null || m.area == area) && medAppliesOn(m, day)).toList();
    final unconfirmed = d.medications.where((m) => (area == null || m.area == area) && m.active && !m.confirmedCurrent).length;

    if (meds.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          unconfirmed > 0
              ? 'Có $unconfirmed mục chưa được xác nhận đang dùng nên chưa hiện ở đây.'
              : 'Chưa có thuốc nào được xác nhận đang dùng hôm nay.',
          style: mutedStyle(context),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => appNav.value = area == 'skin' ? 5 : 6,
            icon: const Icon(Icons.medication_outlined, size: 18),
            label: const Text('Quản lý thuốc'),
          ),
        ),
      ]);
    }

    return Column(children: [
      for (final m in meds)
        for (final t in medTimes(m))
          Builder(builder: (context) {
            final status = d.medLogs[medKey(day, m.id, t)]?.status;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      [if (t != '--:--') t, if (m.instructions.isNotEmpty) m.instructions].join(' · '),
                      style: mutedStyle(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  emptySelectionAllowed: true,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: const [
                    ButtonSegment(value: 'taken', label: Text('Đã dùng')),
                    ButtonSegment(value: 'skipped', label: Text('Bỏ')),
                  ],
                  selected: status == null || status == 'missed' ? <String>{} : {status},
                  onSelectionChanged: (s) =>
                      st.update((dd) => setMedStatus(dd, day, m.id, t, s.isEmpty ? null : s.first)),
                ),
              ]),
            );
          }),
      Text(
        'App chỉ ghi nhận việc bạn dùng theo hướng dẫn đã nhập — không tự thay đổi liều hay tần suất.',
        style: mutedStyle(context)?.copyWith(fontSize: 11),
      ),
    ]);
  }
}
