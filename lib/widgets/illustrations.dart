import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/theme.dart';

// ─────────────────────────── Route map ───────────────────────────

/// Stylised neighbourhood map used for location, tracking and staff routes.
/// When [animated] is true a courier dot travels along the route.
class RouteMap extends StatefulWidget {
  final double height;
  final bool animated;
  final String label;
  const RouteMap({super.key, this.height = 165, this.animated = false, this.label = 'Illustrative Kashipur route'});

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 7));

  @override
  void initState() {
    super.initState();
    if (widget.animated) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.mapBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(painter: _MapPainter(widget.animated ? _c.value : -1)),
          ),
        ),
        Positioned(
          left: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
            child: Text(widget.label, style: T.sans(9.5, color: AppColors.ink, weight: FontWeight.w500)),
          ),
        ),
      ]),
    );
  }
}

class _MapPainter extends CustomPainter {
  final double t; // -1 = no courier
  _MapPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final edge = Paint()
      ..color = const Color(0xFFD5DCCB)
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.square;
    final road = Paint()
      ..color = const Color(0xFFFFFDF8)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.square;
    final roads = <(Offset, Offset)>[
      (Offset(-10, h * 0.20), Offset(w + 10, h * 0.34)),
      (Offset(-10, h * 0.80), Offset(w + 10, h * 0.62)),
      (Offset(w * 0.12, -10), Offset(w * 0.30, h + 10)),
      (Offset(w * 0.47, -10), Offset(w * 0.42, h + 10)),
      (Offset(w * 0.74, -10), Offset(w * 0.66, h + 10)),
      (Offset(w * 0.93, -10), Offset(w * 0.84, h + 10)),
    ];
    for (final r in roads) {
      canvas.drawLine(r.$1, r.$2, edge);
    }
    for (final r in roads) {
      canvas.drawLine(r.$1, r.$2, road);
    }

    // Area label
    final tp = TextPainter(
      text: TextSpan(text: 'PATEL NAGAR', style: T.sans(9, color: const Color(0xFF8A8F80), weight: FontWeight.w600, spacing: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w * 0.58, h * 0.10));

    // Route
    final pts = [Offset(w * 0.20, h * 0.27), Offset(w * 0.55, h * 0.34), Offset(w * 0.52, h * 0.70), Offset(w * 0.79, h * 0.66)];
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final white = Paint()..color = AppColors.white;
    canvas.drawCircle(pts.first, 9, white);
    canvas.drawCircle(pts.first, 7, Paint()..color = AppColors.yellow);
    canvas.drawCircle(pts.last, 11, white);
    canvas.drawCircle(pts.last, 9, Paint()..color = AppColors.berry);

    if (t >= 0) {
      final metric = path.computeMetrics().first;
      final tan = metric.getTangentForOffset(metric.length * Curves.easeInOut.transform(t));
      if (tan != null) {
        canvas.drawCircle(tan.position, 13, Paint()..color = const Color(0x33007F7C));
        canvas.drawCircle(tan.position, 8, white);
        canvas.drawCircle(tan.position, 5.5, Paint()..color = AppColors.teal);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.t != t;
}

// ─────────────────────────── Milk bottle ───────────────────────────

class MilkBottle extends StatelessWidget {
  final double height;
  const MilkBottle({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) => SizedBox(width: height * 0.52, height: height, child: CustomPaint(painter: _BottlePainter()));
}

class _BottlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final cx = w / 2;

    // Base shadow
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, h * 0.955), width: w * 1.05, height: h * 0.07), Paint()..color = const Color(0xFF1D5C55));

