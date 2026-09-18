import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motorstock_mobile/bike_assembly.dart';
import 'package:motorstock_mobile/branding.dart';
import 'package:motorstock_mobile/ui.dart';

Widget assemblyApp() => MaterialApp(
  theme: appTheme,
  home: const Scaffold(
    body: Center(
      child: SizedBox(width: 320, height: 260, child: BikeAssembly()),
    ),
  ),
);

void bikePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('bike assembly pauses, resumes, finishes, and replays', (
    tester,
  ) async {
    await tester.pumpWidget(assemblyApp());
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byTooltip('Pause bike animation'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bikeAnimationToggle')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Play bike animation'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(find.byTooltip('Play bike animation'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);

    await tester.tap(find.byKey(const Key('bikeAnimationToggle')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Replay bike animation'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.tap(find.byKey(const Key('bikeAnimationToggle')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byTooltip('Pause bike animation'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Replay bike animation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backgrounding suspends assembly without undoing a user pause', (
    tester,
  ) async {
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await tester.pumpWidget(assemblyApp());
    await tester.pump(const Duration(milliseconds: 800));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 8));
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byTooltip('Pause bike animation'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bikeAnimationToggle')));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 8));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Play bike animation'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.tap(find.byKey(const Key('bikeAnimationToggle')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Replay bike animation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows the assembled bike without autoplay', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    bikePhone(tester);
    await tester.pumpWidget(assemblyApp());
    await tester.pump();
    expect(find.byTooltip('Pause bike animation'), findsNothing);
    expect(find.byTooltip('Replay bike animation'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(seconds: 8));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.tap(find.byKey(const Key('bikeAnimationToggle')));
    await tester.pump();
    expect(find.byTooltip('Pause bike animation'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Replay bike animation'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Get started works during assembly and leaving disposes its ticker',
    (tester) async {
      bikePhone(tester);
      var entered = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: StatefulBuilder(
            builder: (context, setState) => entered
                ? const Scaffold(body: Text('Showroom opened'))
                : MotorStockWelcome(
                    onSignIn: () => setState(() => entered = true),
                  ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BikeAssembly), findsOneWidget);
      final start = find.byKey(const Key('welcomeSignIn'));
      await tester.ensureVisible(start);
      await tester.pump();
      expect(start.hitTestable(), findsOneWidget);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(entered, isTrue);
      expect(find.text('Showroom opened'), findsOneWidget);
      expect(find.byType(BikeAssembly), findsNothing);
      await tester.pump(const Duration(seconds: 8));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
