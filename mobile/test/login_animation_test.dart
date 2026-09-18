import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motorstock_mobile/branding.dart';
import 'package:motorstock_mobile/main.dart';
import 'package:motorstock_mobile/screens.dart';
import 'package:motorstock_mobile/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder reveal(String words) => find.byWidgetPredicate(
  (widget) => widget is StaggeredTextReveal && widget.words == words,
);

List<double> wordOpacities(WidgetTester tester, Finder text) => tester
    .widgetList<Opacity>(
      find.descendant(of: text, matching: find.byType(Opacity)),
    )
    .map((widget) => widget.opacity)
    .toList();

Future<MotorStore> openLogin(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final store = MotorStore(await SharedPreferences.getInstance())..load();
  addTearDown(store.dispose);
  await tester.pumpWidget(MotorStockApp(store: store));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('welcomeSignIn')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('welcomeSignIn')));
  await tester.pump();
  return store;
}

void phoneSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('credentials and sign-in work while login copy reveals', (
    tester,
  ) async {
    phoneSize(tester, const Size(390, 844));
    final store = await openLogin(tester);

    expect(reveal('Welcome back'), findsOneWidget);
    expect(
      wordOpacities(tester, reveal('Welcome back')),
      contains(lessThan(1)),
    );

    final inputs = find.byType(TextField);
    await tester.enterText(inputs.at(0), 'admin@motorstock.demo');
    await tester.enterText(inputs.at(1), 'demo123');
    expect(
      tester.widget<TextField>(inputs.at(0)).controller!.text,
      'admin@motorstock.demo',
    );
    expect(tester.widget<TextField>(inputs.at(1)).controller!.text, 'demo123');
    expect(
      wordOpacities(tester, reveal('Welcome back')),
      contains(lessThan(1)),
    );

    await tester.ensureVisible(find.byKey(const Key('login')));
    await tester.tap(find.byKey(const Key('login')));
    await tester.pumpAndSettle();

    expect(store.signedIn, isTrue);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('password and role changes do not replay the login heading', (
    tester,
  ) async {
    phoneSize(tester, const Size(390, 844));
    await openLogin(tester);
    await tester.pumpAndSettle();
    expect(wordOpacities(tester, reveal('Welcome back')), everyElement(1));

    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isFalse,
    );
    expect(wordOpacities(tester, reveal('Welcome back')), everyElement(1));

    await tester.ensureVisible(find.byKey(const Key('loginRole')));
    await tester.tap(find.byKey(const Key('loginRole')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Showroom staff').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      'staff@motorstock.demo',
    );
    expect(wordOpacities(tester, reveal('Welcome back')), everyElement(1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion reveals login immediately on a small phone', (
    tester,
  ) async {
    phoneSize(tester, const Size(320, 640));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openLogin(tester);

    final loginReveals = find.byType(StaggeredTextReveal);
    expect(reveal('Welcome back'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    final opacities = wordOpacities(tester, loginReveals);
    expect(opacities, everyElement(1));
    expect(
      find.descendant(of: loginReveals, matching: find.byType(ImageFiltered)),
      findsNothing,
    );

    // One ordinary frame flushes the welcome button's outgoing ink response;
    // text reveals must not leave tickers running when motion is disabled.
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.ensureVisible(find.byKey(const Key('login')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('animated login stays usable on a small phone', (tester) async {
    phoneSize(tester, const Size(320, 640));
    await openLogin(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('login')));
    await tester.pump();
    expect(find.byKey(const Key('login')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
