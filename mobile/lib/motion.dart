import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A short, one-shot reveal. Rebuilding an existing tile never restarts it.
class MotionEntrance extends StatefulWidget {
  final Widget child;
  final int order;

  const MotionEntrance({super.key, required this.child, this.order = 0});

  @override
  State<MotionEntrance> createState() => _MotionEntranceState();
}

class _MotionEntranceState extends State<MotionEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final delay = widget.order.clamp(0, 5) * 45;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 420 + delay),
    );
    _progress = _controller.drive(
      CurveTween(
        curve: Interval(delay / (420 + delay), 1, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _progress.value,
      alwaysIncludeSemantics: true,
      child: Transform.translate(
        offset: Offset(0, 9 * (1 - _progress.value)),
        transformHitTests: false,
        child: Transform.scale(
          scale: .985 + .015 * _progress.value,
          transformHitTests: false,
          child: child,
        ),
      ),
    ),
  );
}

/// Observes pointer feedback without competing with the child's gestures.
/// Use for actionable tiles; normal buttons receive this effect from the theme.
class PressFeedback extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PressFeedback({super.key, required this.child, this.enabled = true});

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  int? _pointer;
  Offset? _origin;
  bool _pressed = false;

  void _release() {
    _pointer = null;
    _origin = null;
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pointer = null;
      _origin = null;
      _pressed = false;
    }
  }

  @override
  void didUpdateWidget(covariant PressFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _pointer = null;
      _origin = null;
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return Listener(
      onPointerDown: (event) {
        if (_pointer != null) return;
        _pointer = event.pointer;
        _origin = event.position;
        setState(() => _pressed = true);
      },
      onPointerMove: (event) {
        if (_pointer == event.pointer &&
            (event.position - _origin!).distance > 12) {
          _release();
        }
      },
      onPointerUp: (event) {
        if (_pointer == event.pointer) _release();
      },
      onPointerCancel: (event) {
        if (_pointer == event.pointer) _release();
      },
      child: AnimatedScale(
        scale: _pressed ? .977 : 1,
        duration: Duration(milliseconds: _pressed ? 100 : 260),
        curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Keeps outgoing content visible briefly, but never tappable or accessible.
class MotionSwitcher extends StatelessWidget {
  final Widget child;

  const MotionSwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [
          for (final previous in previousChildren)
            ExcludeFocus(
              child: ExcludeSemantics(child: IgnorePointer(child: previous)),
            ),
          ?currentChild,
        ],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .025),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Animates updates, never an artificial count from zero on first appearance.
/// Assistive technology always reads the final, accurate amount.
class AnimatedAmount extends StatelessWidget {
  final num value;
  final String Function(num) format;
  final TextStyle? style;

  const AnimatedAmount({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (!value.isFinite || MediaQuery.disableAnimationsOf(context)) {
      return Text(
        format(value),
        key: const ValueKey('static-amount'),
        style: style,
      );
    }
    return Semantics(
      key: const ValueKey('animated-amount'),
      label: format(value),
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: value.toDouble(), end: value.toDouble()),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, amount, _) => Text(format(amount), style: style),
        ),
      ),
    );
  }
}

/// Soft edge resistance for touch scrolling, without Android's stretch overlay.
class DealerScrollBehavior extends MaterialScrollBehavior {
  const DealerScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? const ClampingScrollPhysics()
      : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

/// Uses the native Cupertino navigation transition, respecting reduced motion.
class DealerPageTransitionsBuilder extends PageTransitionsBuilder {
  const DealerPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  DelegatedTransitionBuilder get delegatedTransition =>
      (context, animation, secondaryAnimation, allowSnapshotting, child) =>
          MediaQuery.disableAnimationsOf(context)
          ? child
          : CupertinoPageTransition.delegatedTransition(
              context,
              animation,
              secondaryAnimation,
              allowSnapshotting,
              child,
            );

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : const CupertinoPageTransitionsBuilder().buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}

/// Button states also cover keyboard activation and automatically skip disabled
/// controls, while the button itself keeps its full touch target.
Widget buttonPressLayer(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return child ?? const SizedBox.shrink();
  }
  final pressed = states.contains(WidgetState.pressed);
  return AnimatedScale(
    scale: pressed ? .96 : 1,
    duration: Duration(milliseconds: pressed ? 100 : 240),
    curve: pressed ? Curves.easeOutCubic : Curves.easeOutBack,
    child: child,
  );
}
