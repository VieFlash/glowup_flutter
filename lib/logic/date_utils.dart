// Tiện ích ngày giờ — làm việc với ngày địa phương 'yyyy-MM-dd'.

String _p2(int n) => n.toString().padLeft(2, '0');

/// DateTime -> 'yyyy-MM-dd' theo giờ địa phương.
String toLocalDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_p2(d.month)}-${_p2(d.day)}';

/// 'yyyy-MM-dd' -> DateTime 00:00 giờ địa phương.
DateTime fromLocalDate(String s) {
  final parts = s.split('-');
  if (parts.length != 3) return DateTime.now();
  return DateTime(int.tryParse(parts[0]) ?? 2000, int.tryParse(parts[1]) ?? 1, int.tryParse(parts[2]) ?? 1);
}

String todayStr() => toLocalDate(DateTime.now());

String shiftDate(String s, int days) {
  final d = fromLocalDate(s);
  return toLocalDate(DateTime(d.year, d.month, d.day + days));
}

/// 0 = Chủ nhật, 1 = Thứ 2, …, 6 = Thứ 7
int weekdayOf(String s) => fromLocalDate(s).weekday % 7;

const weekdayShort = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
const weekdayLong = ['Chủ nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];

/// Thứ tự hiển thị tuần bắt đầu từ Thứ 2
const weekOrder = [1, 2, 3, 4, 5, 6, 0];

String fmtDate(String s) {
  final d = fromLocalDate(s);
  return '${_p2(d.day)}/${_p2(d.month)}/${d.year}';
}

String fmtDayMonth(String s) {
  final d = fromLocalDate(s);
  return '${_p2(d.day)}/${_p2(d.month)}';
}

String fmtLong(String s) {
  final d = fromLocalDate(s);
  return '${weekdayLong[d.weekday % 7]}, ${d.day} tháng ${d.month}, ${d.year}';
}

String fmtMonth(String s) {
  final d = fromLocalDate(s);
  return 'Tháng ${d.month}/${d.year}';
}

/// Tuần bắt đầu từ Thứ 2.
({String start, String end}) weekRange(String s) {
  final wd = weekdayOf(s); // 0..6
  final back = (wd + 6) % 7; // số ngày lùi về Thứ 2
  final start = shiftDate(s, -back);
  return (start: start, end: shiftDate(start, 6));
}

({String start, String end}) monthRange(String s) {
  final d = fromLocalDate(s);
  final start = DateTime(d.year, d.month, 1);
  final end = DateTime(d.year, d.month + 1, 0);
  return (start: toLocalDate(start), end: toLocalDate(end));
}

String shiftMonth(String s, int months) {
  final d = fromLocalDate(s);
  return toLocalDate(DateTime(d.year, d.month + months, 1));
}

List<String> eachDate(String start, String end) {
  final out = <String>[];
  var cur = start;
  var guard = 0;
  while (cur.compareTo(end) <= 0 && guard < 1000) {
    out.add(cur);
    cur = shiftDate(cur, 1);
    guard++;
  }
  return out;
}

bool inRange(String d, String start, String end) => d.compareTo(start) >= 0 && d.compareTo(end) <= 0;

int daysBetween(String a, String b) {
  final da = fromLocalDate(a);
  final db = fromLocalDate(b);
  return DateTime.utc(db.year, db.month, db.day).difference(DateTime.utc(da.year, da.month, da.day)).inDays;
}

final RegExp _hmRe = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
bool isValidHm(String t) => _hmRe.hasMatch(t);

int hmToMin(String t) {
  if (!isValidHm(t)) return 0;
  final p = t.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String minToHm(int min) {
  final m = ((min % 1440) + 1440) % 1440;
  return '${_p2(m ~/ 60)}:${_p2(m % 60)}';
}

String nowHm() {
  final n = DateTime.now();
  return '${_p2(n.hour)}:${_p2(n.minute)}';
}

/// Thời lượng ngủ (giờ) từ giờ bắt đầu ngủ đến giờ thức dậy, xử lý qua nửa đêm.
double sleepDurationHours(String sleepTime, String wakeTime) {
  var diff = hmToMin(wakeTime) - hmToMin(sleepTime);
  if (diff <= 0) diff += 1440;
  return diff / 60.0;
}

/// Số phút trễ so với mục tiêu; giờ trước 12:00 trưa được coi là "sau nửa đêm".
int minutesLate(String actual, String target) {
  int norm(String t) {
    final m = hmToMin(t);
    return m < 12 * 60 ? m + 1440 : m;
  }

  return norm(actual) - norm(target);
}

String fmtHours(double? h) {
  if (h == null) return '—';
  final total = (h * 60).round();
  return '${total ~/ 60}g${_p2(total % 60)}';
}
