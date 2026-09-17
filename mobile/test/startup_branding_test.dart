import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motorstock_mobile/branding.dart';
import 'package:motorstock_mobile/main.dart';
import 'package:motorstock_mobile/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<MotorStore> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return MotorStore(await SharedPreferences.getInstance())..load();
}

void main() {
  testWidgets('startup shows brand while loading and retries failed loading', (
    tester,
  ) async {
    final store = await freshStore();
    final attempt = Completer<MotorStore>();
    var calls = 0;
    await tester.pumpWidget(
      MotorStockStartup(
        initializeStore: () {
          calls++;
          return calls == 1 ? attempt.future : Future.value(store);
        },
      ),
    );
    expect(find.byType(MotorStockSplash), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    attempt.completeError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(MotorStockWelcome), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restored session goes directly to its dashboard', (
    tester,
  ) async {
    final store = await freshStore();
    store.login(admin: true);
    await tester.pumpWidget(
      MotorStockStartup(initializeStore: () async => store),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('welcomeSignIn')), findsNothing);
  });

  testWidgets(
    'welcome and login remain usable on a small phone with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await freshStore();
      await tester.pumpWidget(MotorStockApp(store: store));
      await tester.pumpAndSettle();
      final start = find.byKey(const Key('welcomeSignIn'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('welcomeBack')));
      await tester.tap(find.byKey(const Key('welcomeBack')));
      await tester.pumpAndSettle();
      expect(find.byType(MotorStockWelcome), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
