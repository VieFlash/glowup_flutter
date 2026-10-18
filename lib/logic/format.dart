import 'dart:math';

/// 1500000 -> "1.500.000 ₫"
String fmtVnd(num? n) {
  if (n == null) return '—';
  final neg = n < 0;
  final s = n.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${neg ? '-' : ''}$buf ₫';
}

/// Số thập phân kiểu Việt Nam: 2,5
String fmtNum(num? n, [int digits = 1]) {
  if (n == null || (n is double && n.isNaN)) return '—';
  final f = pow(10, digits);
  final r = (n * f).round() / f;
  var s = r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(digits);
  return s.replaceAll('.', ',');
}

String fmtPct(double? r) => r == null ? '—' : '${(r * 100).round()}%';

double? avg(Iterable<num> xs) {
  final l = xs.toList();
  if (l.isEmpty) return null;
  return l.fold<double>(0, (a, b) => a + b) / l.length;
}

/// Đọc số tiền từ chuỗi "150.000", "150,000", "150000"
int? parseMoney(String s) {
  final cleaned = s.replaceAll(RegExp(r'[^0-9]'), '');
  if (cleaned.isEmpty) return null;
  return int.tryParse(cleaned);
}

final Random _rnd = Random();

String uid([String prefix = '']) {
  final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final r = List.generate(6, (_) => _rnd.nextInt(36).toRadixString(36)).join();
  return prefix.isEmpty ? '$t$r' : '${prefix}_$t$r';
}
