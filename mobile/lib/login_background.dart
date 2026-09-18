import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'branding.dart' show brandNavy;
import 'ui.dart' show accent, isDarkMode;

/// A soft overhead glow that keeps the dealership's existing light palette.
/// The atmosphere settles once; form input is never part of the animation.
class LoginAtmosphere extends StatefulWidget {
  final Widget child;

  const LoginAtmosphere({super.key, required this.child});

  @override
  State<LoginAtmosphere> createState() => _LoginAtmosphereState();
}

class _LoginAtmosphereState extends State<LoginAtmosphere>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _progress;
  bool _settled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller?.dispose();
      _controller = null;
      _progress = null;
      _settled = true;
    } else if (!_settled && _controller == null) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );
      _controller = controller;
      _progress = controller.drive(CurveTween(curve: Curves.easeOutCubic));
      controller.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final dark = isDarkMode(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: progress == null
                      ? CustomPaint(
                          painter: _LoginGlowPainter(progress: 1, dark: dark),
                        )
                      : AnimatedBuilder(
                          animation: progress,
                          builder: (context, _) => CustomPaint(
                            painter: _LoginGlowPainter(
                              progress: progress.value,
                              dark: dark,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _LoginGlowPainter extends CustomPainter {
  final double progress;
  final bool dark;

  const _LoginGlowPainter({required this.progress, required this.dark});

  void _glow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radiusX,
    required double radiusY,
    required List<Color> colors,
    required List<double> stops,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(radiusX, radiusY);
    final paint = Paint()
      ..shader = ui.Gradient.radial(Offset.zero, 1, colors, stops);
    canvas.drawRect(
      Rect.fromLTWH(
        -center.dx / radiusX,
        -center.dy / radiusY,
        size.width / radiusX,
        size.height / radiusY,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final strength = .72 + .28 * progress;

    // A broad elliptical wash avoids a visible circular edge on tall phones.
    _glow(
      canvas,
      size,
      center: Offset(size.width * .5, size.height * (.035 + .025 * progress)),
      radiusX: size.width * .94,
      radiusY: size.height * .55,
      colors: [
        accent.withValues(alpha: (dark ? .38 : .32) * strength),
        accent.withValues(alpha: (dark ? .20 : .18) * strength),
        accent.withValues(alpha: (dark ? .07 : .055) * strength),
        accent.withValues(alpha: 0),
      ],
      stops: const [0, .28, .62, 1],
    );

    // Restrained corner depth frames the glow without darkening the form.
    _glow(
      canvas,
      size,
      center: Offset(-size.width * .16, -size.height * .07),
      radiusX: size.width * .74,
      radiusY: size.height * .42,
      colors: [
        (dark ? Colors.black : brandNavy).withValues(
          alpha: (dark ? .28 : .065) * strength,
        ),
        brandNavy.withValues(alpha: (dark ? .08 : .018) * strength),
        brandNavy.withValues(alpha: 0),
      ],
      stops: const [0, .42, 1],
    );
    _glow(
      canvas,
      size,
      center: Offset(size.width * 1.14, size.height * .12),
      radiusX: size.width * .55,
      radiusY: size.height * .48,
      colors: [
        brandNavy.withValues(alpha: .035 * strength),
        brandNavy.withValues(alpha: 0),
      ],
      stops: const [0, 1],
    );
  }

  @override
  bool shouldRepaint(covariant _LoginGlowPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.dark != dark;
}
