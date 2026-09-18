import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motorstock_mobile/main.dart';
import 'package:motorstock_mobile/domain.dart';
import 'package:motorstock_mobile/store.dart';
import 'package:motorstock_mobile/invoice.dart';
import 'package:motorstock_mobile/branding.dart';

void main() {
  testWidgets('render phone previews and generate invoice PDF', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loader = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/roboto-regular.ttf'));
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
    SharedPreferences.setMockInitialValues({});
    final store = MotorStore(await SharedPreferences.getInstance())..load();
    final capture = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: MotorStockApp(store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MotorStockApp));
      await precacheImage(const AssetImage('assets/bike.png'), context);
      await precacheImage(
        const AssetImage('assets/motorstock-icon.png'),
        context,
      );
    });
    await tester.pumpAndSettle();
    Future<void> screenshot(String name) async {
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('artifacts').create(recursive: true);
        await File('artifacts/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await screenshot('welcome');
    await tester.tap(find.byKey(const Key('bikeAnimationToggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2800));
    await screenshot('welcome-disassembled');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcomeSignIn')));
    await tester.pumpAndSettle();
    await screenshot('login');
    await tester.tap(find.byKey(const Key('login')));
    await tester.pumpAndSettle();
    await screenshot('dashboard');
    for (final item in [
      ('Sales In', 'inventory'),
      ('Sales Out', 'sales'),
      ('Bill', 'billing'),
      ('Stores', 'stores'),
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(item.$1),
        ),
      );
      await tester.pumpAndSettle();
      await screenshot(item.$2);
      expect(tester.takeException(), isNull);
      if (item.$2 == 'billing') {
        await tester.scrollUntilVisible(
          find.byKey(const Key('addCustomerPhoto')),
          220,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await screenshot('billing-customer-photo');
        await tester.scrollUntilVisible(
          find.text('Charges & tax'),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await screenshot('billing-payment');
      }
    }
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Home'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appearanceMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appearanceDark')));
    await tester.pumpAndSettle();
    await screenshot('dashboard-dark');
    expect(store.appearance, 'Dark');
    for (final item in [
      ('Sales In', 'inventory-dark'),
      ('Bill', 'billing-dark'),
      ('Sales Out', 'sales-dark'),
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(item.$1),
        ),
      );
      await tester.pumpAndSettle();
      await screenshot(item.$2);
      expect(tester.takeException(), isNull);
      if (item.$2 == 'billing-dark') {
        await tester.tap(find.byType(DropdownButtonFormField<String>).last);
        await tester.pumpAndSettle();
        await screenshot('billing-dropdown-dark');
        expect(find.text('UPI'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
      }
    }
    final picturedInvoice = Sale.fromJson({
      ...store.sales.first.toJson(),
      'customerImage': 'assets/bike.png',
    });
    final pdf = await invoiceBytes(picturedInvoice);
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
    await tester.runAsync(() async {
      await File('artifacts/sample-invoice.pdf').writeAsBytes(pdf);
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MotorStockSplash(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await screenshot('splash');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
