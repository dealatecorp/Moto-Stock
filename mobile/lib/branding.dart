import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const brandTeal = Color(0xff007fa6);
const brandNavy = Color(0xff100947);
const brandLavender = Color(0xffe6dfff);

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
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
    ),
    child: Scaffold(
      backgroundColor: Colors.white,
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
                      border: Border.all(color: const Color(0xffe2e6f5)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xffe2e6f5)),
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
                        color: brandNavy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 5,
                    width: 64,
                    decoration: BoxDecoration(
                      color: brandTeal,
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
                      color: Color(0xff758196),
                    ),
                  ),
                  const SizedBox(height: 74),
                  if (error == null)
                    const SizedBox(
                      width: 238,
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        color: brandTeal,
                        backgroundColor: Color(0xffe7eaf1),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        semanticsLabel: 'Opening your showroom',
                      ),
                    )
                  else ...[
                    Text(error!, textAlign: TextAlign.center),
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
                      color: Color(0xff758196),
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
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: const Color(0xfff5f1ff),
    ),
    child: Scaffold(
      backgroundColor: brandLavender,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffe1d8ff), Color(0xffebe5ff), Color(0xfff5f1ff)],
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
                                  color: Colors.white.withValues(alpha: .8),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x10100947),
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
                                          color: brandNavy,
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
                                  const SizedBox(height: 30),
                                  const Text(
                                    'SMART DEALERSHIP MANAGEMENT',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xff607083),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      height: 1.7,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'MOTO STOCK',
                                      style: TextStyle(
                                        fontSize: 42,
                                        fontStyle: FontStyle.italic,
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.w900,
                                        color: brandNavy,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: (viewport.maxHeight * .25).clamp(
                                      152,
                                      260,
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned(
                                          bottom: 9,
                                          child: Container(
                                            width: 230,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x22100947),
                                                  blurRadius: 28,
                                                  spreadRadius: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const Positioned(
                                          top: 18,
                                          left: 5,
                                          child: _Helmet(angle: -.3),
                                        ),
                                        const Positioned(
                                          top: 2,
                                          right: 16,
                                          child: _Helmet(angle: .2),
                                        ),
                                        const Positioned(
                                          bottom: 16,
                                          right: 0,
                                          child: _Helmet(angle: -.2),
                                        ),
                                        Image.asset(
                                          'assets/bike.png',
                                          fit: BoxFit.contain,
                                          semanticLabel:
                                              'MotorStock motorcycle',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Your showroom.\nOne connected place.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 26,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -.6,
                                      color: brandNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Inventory, sales and your team.\nEverything you need, wherever you are.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xff657081),
                                      fontSize: 13,
                                      height: 1.6,
                                    ),
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
                                    backgroundColor: brandNavy,
                                    foregroundColor: Colors.white,
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
                                        color: Color(0xff73d7ed),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'BUILT FOR YOUR NEXT MILE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                    color: Color(0xff64748b),
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

class _Helmet extends StatelessWidget {
  final double angle;
  const _Helmet({required this.angle});

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .5)),
      ),
      child: const Icon(
        Icons.sports_motorsports_outlined,
        size: 24,
        color: Color(0xffa8c4d8),
      ),
    ),
  );
}
