import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motorstock_mobile/domain.dart';
import 'package:motorstock_mobile/forms.dart';
import 'package:motorstock_mobile/main.dart';
import 'package:motorstock_mobile/motion.dart';
import 'package:motorstock_mobile/screens.dart';
import 'package:motorstock_mobile/store.dart';
import 'package:motorstock_mobile/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<MotorStore> motionStore() async {
  SharedPreferences.setMockInitialValues({});
  final store = MotorStore(await SharedPreferences.getInstance())..load();
  store.login(admin: true);
  addTearDown(store.dispose);
  return store;
}

void motionPhone(WidgetTester tester, {bool reducedMotion = false}) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (reducedMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
}

Finder destination(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Future<void> enterBillingNumber(
  WidgetTester tester,
  String label,
  String value,
) async {
  final input = find.widgetWithText(TextFormField, label);
  await tester.scrollUntilVisible(
    input,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(input, value);
  await tester.pump();
}

void main() {
  testWidgets(
    'cancelled or dragged presses release feedback without activating',
    (tester) async {
      var taps = 0;
      const target = Key('pressTarget');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressFeedback(
                child: GestureDetector(
                  key: target,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const SizedBox(width: 100, height: 100),
                ),
              ),
            ),
          ),
        ),
      );
      final pressed = find.byType(AnimatedScale);
      final pointer = await tester.startGesture(
        tester.getCenter(find.byKey(target)),
      );
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.widget<AnimatedScale>(pressed).scale, lessThan(1));
      await pointer.cancel();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(pressed).scale, 1);
      expect(taps, 0);

      final dragged = await tester.startGesture(
        tester.getCenter(find.byKey(target)),
      );
      await dragged.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(tester.widget<AnimatedScale>(pressed).scale, 1);
      await dragged.cancel();
      await tester.tap(find.byKey(target));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion exposes final content and amounts in one frame', (
    tester,
  ) async {
    motionPhone(tester, reducedMotion: true);
    final amount = ValueNotifier<num>(1250);
    addTearDown(amount.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<num>(
            valueListenable: amount,
            builder: (context, value, _) => MotionEntrance(
              child: PressFeedback(
                child: MotionSwitcher(
                  child: AnimatedAmount(
                    key: ValueKey(value),
                    value: value,
                    format: money,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text(money(1250)), findsOneWidget);
    amount.value = 2450;
    await tester.pump();
    expect(find.text(money(2450)), findsOneWidget);
    expect(find.text(money(1250)), findsNothing);
    expect(
      tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((widget) => widget.opacity),
      everyElement(1),
    );
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an invalid amount does not contaminate later valid animated totals',
    (tester) async {
      final amount = ValueNotifier<num>(1250);
      addTearDown(amount.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<num>(
              valueListenable: amount,
              builder: (context, value, _) => AnimatedAmount(
                value: value,
                format: (number) =>
                    number.isFinite ? money(number) : 'Unavailable',
              ),
            ),
          ),
        ),
      );
      for (final invalid in [double.nan, double.infinity]) {
        amount.value = invalid;
        await tester.pump();
        expect(find.text('Unavailable'), findsOneWidget);
        amount.value = 2450;
        await tester.pumpAndSettle();
        expect(find.text(money(2450)), findsOneWidget);
        expect(find.text('Unavailable'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rapid tab switches keep search and only expose the current page',
    (tester) async {
      motionPhone(tester);
      final store = await motionStore();
      await tester.pumpWidget(MotorStockApp(store: store));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'initial dashboard');
      await tester.tap(destination('Sales In'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'inventory opened');
      await tester.enterText(
        find.byKey(const Key('inventorySearch')),
        'no-matching-motorcycle',
      );
      await tester.pumpAndSettle();
      expect(find.text('No bikes found'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'inventory filtered');

      for (final label in ['Bill', 'Sales Out', 'Stores', 'Home', 'Sales In']) {
        await tester.tap(destination(label));
        await tester.pump(const Duration(milliseconds: 40));
        expect(tester.takeException(), isNull, reason: label);
      }

      final search = find.byKey(const Key('inventorySearch'));
      expect(search.hitTestable(), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(of: search, matching: find.byType(EditableText)),
            )
            .controller
            .text,
        'no-matching-motorcycle',
      );
      expect(find.text('No bikes found'), findsOneWidget);
      expect(
        find.byKey(const Key('generateInvoice')).hitTestable(),
        findsNothing,
      );
      expect(find.text('Create invoice').hitTestable(), findsNothing);
      await tester.enterText(search, '');
      await tester.pumpAndSettle();
      expect(find.text('No bikes found'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dashboard filters and chart selection work with reduced motion and large text',
    (tester) async {
      motionPhone(tester, reducedMotion: true);
      tester.platformDispatcher.textScaleFactorTestValue = 1.2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await motionStore();
      final now = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: Dashboard(store: store, go: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final period = find.byKey(const Key('dashboardPeriod'));
      await tester.ensureVisible(period);
      await tester.pump();
      await tester.tap(period);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Today').last);
      await tester.pumpAndSettle();

      final todayRevenue = store.visibleSales
          .where(
            (sale) =>
                sale.status != 'Cancelled' &&
                sale.date.year == now.year &&
                sale.date.month == now.month &&
                sale.date.day == now.day,
          )
          .fold<double>(0, (sum, sale) => sum + sale.total);
      final metric = find.byWidgetPredicate(
        (widget) => widget is Metric && widget.label == 'Revenue',
      );
      expect(
        find.descendant(
          of: metric,
          matching: find.text(shortMoney(todayRevenue)),
        ),
        findsOneWidget,
      );

      final firstBar = find.byKey(const Key('revenueWeek0'));
      await tester.scrollUntilVisible(
        firstBar,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(firstBar);
      await tester.pump();
      final oldestWeek = store.visibleSales.where((sale) {
        final age = now.difference(sale.date).inDays;
        return sale.status != 'Cancelled' && age >= 21 && age < 28;
      }).toList();
      expect(
        find.text('Week 1 · ${oldestWeek.length} invoices'),
        findsOneWidget,
      );
      final chartAmount = find.descendant(
        of: find.byType(RevenueChart),
        matching: find.byType(AnimatedAmount),
      );
      expect(
        find.descendant(
          of: chartAmount,
          matching: find.text(
            money(oldestWeek.fold<double>(0, (sum, sale) => sum + sale.total)),
          ),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced-motion billing keeps accurate totals and usable finance fields',
    (tester) async {
      motionPhone(tester, reducedMotion: true);
      tester.platformDispatcher.textScaleFactorTestValue = 1.2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await motionStore();
      final bike = store.vehicles.firstWhere((vehicle) => vehicle.stock > 0);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: BillingPage(store: store, initialVehicle: bike),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final charges = find.byKey(const Key('billingCharges'));
      await tester.scrollUntilVisible(
        charges,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: charges, matching: find.text('Charges & tax')),
      );
      await tester.pumpAndSettle();
      await enterBillingNumber(tester, 'Discount (₹)', '1000');
      await enterBillingNumber(tester, 'Amount received (₹)', '10000');

      final toggle = find.byKey(const Key('financeToggle'));
      await tester.ensureVisible(toggle);
      await tester.pump();
      await tester.tap(toggle);
      await tester.pump();
      final interest = find.widgetWithText(
        TextFormField,
        'Annual interest rate (%)',
      );
      expect(interest, findsOneWidget);
      await tester.ensureVisible(interest);
      await tester.enterText(interest, '0');
      await tester.pump();

      final total = find.byKey(const Key('invoiceTotal'));
      final balance = find.byKey(const Key('invoiceBalance'));
      await tester.ensureVisible(balance);
      await tester.pump();
      expect(
        find.descendant(
          of: total,
          matching: find.text(money(bike.price - 1000)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: balance,
          matching: find.text(money(bike.price - 11000)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('invoiceEmi')),
          matching: find.text(money((bike.price - 11000) / 36)),
        ),
        findsOneWidget,
      );

      await tester.ensureVisible(toggle);
      await tester.pump();
      await tester.tap(toggle);
      await tester.pump();
      expect(interest, findsNothing);
      expect(find.text('Estimated monthly EMI'), findsNothing);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
