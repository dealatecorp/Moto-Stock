import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motorstock_mobile/domain.dart';
import 'package:motorstock_mobile/forms.dart';
import 'package:motorstock_mobile/main.dart';
import 'package:motorstock_mobile/screens.dart';
import 'package:motorstock_mobile/store.dart';
import 'package:motorstock_mobile/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<MotorStore> setup(WidgetTester tester, {bool admin = true}) async {
  tester.view.physicalSize = const Size(320, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.textScaleFactorTestValue = 1.2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({});
  final store = MotorStore(await SharedPreferences.getInstance())..load();
  store.login(admin: admin);
  addTearDown(store.dispose);
  return store;
}

Future<void> choose(WidgetTester tester, String key, String value) async {
  final control = find.byKey(Key(key));
  await revealControl(tester, control);
  await tester.tap(control);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

Future<void> revealControl(WidgetTester tester, Finder control) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (control.evaluate().isEmpty) {
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      control,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(control);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String label, String value) async {
  final input = find.widgetWithText(TextFormField, label);
  await tester.scrollUntilVisible(
    input,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(input, value);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dark invoice dropdowns keep mobile-safe themed menus', (
    tester,
  ) async {
    final store = await setup(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: darkAppTheme,
        home: Scaffold(body: BillingPage(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    final dropdowns = tester
        .widgetList<DropdownButton<String>>(find.byType(DropdownButton<String>))
        .toList();
    expect(dropdowns, hasLength(2));
    for (final dropdown in dropdowns) {
      expect(dropdown.dropdownColor, darkRaised);
      expect(dropdown.isExpanded, isTrue);
      expect(dropdown.itemHeight, 52);
      expect(dropdown.menuMaxHeight, lessThanOrEqualTo(740 * .48));
    }

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Vizag Showroom'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'appearance selection updates, persists and keeps the new button map',
    (tester) async {
      final store = await setup(tester);
      await tester.pumpWidget(MotorStockApp(store: store));
      await tester.pumpAndSettle();
      final labels = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .map((item) => item.label)
          .toList();
      expect(labels, ['Home', 'Sales In', 'Bill', 'Sales Out', 'Stores']);

      await tester.tap(find.byKey(const Key('appearanceMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('appearanceDark')));
      await tester.pumpAndSettle();
      expect(store.appearance, 'Dark');
      expect(
        Theme.of(tester.element(find.byType(HomeScreen))).brightness,
        Brightness.dark,
      );
      expect(store.preferences.getString(MotorStore.appearanceKey), 'Dark');

      final restored = MotorStore(store.preferences)..load();
      addTearDown(restored.dispose);
      expect(restored.appearance, 'Dark');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inventory dropdowns filter stock and staff menus retain permissions',
    (tester) async {
      final store = await setup(tester, admin: false);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(body: InventoryPage(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      final bike = store.visibleVehicles.first;
      await choose(tester, 'inventoryCategory', bike.category);
      await choose(tester, 'inventoryStock', bike.status);
      final visible = store.visibleVehicles.where(
        (v) => v.category == bike.category && v.status == bike.status,
      );
      for (final v in visible) {
        expect(find.byKey(ValueKey(v.id)), findsOneWidget);
      }
      for (final v in store.visibleVehicles.where(
        (v) => v.category != bike.category || v.status != bike.status,
      )) {
        expect(find.byKey(ValueKey(v.id)), findsNothing);
      }
      final menu = find.byKey(ValueKey('vehicleActions-${bike.id}'));
      await tester.ensureVisible(menu);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.text('Edit bike'), findsOneWidget);
      expect(find.text('Transfer stock'), findsNothing);
      expect(find.text('Delete vehicle'), findsNothing);
      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();
      expect(find.byType(VehicleDetail), findsOneWidget);
      expect(find.text(bike.vin), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sales menus apply payment, sorting and showroom filters', (
    tester,
  ) async {
    final store = await setup(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: store,
            builder: (_, _) => SalesPage(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await choose(tester, 'salesPayment', 'Paid');
    await choose(tester, 'salesSort', 'Highest amount');
    final tiles = tester.widgetList<SaleTile>(find.byType(SaleTile)).toList();
    expect(tiles, isNotEmpty);
    expect(tiles.every((t) => t.sale.payment == 'Paid'), isTrue);
    final totals = tiles.map((t) => t.sale.total).toList();
    expect(totals, orderedEquals([...totals]..sort((a, b) => b.compareTo(a))));
    final branch = tiles.first.sale.branch;
    await choose(tester, 'branchPicker', branch);
    expect(store.selectedBranch, branch);
    expect(
      tester
          .widgetList<SaleTile>(find.byType(SaleTile))
          .every((t) => t.sale.branch == branch && t.sale.payment == 'Paid'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapsed charges keep values and reopen for invalid GST', (
    tester,
  ) async {
    final store = await setup(tester);
    final bike = store.vehicles.firstWhere((v) => v.stock > 0);
    final count = store.sales.length;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: BillingPage(store: store, initialVehicle: bike),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final addPhoto = find.byKey(const Key('addCustomerPhoto'));
    expect(addPhoto, findsOneWidget);
    await revealControl(tester, addPhoto);
    await tester.tap(addPhoto);
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Discount (₹)'), findsNothing);
    await enter(tester, 'Customer full name', 'Test Buyer');
    await enter(tester, 'Phone number', '9000000000');
    await enter(tester, 'Registration address', 'Test address');
    final disclosure = find.text('Charges & tax');
    await revealControl(tester, disclosure);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    await enter(tester, 'Discount (₹)', '1000');
    await enter(tester, 'GST rate (%)', '101');
    await revealControl(tester, disclosure);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'GST rate (%)'), findsNothing);
    final save = find.byKey(const Key('generateInvoice'));
    await revealControl(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'GST rate (%)'), findsOneWidget);
    expect(find.text('Enter a rate from 0 to 100'), findsOneWidget);
    expect(store.sales.length, count);
    expect(find.byType(AlertDialog), findsNothing);
    await enter(tester, 'GST rate (%)', '0');
    await revealControl(tester, disclosure);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    final total = find.byKey(const Key('invoiceTotal'));
    await tester.ensureVisible(total);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: total, matching: find.text(money(bike.price - 1000))),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
