import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bike_assembly.dart';

const brandTeal = Color(0xff007fa6);
const brandNavy = Color(0xff100947);

/// Flutter adaptation of Inspira UI's Text Generate Effect.
///
/// Every word keeps its final layout position while opacity, blur and vertical
/// offset animate in sequence. Reduced-motion settings reveal the text at once.
class StaggeredTextReveal extends StatefulWidget {
  final String words;
  final TextStyle? style;
  final bool enabled;
  final TextAlign textAlign;
  final bool filter;
  final Duration duration;
  final Duration delay;
  final Duration stagger;

  const StaggeredTextReveal({
    super.key,
    required this.words,
    this.style,
    this.enabled = true,
    this.textAlign = TextAlign.center,
    this.filter = true,
    this.duration = const Duration(milliseconds: 700),
    this.delay = Duration.zero,
    this.stagger = const Duration(milliseconds: 70),
  });

  @override
  State<StaggeredTextReveal> createState() => _StaggeredTextRevealState();
}

class _StaggeredTextRevealState extends State<StaggeredTextReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  List<String> get _words => widget.words
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    final wordCount = _words.length;
    final total =
        widget.delay +
        widget.duration +
        widget.stagger * (wordCount > 0 ? wordCount - 1 : 0);
    _controller = AnimationController(vsync: this, duration: total);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
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
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    if (!widget.enabled || reducedMotion) {
      return Text(widget.words, style: style, textAlign: widget.textAlign);
    }
    final lines = widget.words.split('\n');
    final alignment = switch (widget.textAlign) {
      TextAlign.left || TextAlign.start => WrapAlignment.start,
      TextAlign.right || TextAlign.end => WrapAlignment.end,
      _ => WrapAlignment.center,
    };
    return Semantics(
      label: widget.words,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final elapsed =
                _controller.value * (_controller.duration?.inMilliseconds ?? 1);
            var wordIndex = 0;
            Widget revealLine(String line) => Wrap(
              alignment: alignment,
              runAlignment: alignment,
              spacing: (style.fontSize ?? 14) * .24,
              runSpacing: 0,
              children: line
                  .trim()
                  .split(RegExp(r'\s+'))
                  .where((word) => word.isNotEmpty)
                  .map((text) {
                    final index = wordIndex++;
                    final start =
                        widget.delay.inMilliseconds +
                        widget.stagger.inMilliseconds * index;
                    final raw = _controller.isCompleted
                        ? 1.0
                        : ((elapsed - start) /
                                  (widget.duration.inMilliseconds > 0
                                      ? widget.duration.inMilliseconds
                                      : 1))
                              .clamp(0.0, 1.0);
                    final progress = Curves.easeOutCubic.transform(raw);
                    Widget word = Text(text, style: style);
                    if (widget.filter && !reducedMotion && progress < 1) {
                      word = ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: (1 - progress) * 5,
                          sigmaY: (1 - progress) * 5,
                        ),
                        child: word,
                      );
                    }
                    return Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(0, (1 - progress) * 8),
                        child: word,
                      ),
                    );
                  })
                  .toList(),
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: switch (widget.textAlign) {
                TextAlign.left || TextAlign.start => CrossAxisAlignment.start,
                TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
                _ => CrossAxisAlignment.center,
              },
              children: lines.map(revealLine).toList(),
            );
          },
        ),
      ),
    );
  }
}

class MotorStockMark extends StatelessWidget {
  final double size;
  const MotorStockMark({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .26),
    child: Image.asset(
      'assets/motorstock-icon.png',
      width: size,
      height: size,
      semanticLabel: 'MotorStock logo',
    ),
  );
}

class MotorStockSplash extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;
  const MotorStockSplash({super.key, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: brandNavy,
    ),
    child: Scaffold(
      backgroundColor: brandNavy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x3373d7ed)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: const Color(0x6673d7ed)),
                      ),
                      child: const MotorStockMark(size: 84),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'MOTO STOCK',
                      style: TextStyle(
                        fontSize: 33,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 5,
                    width: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xff73d7ed),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'SMART DEALERSHIP MANAGEMENT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.8,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff9da9cb),
                    ),
                  ),
                  const SizedBox(height: 74),
                  if (error == null)
                    const SizedBox(
                      width: 238,
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        color: Color(0xff73d7ed),
                        backgroundColor: Color(0xff34305d),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        semanticsLabel: 'Opening your showroom',
                      ),
                    )
                  else ...[
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 3,
                      color: Color(0xff9da9cb),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class MotorStockWelcome extends StatelessWidget {
  final VoidCallback onSignIn;
  const MotorStockWelcome({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: brandNavy,
    ),
    child: Scaffold(
      backgroundColor: brandNavy,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff09072a), Color(0xff171047), Color(0xff102652)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (viewport.maxHeight - 42).clamp(
                            0,
                            double.infinity,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  8,
                                  16,
                                  8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .14),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x35000000),
                                      blurRadius: 24,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MotorStockMark(size: 36),
                                    SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        'MOTO STOCK',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: .8,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 850),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 24),
                                  child: child,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: (viewport.maxHeight * .34).clamp(
                                      230,
                                      300,
                                    ),
                                    child: const BikeAssembly(),
                                  ),
                                  const SizedBox(height: 14),
                                  const Column(
                                    children: [
                                      StaggeredTextReveal(
                                        words: 'Your showroom.',
                                        delay: Duration(milliseconds: 180),
                                        style: TextStyle(
                                          fontSize: 26,
                                          height: 1.2,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -.6,
                                          color: Colors.white,
                                        ),
                                      ),
                                      StaggeredTextReveal(
                                        words: 'One connected place.',
                                        delay: Duration(milliseconds: 320),
                                        style: TextStyle(
                                          fontSize: 26,
                                          height: 1.2,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -.6,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton(
                                  key: const Key('welcomeSignIn'),
                                  onPressed: onSignIn,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Color(0xff73d7ed),
                                    foregroundColor: brandNavy,
                                    minimumSize: const Size(
                                      double.infinity,
                                      56,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Get started',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                        color: brandNavy,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
