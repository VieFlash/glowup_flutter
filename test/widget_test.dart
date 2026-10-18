// Kiểm thử logic thuần (không cần thiết bị): chạy `flutter test`.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glowup_tracker/data/defaults.dart';
import 'package:glowup_tracker/logic/date_utils.dart';
import 'package:glowup_tracker/logic/format.dart';
import 'package:glowup_tracker/logic/logic.dart';
import 'package:glowup_tracker/models/models.dart';
import 'package:glowup_tracker/services/storage_service.dart';

void main() {
  group('Ngày giờ', () {
    test('toLocalDate / shiftDate qua tháng, năm', () {
      expect(shiftDate('2026-01-31', 1), '2026-02-01');
      expect(shiftDate('2026-01-01', -1), '2025-12-31');
      expect(weekdayOf('2026-10-18'), 0); // Chủ nhật
    });
    test('Tuần bắt đầu Thứ 2', () {
      final r = weekRange('2026-10-18');
      expect(r.start, '2026-10-12');
      expect(r.end, '2026-10-18');
    });
    test('Thời lượng ngủ qua nửa đêm', () {
      expect(sleepDurationHours('23:00', '07:00'), 8);
      expect(sleepDurationHours('00:30', '07:00'), 6.5);
    });
    test('Phút trễ so với mục tiêu', () {
      expect(minutesLate('00:30', '23:00'), 90);
      expect(minutesLate('22:45', '23:00'), -15);
    });
  });

  group('Định dạng', () {
    test('VNĐ', () {
      expect(fmtVnd(1500000), '1.500.000 ₫');
      expect(parseMoney('150.000'), 150000);
    });
  });

  group('Tiến độ & chuỗi', () {
    test('Bỏ qua / không áp dụng không bị tính là chưa làm', () {
      final d = createInitialData();
      const day = '2026-10-15';
      final hs = habitsForDate(d, day);
      setHabitStatus(d, day, hs[0].id, 'done');
      setHabitStatus(d, day, hs[1].id, 'skipped');
      setHabitStatus(d, day, hs[2].id, 'na');
      final p = dayProgress(d, day);
      expect(p.counted, hs.length - 2);
      expect(p.done, 1);
    });
    test('Chuỗi duy trì', () {
      final d = createInitialData();
      for (final day in ['2026-10-16', '2026-10-17']) {
        for (final h in habitsForDate(d, day)) {
          setHabitStatus(d, day, h.id, 'done');
        }
      }
      expect(currentStreak(d, '2026-10-18'), 2); // hôm nay chưa đạt -> đếm từ hôm qua
    });
  });

  group('Thuốc', () {
    test('Thuốc chưa xác nhận không được tính', () {
      final d = createInitialData();
      d.medications.add(MedicationPlan(id: 'm1', name: 'X', area: 'hair', timesOfDay: ['21:00']));
      expect(medAppliesOn(d.medications.first, todayStr()), isFalse);
      d.medications.first.confirmedCurrent = true;
      expect(medAppliesOn(d.medications.first, todayStr()), isTrue);
    });
  });

  group('Xuất / nhập', () {
    test('Vòng xuất -> nhập giữ nguyên dữ liệu', () async {
      final s = StorageService();
      final d = createInitialData();
      d.expenses.add(Expense(id: 'e1', date: '2026-10-01', amount: 120000, category: 'food', title: 'Đi chợ'));
      final out = await s.buildExport(d, includePhotos: false);
      final text = jsonEncode(out);
      final back = s.parseImport(text).data;
      expect(back.expenses.single.amount, 120000);
      expect(back.habits.length, d.habits.length);
    });
    test('File sai định dạng báo lỗi', () {
      final s = StorageService();
      expect(() => s.parseImport('không phải json'), throwsA(isA<ImportException>()));
      expect(() => s.parseImport('{"app":"khac"}'), throwsA(isA<ImportException>()));
    });
  });
}