    // Body
    final neckW = w * 0.40, bodyW = w * 0.86;
    final top = h * 0.10, shoulder = h * 0.30, bottom = h * 0.94;
    final body = Path()
      ..moveTo(cx - neckW / 2, top)
      ..lineTo(cx - neckW / 2, h * 0.17)
      ..cubicTo(cx - neckW / 2, h * 0.24, cx - bodyW / 2, h * 0.24, cx - bodyW / 2, shoulder)
      ..lineTo(cx - bodyW / 2, bottom - 8)
      ..quadraticBezierTo(cx - bodyW / 2, bottom, cx - bodyW / 2 + 8, bottom)
      ..lineTo(cx + bodyW / 2 - 8, bottom)
      ..quadraticBezierTo(cx + bodyW / 2, bottom, cx + bodyW / 2, bottom - 8)
      ..lineTo(cx + bodyW / 2, shoulder)
      ..cubicTo(cx + bodyW / 2, h * 0.24, cx + neckW / 2, h * 0.24, cx + neckW / 2, h * 0.17)
      ..lineTo(cx + neckW / 2, top)
      ..close();
    canvas.drawPath(body, Paint()..color = AppColors.white);
    canvas.drawPath(
      body,
      Paint()
        ..color = AppColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.6, w * 0.035),
    );

    // Yellow neck band + teal cap
    canvas.drawRect(Rect.fromLTWH(cx - neckW / 2, h * 0.09, neckW, h * 0.05), Paint()..color = AppColors.yellow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - neckW * 0.58, h * 0.02, neckW * 1.16, h * 0.075), Radius.circular(w * 0.05)),
      Paint()..color = AppColors.teal,
    );

    // Label
    final label = Rect.fromLTWH(cx - w * 0.36, h * 0.43, w * 0.72, h * 0.30);
    canvas.drawRect(label, Paint()..color = AppColors.berry);
    canvas.drawRect(
      label.deflate(w * 0.035),
      Paint()
        ..color = AppColors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    void text(String t, double y, double size, Color c, {bool serif = false}) {
      final tp = TextPainter(
        text: TextSpan(
          text: t,
          style: TextStyle(fontFamily: serif ? AppFonts.serif : AppFonts.sans, fontSize: size, color: c, fontWeight: FontWeight.w600, height: 1),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: label.width);
      tp.paint(canvas, Offset(cx - tp.width / 2, y));
    }

    text('UDS', h * 0.465, h * 0.075, AppColors.yellow, serif: true);
    text('FULL CREAM', h * 0.565, h * 0.043, AppColors.white);
    text('FRESH MILK', h * 0.63, h * 0.036, AppColors.yellow);
    text('1 LITRE', h * 0.80, h * 0.038, AppColors.teal);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MilkHero extends StatelessWidget {
  final double height;
  final VoidCallback? onTap;
  const MilkHero({super.key, this.height = 158, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(90),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Stack(children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 16, end: 0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Transform.translate(offset: Offset(0, v), child: child),
              child: MilkBottle(height: height * 0.8),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 18,
            child: Text('Fresh beginnings.\nEvery morning.', textAlign: TextAlign.right, style: T.sans(9.5, color: AppColors.teal, height: 1.5)),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────── Gift banner ───────────────────────────

class GiftBanner extends StatelessWidget {
  final int gifts;
  final double height;
  const GiftBanner({super.key, this.gifts = 1, this.height = 92});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _PaisleyPainter())),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Row(
              key: ValueKey(gifts),
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < math.max(1, gifts); i++)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.card_giftcard_rounded, color: AppColors.yellow, size: 38),
                  ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _PaisleyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0x22FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (double x = -20; x < s.width + 40; x += 64) {
      final path = Path()..moveTo(x, s.height * 0.5);
      path.cubicTo(x + 16, s.height * 0.1, x + 32, s.height * 0.9, x + 64, s.height * 0.5);
      canvas.drawPath(path, p);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 32, s.height * 0.22), width: 22, height: 12), p);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 2, s.height * 0.8), width: 22, height: 12), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────── Photos ───────────────────────────

/// Product photography with the signature arched top.
class ArchImage extends StatelessWidget {
  final String asset;
  final double? width;
  final double height;
  final double arch;
  final double bottomRadius;
  const ArchImage(this.asset, {super.key, this.width, required this.height, this.arch = 60, this.bottomRadius = 14});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(arch), bottom: Radius.circular(bottomRadius)),
      child: Image.asset(asset, width: width, height: height, fit: BoxFit.cover, filterQuality: ui.FilterQuality.medium),
    );
  }
}
