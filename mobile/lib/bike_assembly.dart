import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A native, illustrated motorcycle that separates into parts and reassembles.
/// Paint alone follows the timeline, so the welcome page does not relayout.
class BikeAssembly extends StatefulWidget {
  const BikeAssembly({super.key});

  @override
  State<BikeAssembly> createState() => _BikeAssemblyState();
}

class _BikeAssemblyState extends State<BikeAssembly>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  bool _configured = false;
  bool _reducedMotion = false;
  bool _userPaused = false;
  bool _resumeWhenActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
      value: 1,
    )..addStatusListener(_statusChanged);
  }

  void _statusChanged(AnimationStatus status) {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (!_configured) {
      _configured = true;
      _reducedMotion = reduced;
      if (!reduced) _controller.forward(from: 0);
    } else if (reduced && !_reducedMotion) {
      _controller.value = 1;
      _resumeWhenActive = false;
      _userPaused = false;
    }
    _reducedMotion = reduced;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_resumeWhenActive && !_userPaused) _controller.forward();
      _resumeWhenActive = false;
    } else {
      // Inactive and paused can arrive consecutively; retain the first intent.
      _resumeWhenActive = _resumeWhenActive || _controller.isAnimating;
      _controller.stop();
    }
    if (mounted) setState(() {});
  }

  void _toggle() {
    setState(() {
      if (_controller.isAnimating) {
        _userPaused = true;
        _resumeWhenActive = false;
        _controller.stop();
      } else {
        _userPaused = false;
        // An explicit replay remains available when reduced motion is enabled.
        if (_controller.isCompleted) {
          _controller.forward(from: 0);
        } else {
          _controller.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing = _controller.isAnimating;
    final complete = _controller.isCompleted;
    return AspectRatio(
      key: const Key('bikeAssembly'),
      aspectRatio: 1.38,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            image: true,
            label:
                'A classic motorcycle with a navy tank, tan saddle and chrome '
                'engine. Its components separate and reassemble.',
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _MotorcyclePainter(_controller),
                  isComplex: true,
                  willChange: playing,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton(
              key: const Key('bikeAnimationToggle'),
              tooltip: playing
                  ? 'Pause bike animation'
                  : complete
                  ? 'Replay bike animation'
                  : 'Play bike animation',
              onPressed: _toggle,
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                backgroundColor: const Color(0x142de0de),
                foregroundColor: const Color(0xffa6edf0),
                side: const BorderSide(color: Color(0x287fe3eb)),
              ),
              icon: Icon(
                playing
                    ? Icons.pause_rounded
                    : complete
                    ? Icons.replay_rounded
                    : Icons.play_arrow_rounded,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MotorcyclePainter extends CustomPainter {
  final Animation<double> timeline;

  _MotorcyclePainter(this.timeline) : super(repaint: timeline);

  static const _black = Color(0xff101825);
  static const _steel = Color(0xffb4c5d1);
  static const _cyan = Color(0xff46d5de);

  double _separation(double delay) {
    final t = timeline.value;
    final outStart = .10 + delay;
    final outEnd = .36 + delay;
    final inStart = .48 + delay;
    final inEnd = .88 + delay;
    if (t <= outStart || t >= inEnd) return 0;
    if (t < outEnd) {
      return Curves.easeInOutCubic.transform(
        (t - outStart) / (outEnd - outStart),
      );
    }
    if (t < inStart) return 1;
    return 1 -
        Curves.easeInOutCubic.transform((t - inStart) / (inEnd - inStart));
  }

  Paint _fill(Color color) => Paint()..color = color;

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  Paint _metal(Rect rect, {bool vertical = true}) =>
      Paint()
        ..shader = ui.Gradient.linear(
          vertical ? rect.topCenter : rect.centerLeft,
          vertical ? rect.bottomCenter : rect.centerRight,
          const [
            Color(0xffedf6fa),
            Color(0xff8b9ba9),
            Color(0xffd6e1e8),
            Color(0xff607281),
          ],
          const [0, .32, .53, 1],
        );

  void _part(
    Canvas canvas, {
    required Offset center,
    required Offset travel,
    required double amount,
    double rotation = 0,
    required void Function() draw,
  }) {
    canvas.save();
    canvas.translate(travel.dx * amount, travel.dy * amount);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * amount);
    canvas.translate(-center.dx, -center.dy);
    draw();
    canvas.restore();
  }

  void _tube(Canvas canvas, Path path, {double width = 8}) {
    canvas.drawPath(path, _stroke(const Color(0xff0a101a), width + 3));
    canvas.drawPath(path, _stroke(const Color(0xff3c4b60), width));
    canvas.drawPath(path, _stroke(const Color(0xff76899b), 1.15));
  }

  void _bolt(Canvas canvas, Offset point, {double radius = 2.5}) {
    canvas.drawCircle(point, radius + .8, _fill(const Color(0xff243142)));
    canvas.drawCircle(point, radius, _fill(_steel));
    canvas.drawLine(
      point - Offset(radius * .45, 0),
      point + Offset(radius * .45, 0),
      _stroke(const Color(0xff596e80), .8),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 600, size.height / 420);
    canvas.save();
    canvas.translate(
      (size.width - 600 * scale) / 2,
      (size.height - 420 * scale) / 2,
    );
    canvas.scale(scale);

    // A soft reflection keeps the detached components visually grounded.
    canvas.save();
    canvas.translate(300, 347);
    canvas.scale(215, 20);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          1,
          const [Color(0x3846d5de), Color(0x0846d5de), Color(0x0046d5de)],
          const [0, .6, 1],
        ),
    );
    canvas.restore();

    final split = _separation(.03);
    if (split > .02) _connectors(canvas, split);

    _part(
      canvas,
      center: const Offset(142, 275),
      travel: const Offset(-40, 17),
      amount: _separation(.01),
      rotation: -.09,
      draw: () => _wheel(canvas, const Offset(142, 275), rear: true),
    );
    _part(
      canvas,
      center: const Offset(454, 275),
      travel: const Offset(39, 19),
      amount: _separation(.035),
      rotation: .10,
      draw: () => _wheel(canvas, const Offset(454, 275)),
    );
    _frame(canvas);
    _part(
      canvas,
      center: const Offset(304, 248),
      travel: const Offset(-4, 54),
      amount: _separation(.035),
      rotation: -.035,
      draw: () => _engine(canvas),
    );
    _part(
      canvas,
      center: const Offset(260, 300),
      travel: const Offset(17, 63),
      amount: _separation(.05),
      rotation: .025,
      draw: () => _exhaust(canvas),
    );
    _part(
      canvas,
      center: const Offset(424, 216),
      travel: const Offset(48, -24),
      amount: _separation(.04),
      rotation: .08,
      draw: () => _frontAssembly(canvas),
    );
    _part(
      canvas,
      center: const Offset(167, 221),
      travel: const Offset(-45, -23),
      amount: _separation(.025),
      rotation: -.09,
      draw: () => _rearSuspension(canvas),
    );
    _part(
      canvas,
      center: const Offset(218, 173),
      travel: const Offset(-39, -56),
      amount: _separation(.015),
      rotation: -.045,
      draw: () => _saddle(canvas),
    );
    _part(
      canvas,
      center: const Offset(331, 163),
      travel: const Offset(8, -83),
      amount: _separation(0),
      rotation: .035,
      draw: () => _tank(canvas),
    );
    canvas.restore();
  }

  void _connectors(Canvas canvas, double amount) {
    final paint = _stroke(_cyan.withValues(alpha: .32 * amount), 1);
    for (final pair in [
      (const Offset(331, 177), const Offset(339, 94)),
      (const Offset(218, 181), const Offset(179, 125)),
      (const Offset(305, 238), const Offset(301, 292)),
      (const Offset(425, 214), const Offset(473, 190)),
      (const Offset(142, 275), const Offset(102, 292)),
      (const Offset(454, 275), const Offset(493, 294)),
    ]) {
      final end = Offset.lerp(pair.$1, pair.$2, amount)!;
      final vector = end - pair.$1;
      final length = vector.distance;
      if (length < 1) continue;
      final direction = vector / length;
      for (double d = 0; d < length; d += 8) {
        canvas.drawLine(
          pair.$1 + direction * d,
          pair.$1 + direction * math.min(d + 3.5, length),
          paint,
        );
      }
      canvas.drawCircle(end, 3, paint);
    }
  }

  void _wheel(Canvas canvas, Offset center, {bool rear = false}) {
    final outer = Rect.fromCircle(center: center, radius: 58);
    canvas.drawCircle(center, 59, _fill(const Color(0xff050a11)));
    canvas.drawCircle(
      center,
      56,
      Paint()
        ..shader = ui.Gradient.radial(
          center - const Offset(14, 20),
          80,
          const [Color(0xff344155), Color(0xff101825), Color(0xff050a11)],
          const [0, .6, 1],
        ),
    );
    canvas.drawCircle(center, 54, _stroke(const Color(0xff526176), .7));
    for (var i = 0; i < 36; i++) {
      final a = i * math.pi * 2 / 36;
      final p = center + Offset(math.cos(a), math.sin(a)) * 56;
      final q = center + Offset(math.cos(a + .028), math.sin(a + .028)) * 51;
      canvas.drawLine(p, q, _stroke(const Color(0xff050b13), 1.65));
    }
    canvas.drawCircle(center, 44.5, _metal(outer));
    canvas.drawCircle(center, 40.5, _fill(const Color(0xff122139)));
    canvas.drawCircle(center, 42.8, _stroke(const Color(0xfff2fbff), 1));
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi * 2 / 24;
      final edge = center + Offset(math.cos(a), math.sin(a)) * 40;
      final hub = center + Offset(math.cos(a + .75), math.sin(a + .75)) * 11;
      canvas.drawLine(hub, edge, _stroke(const Color(0xffa4bdcd), .95));
      final alternate =
          center + Offset(math.cos(a - .75), math.sin(a - .75)) * 11;
      canvas.drawLine(alternate, edge, _stroke(const Color(0xff607c91), .6));
    }
    canvas.drawCircle(center, rear ? 19 : 25, _metal(outer));
    canvas.drawCircle(center, rear ? 15 : 20, _fill(const Color(0xff273747)));
    if (!rear) {
      for (var i = 0; i < 14; i++) {
        final a = i * math.pi * 2 / 14;
        canvas.drawCircle(
          center + Offset(math.cos(a), math.sin(a)) * 22.5,
          1.5,
          _fill(const Color(0xff263747)),
        );
      }
    }
    canvas.drawCircle(
      center,
      11,
      _metal(Rect.fromCircle(center: center, radius: 11)),
    );
    _bolt(canvas, center, radius: 5);
  }

  void _frame(Canvas canvas) {
    final main = Path()
      ..moveTo(142, 275)
      ..lineTo(228, 196)
      ..lineTo(303, 286)
      ..lineTo(383, 178)
      ..lineTo(228, 196)
      ..lineTo(171, 195)
      ..moveTo(142, 275)
      ..lineTo(303, 286)
      ..moveTo(226, 195)
      ..lineTo(226, 276)
      ..lineTo(279, 299)
      ..lineTo(345, 296)
      ..quadraticBezierTo(367, 287, 369, 257)
      ..lineTo(389, 175);
    _tube(canvas, main, width: 8);
    final side = Path()
      ..moveTo(178, 204)
      ..lineTo(243, 204)
      ..lineTo(224, 251)
      ..lineTo(193, 238)
      ..close();
    canvas.drawPath(side, _fill(const Color(0xff162235)));
    canvas.drawPath(side, _stroke(const Color(0xff50637b), 1.5));
    canvas.drawLine(
      const Offset(192, 214),
      const Offset(230, 214),
      _stroke(_cyan, 1.5),
    );
    _label(
      canvas,
      '350',
      const Offset(204, 221),
      10,
      const Color(0xffd7e7ed),
      bold: true,
    );
    _bolt(canvas, const Offset(227, 202));
    _bolt(canvas, const Offset(230, 270), radius: 4);
    _tube(
      canvas,
      Path()
        ..moveTo(272, 286)
        ..lineTo(254, 325)
        ..lineTo(244, 325),
      width: 4,
    );
  }

  void _engine(Canvas canvas) {
    // The ribbed air-cooled cylinder, with offset layers for depth.
    canvas.save();
    canvas.translate(305, 231);
    canvas.rotate(-.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25, -22, 47, 45),
        const Radius.circular(8),
      ),
      _fill(const Color(0xff0b1522)),
    );
    for (var i = 0; i < 8; i++) {
      final y = -20.0 + i * 5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-28, y, 56, 3.2),
          const Radius.circular(1),
        ),
        _metal(Rect.fromLTWH(-28, y, 56, 3.2)),
      );
    }
    final head = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-23, -37, 47, 16),
      const Radius.circular(7),
    );
    canvas.drawRRect(head, _metal(head.outerRect));
    canvas.drawLine(
      const Offset(-15, -33),
      const Offset(16, -33),
      _stroke(const Color(0xfff1f9fb), 1),
    );
    _bolt(canvas, const Offset(-17, -25), radius: 1.8);
    _bolt(canvas, const Offset(18, -25), radius: 1.8);
    canvas.restore();

    final housing = Path()
      ..moveTo(276, 247)
      ..cubicTo(295, 239, 332, 247, 344, 264)
      ..cubicTo(355, 282, 338, 300, 308, 301)
      ..lineTo(282, 297)
      ..cubicTo(259, 292, 256, 260, 276, 247)
      ..close();
    canvas.drawPath(housing, _stroke(const Color(0xff07101b), 6));
    canvas.drawPath(housing, _metal(const Rect.fromLTWH(265, 244, 84, 57)));
    canvas.drawOval(
      const Rect.fromLTWH(275, 251, 52, 43),
      _metal(const Rect.fromLTWH(275, 251, 52, 43), vertical: false),
    );
    canvas.drawOval(
      const Rect.fromLTWH(277, 253, 48, 39),
      _stroke(const Color(0xffedfafb), .8),
    );
    for (final point in [
      const Offset(278, 253),
      const Offset(324, 255),
      const Offset(337, 278),
      const Offset(310, 295),
      const Offset(275, 286),
    ]) {
      _bolt(canvas, point, radius: 2);
    }
    _label(
      canvas,
      'MOTO',
      const Offset(286, 268),
      8,
      const Color(0xff455568),
      bold: true,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(342, 219, 15, 22),
        const Radius.circular(4),
      ),
      _metal(const Rect.fromLTWH(342, 219, 15, 22)),
    );
    _tube(
      canvas,
      Path()
        ..moveTo(354, 226)
        ..lineTo(367, 220)
        ..lineTo(365, 209),
      width: 3,
    );
  }

  void _exhaust(Canvas canvas) {
    final pipe = Path()
      ..moveTo(328, 226)
      ..cubicTo(360, 224, 363, 274, 345, 292)
      ..quadraticBezierTo(332, 307, 312, 307)
      ..lineTo(208, 307)
      ..lineTo(128, 287);
    canvas.drawPath(pipe, _stroke(const Color(0xff0a111b), 13));
    canvas.drawPath(pipe, _stroke(const Color(0xff8699a9), 10));
    canvas.drawPath(pipe, _stroke(const Color(0xffe1eef2), 5.5));
    canvas.drawPath(pipe, _stroke(const Color(0xff728592), 1.2));
    canvas.save();
    canvas.translate(164, 297);
    canvas.rotate(.24);
    final silencer = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-47, -8, 93, 16),
      const Radius.circular(6),
    );
    canvas.drawRRect(silencer, _metal(silencer.outerRect));
    canvas.drawLine(
      const Offset(-40, -5),
      const Offset(38, -5),
      _stroke(Colors.white, 1.2),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-50, -7, 8, 14),
      _fill(const Color(0xff354352)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-49, -4, 4, 8),
      _fill(const Color(0xff111b29)),
    );
    canvas.restore();
  }

  void _rearSuspension(Canvas canvas) {
    final fender = Path()
      ..moveTo(88, 236)
      ..cubicTo(111, 207, 159, 208, 188, 230);
    canvas.drawPath(fender, _stroke(const Color(0xff050d19), 12));
    canvas.drawPath(fender, _stroke(const Color(0xff43566b), 7));
    canvas.drawPath(fender, _stroke(const Color(0xffa4c0d1), 1));
    canvas.drawLine(
      const Offset(98, 230),
      const Offset(89, 250),
      _stroke(_black, 6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(84, 226, 12, 7),
        const Radius.circular(2),
      ),
      _fill(const Color(0xffef7868)),
    );
    canvas.save();
    canvas.translate(190, 213);
    canvas.rotate(.32);
    canvas.drawLine(Offset.zero, const Offset(0, 57), _stroke(_steel, 5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, 0, 12, 18),
        const Radius.circular(4),
      ),
      _metal(const Rect.fromLTWH(-6, 0, 12, 18)),
    );
    for (var i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(-6, 18.0 + i * 4),
        Offset(6, 21.0 + i * 4),
        _stroke(const Color(0xffc4d6e0), 2.2),
      );
    }
    _bolt(canvas, Offset.zero, radius: 3.3);
    _bolt(canvas, const Offset(0, 56), radius: 3.3);
    canvas.restore();
  }

  void _frontAssembly(Canvas canvas) {
    // Fork stanchions slant forward from the steering head to the wheel axle.
    canvas.drawLine(
      const Offset(399, 174),
      const Offset(450, 275),
      _stroke(const Color(0xff5d7589), 9),
    );
    canvas.drawLine(
      const Offset(410, 170),
      const Offset(459, 271),
      _stroke(const Color(0xffc5d9e4), 8),
    );
    canvas.drawLine(
      const Offset(406, 188),
      const Offset(423, 222),
      _stroke(const Color(0xff0a1320), 11),
    );
    canvas.drawLine(
      const Offset(417, 185),
      const Offset(434, 219),
      _stroke(const Color(0xff111c2b), 11),
    );
    for (var i = 0; i < 7; i++) {
      final y = 189.0 + i * 4.3;
      final x = 406 + i * 2.1;
      canvas.drawLine(
        Offset(x - 5, y + 2),
        Offset(x + 5, y - 2),
        _stroke(const Color(0xff657b8c), 1.2),
      );
      canvas.drawLine(
        Offset(x + 6, y - 1),
        Offset(x + 16, y - 5),
        _stroke(const Color(0xff53697b), 1.2),
      );
    }
    final fender = Path()
      ..moveTo(408, 239)
      ..cubicTo(432, 213, 475, 213, 497, 239);
    canvas.drawPath(fender, _stroke(const Color(0xff080f1c), 10));
    canvas.drawPath(fender, _stroke(const Color(0xff4e637a), 6));
    canvas.drawPath(fender, _stroke(const Color(0xffd1e8ef), 1.2));
    _bolt(canvas, const Offset(454, 274), radius: 4.4);

    // Headlamp shell and glass, with a warm inset reflector.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(398, 150, 28, 29),
        const Radius.circular(12),
      ),
      _metal(const Rect.fromLTWH(398, 150, 28, 29), vertical: false),
    );
    canvas.drawOval(
      const Rect.fromLTWH(416, 148, 15, 33),
      _fill(const Color(0xfff0f6e6)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(418, 152, 10, 25),
      _fill(const Color(0xffbfd8d9)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(416, 148, 15, 33),
      _stroke(const Color(0xffe4f0f4), 2.2),
    );
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(420, 155.0 + i * 5),
        Offset(426, 155.0 + i * 5),
        _stroke(const Color(0xff91afb6), .8),
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(401, 183, 12, 6),
      _fill(const Color(0xffffb54a)),
    );
    canvas.drawLine(
      const Offset(388, 145),
      const Offset(382, 130),
      _stroke(_steel, 4),
    );
    _tube(
      canvas,
      Path()
        ..moveTo(382, 130)
        ..lineTo(407, 126)
        ..lineTo(420, 117)
        ..lineTo(433, 119),
      width: 3.5,
    );
    canvas.drawLine(
      const Offset(427, 118),
      const Offset(443, 120),
      _stroke(_black, 7),
    );
    _tube(
      canvas,
      Path()
        ..moveTo(400, 128)
        ..lineTo(399, 109)
        ..lineTo(389, 103),
      width: 2,
    );
    canvas.drawOval(
      const Rect.fromLTWH(378, 96, 19, 10),
      _metal(const Rect.fromLTWH(378, 96, 19, 10)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(384, 135, 14, 11),
        const Radius.circular(4),
      ),
      _fill(const Color(0xff364e64)),
    );
  }

  void _saddle(Canvas canvas) {
    _tube(
      canvas,
      Path()
        ..moveTo(174, 183)
        ..lineTo(163, 181)
        ..quadraticBezierTo(153, 181, 155, 169)
        ..lineTo(170, 167),
      width: 3,
    );
    final seat = Path()
      ..moveTo(172, 169)
      ..cubicTo(191, 163, 211, 165, 232, 171)
      ..cubicTo(246, 174, 258, 174, 272, 169)
      ..quadraticBezierTo(282, 174, 278, 184)
      ..cubicTo(248, 192, 209, 187, 173, 184)
      ..quadraticBezierTo(166, 180, 172, 169)
      ..close();
    canvas.drawPath(seat, _stroke(const Color(0xff0b1321), 5));
    canvas.drawPath(
      seat,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(210, 165),
          const Offset(210, 189),
          const [Color(0xffe0b78d), Color(0xffac784d), Color(0xff795034)],
          const [0, .48, 1],
        ),
    );
    canvas.drawPath(
      Path()
        ..moveTo(176, 171)
        ..cubicTo(204, 168, 233, 184, 272, 175),
      _stroke(const Color(0xffebc79e), 1.1),
    );
    for (var i = 0; i < 10; i++) {
      final x = 181.0 + i * 8.5;
      canvas.drawLine(
        Offset(x, 178),
        Offset(x + 1, 182),
        _stroke(const Color(0xff744c32), .65),
      );
    }
  }

  void _tank(Canvas canvas) {
    final tank = Path()
      ..moveTo(276, 176)
      ..cubicTo(273, 150, 300, 136, 329, 136)
      ..cubicTo(357, 135, 377, 148, 382, 171)
      ..quadraticBezierTo(384, 185, 370, 190)
      ..lineTo(290, 189)
      ..quadraticBezierTo(276, 188, 276, 176)
      ..close();
    canvas.drawPath(tank, _stroke(const Color(0xff070f1c), 5));
    canvas.drawPath(
      tank,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(315, 136),
          const Offset(338, 190),
          const [Color(0xff627c94), Color(0xff1b2c45), Color(0xff0c172b)],
          const [0, .27, 1],
        ),
    );
    final trim = Path()
      ..moveTo(283, 176)
      ..cubicTo(284, 153, 302, 143, 330, 143)
      ..cubicTo(351, 143, 371, 153, 374, 174)
      ..quadraticBezierTo(376, 181, 367, 183)
      ..lineTo(294, 182);
    canvas.drawPath(trim, _stroke(_cyan.withValues(alpha: .9), 1.4));
    canvas.drawPath(
      Path()
        ..moveTo(294, 151)
        ..quadraticBezierTo(314, 138, 347, 147),
      _stroke(const Color(0xffdceff5), 2.4),
    );
    canvas.drawOval(
      const Rect.fromLTWH(319, 131, 21, 7),
      _metal(const Rect.fromLTWH(319, 131, 21, 7)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(315, 155, 26, 24),
      _fill(const Color(0xffc3aa75)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(318, 158, 20, 18),
      _fill(const Color(0xff182a3a)),
    );
    _label(
      canvas,
      'M',
      const Offset(322, 159),
      12,
      const Color(0xffecd8a6),
      bold: true,
    );
  }

  void _label(
    Canvas canvas,
    String value,
    Offset at,
    double size,
    Color color, {
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _MotorcyclePainter oldDelegate) =>
      oldDelegate.timeline != timeline;
}
