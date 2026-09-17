import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motorstock_mobile/main.dart';
import 'package:motorstock_mobile/store.dart';
import 'package:motorstock_mobile/domain.dart';
import 'package:motorstock_mobile/forms.dart';
import 'package:motorstock_mobile/screens.dart';
import 'package:motorstock_mobile/ui.dart';

Future<MotorStore> fresh() async {
  SharedPreferences.setMockInitialValues({});
  return MotorStore(await SharedPreferences.getInstance())..load();
}

void main() {
  test('EMI handles zero interest and standard amortization', () {
    expect(emi(120000, 0, 12), 10000);
    expect(emi(100000, 12, 12), closeTo(8884.88, .01));
    expect(emi(0, 12, 12), 0);
  });
  test('invoice reserves stock, persists, and rejects overpayments', () async {
    final store = await fresh();
    final bike = store.vehicles.first;
    final sale = await store.createSale(
      BillDraft(
        vehicle: bike,
        customer: 'Test Buyer',
        phone: '9000000000',
        address: 'Vizag',
        employee: 'Admin',
        paid: 1000,
      ),
    );
    expect(store.vehicles.first.stock, bike.stock - 1);
    expect(sale.balance, bike.price - 1000);
    final restored = MotorStore(store.preferences)..load();
    expect(restored.sales.any((s) => s.id == sale.id), true);
    await expectLater(
      store.recordPayment(sale, sale.balance + 1),
      throwsStateError,
    );
    expect(store.sales.last.paid, 1000);
    await store.recordPayment(sale, sale.balance);
    expect(store.sales.last.balance, 0);
  });
  test('out of stock invoice leaves state unchanged', () async {
    final store = await fresh();
    final bike = store.vehicles.firstWhere((v) => v.stock == 0);
    final before = store.sales.length;
    await expectLater(
      store.createSale(
        BillDraft(
          vehicle: bike,
          customer: 'Test',
          phone: '9000000000',
          address: 'Test',
          employee: 'Admin',
        ),
      ),
      throwsStateError,
    );
    expect(store.sales.length, before);
  });
  test(
    'partial transfer preserves total stock and branch boundaries',
    () async {
      final store = await fresh();
      final total = store.vehicles.fold(0, (a, b) => a + b.stock);
      final bike = store.vehicles.first;
      await store.transfer(bike, 'Vizag Showroom', 2);
      expect(store.vehicles.fold(0, (a, b) => a + b.stock), total);
      store.login(admin: false);
      expect(
        store.visibleVehicles.every((v) => v.branch == 'Vizag Showroom'),
        true,
      );
      await expectLater(
        store.deleteVehicle(store.vehicles.last),
        throwsStateError,
      );
    },
  );
  testWidgets('login, all five destinations, and phone layout', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await fresh();
    await tester.pumpWidget(MotorStockApp(store: store));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('welcomeSignIn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('welcomeSignIn')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.byKey(const Key('login')));
    await tester.pumpAndSettle();
    expect(find.text('Network snapshot'), findsOneWidget);
    expect(find.text('New vehicle'), findsNothing);
    expect(tester.takeException(), isNull);
    for (final label in [
      'Sale In',
      'Sale Out',
      'Billing',
      'Stores',
      'Dashboard',
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Sale In'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('inventorySearch')),
      'not-a-bike',
    );
    await tester.pumpAndSettle();
    expect(find.text('No vehicles found'), findsOneWidget);
  });
  testWidgets(
    'store opens its employees and employee statistics on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await fresh();
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: StoresPage(store: store),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('store-b1')));
      await tester.pumpAndSettle();
      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(find.text('P. Rajesh'), findsNothing);
      await tester.tap(find.byKey(const Key('employee-EMP-001')));
      await tester.pumpAndSettle();
      expect(find.text('Employee statistics'), findsOneWidget);
      expect(find.text('Invoiced revenue'), findsOneWidget);
      expect(find.text('Collected'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test('employee statistics respect staff ID, branch, cancellations and legacy records', () {
    const employee = Staff(id: 'e1', name: 'Ravi', branch: 'Vizag');
    Sale sale(
      String id, {
      String staffId = '',
      String name = 'Ravi',
      String branch = 'Vizag',
      String status = 'Delivered',
    }) => Sale(
      id: id,
      vehicleId: 'v1',
      bike: 'Bike',
      branch: branch,
      customer: 'Buyer',
      phone: '9000000000',
      address: 'City',
      employee: name,
      staffId: staffId,
      date: DateTime(2026, 9, 16),
      subtotal: 100,
      discount: 0,
      tax: 0,
      total: 100,
      paid: 50,
      status: status,
    );
    final rows = EmployeeStatsPage.salesFor([
      sale('matched-id', staffId: 'e1', name: 'Old name'),
      sale('legacy'),
      sale('other-id', staffId: 'e2'),
      sale('other-branch', staffId: 'e1', branch: 'Guntur'),
      sale('cancelled', staffId: 'e1', status: 'Cancelled'),
    ], employee);
    expect(rows.map((s) => s.id), unorderedEquals(['matched-id', 'legacy']));
  });
  testWidgets('intake form validates and saves a vehicle', (tester) async {
    final store = await fresh();
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: VehicleForm(store: store),
      ),
    );
    await tester.pumpAndSettle();
    for (final entry in {
      'Make & model': 'Test Motorcycle',
      'Brand': 'Test',
      'VIN / Stock identifier': 'TEST-VIN-NEW',
      'Color': 'Blue',
    }.entries) {
      final input = find.widgetWithText(TextFormField, entry.key);
      await tester.scrollUntilVisible(
        input,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(input, entry.value);
    }
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Purchase cost per unit (₹)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Purchase cost per unit (₹)'),
      '100000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Selling price per unit (₹)'),
      '120000',
    );
    await tester.ensureVisible(find.byKey(const Key('saveVehicle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveVehicle')));
    await tester.pumpAndSettle();
    expect(store.vehicles.any((v) => v.vin == 'TEST-VIN-NEW'), true);
  });
  testWidgets('EMI and team screens render on narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: appTheme, home: const EmiPage()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final store = await fresh();
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: StoresPage(store: store),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
