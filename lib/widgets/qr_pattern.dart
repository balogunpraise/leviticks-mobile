import 'package:flutter/material.dart';

/// Mirrors `src/lib/qrPattern.ts` — a deterministic, decorative fake-QR
/// pattern seeded from the ticket code (not a real scannable QR).
class QrCell {
  const QrCell(this.x, this.y);
  final int x;
  final int y;
}

class _SeededRandom {
  _SeededRandom(int seed) : _a = seed;
  int _a;

  double next() {
    _a = (_a + 0x6d2b79f5) & 0xFFFFFFFF;
    var t = _a;
    t = ((t ^ (t >> 15)) * ((1 | _a) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    t = (t + (((t ^ (t >> 7)) * ((61 | t) & 0xFFFFFFFF)) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    final result = (t ^ (t >> 14)) & 0xFFFFFFFF;
    return result / 4294967296.0;
  }
}

int _hashCode(String code) {
  var acc = 0;
  for (final unit in code.codeUnits) {
    acc = ((acc * 31 + unit) & 0xFFFFFFFF);
  }
  // Interpret as signed 32-bit, matching JS `| 0` overflow behavior.
  if (acc > 0x7FFFFFFF) acc -= 0x100000000;
  return acc;
}

List<QrCell> getQrCells(String code) {
  const size = 21;
  final rng = _SeededRandom(_hashCode(code));
  final cells = <QrCell>[];

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final inFinder = (x < 8 && y < 8) || (x >= 13 && y < 8) || (x < 8 && y >= 13);
      if (!inFinder && rng.next() >= 0.5) cells.add(QrCell(x, y));
    }
  }

  for (final origin in const [(0, 0), (14, 0), (0, 14)]) {
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        final border = x == 0 || x == 6 || y == 0 || y == 6;
        final inner = x >= 2 && x <= 4 && y >= 2 && y <= 4;
        if (border || inner) cells.add(QrCell(origin.$1 + x, origin.$2 + y));
      }
    }
  }

  return cells;
}

class QrPatternPainter extends CustomPainter {
  QrPatternPainter(this.code, {this.color = Colors.black});

  final String code;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 21;
    final paint = Paint()..color = color;
    for (final cell in getQrCells(code)) {
      canvas.drawRect(
        Rect.fromLTWH(cell.x * cellSize, cell.y * cellSize, cellSize, cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant QrPatternPainter oldDelegate) => oldDelegate.code != code;
}

/// Renders the decorative QR pattern at a fixed square [size].
class QrPatternView extends StatelessWidget {
  const QrPatternView({super.key, required this.code, this.size = 64, this.color = Colors.black});

  final String code;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: QrPatternPainter(code, color: color)),
    );
  }
}
