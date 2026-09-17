import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motorstock_mobile/domain.dart';
import 'package:motorstock_mobile/screens.dart';
import 'package:motorstock_mobile/store.dart';
import 'package:motorstock_mobile/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<MotorStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return MotorStore(await SharedPreferences.getInstance())..load();
}

void main() {
  testWidgets('sale details displays the image saved with that sale', (
    tester,
  ) async {
    final store = await _store();
    final sale = store.sales.firstWhere((sale) => sale.vehicleImage.isNotEmpty);

    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: SaleDetail(store: store, saleId: sale.id),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<ItemImage>(
      find.byKey(const Key('saleItemImage')),
    );
    expect(image.source, sale.vehicleImage);
  });

  testWidgets('legacy sale falls back to its current inventory image', (
    tester,
  ) async {
    final store = await _store();
    final saleIndex = store.sales.indexWhere((sale) {
      return store.vehicles.any(
        (vehicle) => vehicle.id == sale.vehicleId && vehicle.image.isNotEmpty,
      );
    });
    final original = store.sales[saleIndex];
    store.sales[saleIndex] = Sale.fromJson({
      ...original.toJson(),
      'vehicleImage': '',
    });
    final inventoryImage = store.vehicles
        .firstWhere((vehicle) => vehicle.id == original.vehicleId)
        .image;

    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: SaleDetail(store: store, saleId: original.id),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<ItemImage>(
      find.byKey(const Key('saleItemImage')),
    );
    expect(image.source, inventoryImage);
  });
}
