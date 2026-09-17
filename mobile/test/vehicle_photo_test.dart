import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motorstock_mobile/domain.dart';
import 'package:motorstock_mobile/forms.dart';
import 'package:motorstock_mobile/store.dart';
import 'package:motorstock_mobile/ui.dart';

void main() {
  test('local vehicle photo is retained in persisted inventory', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = MotorStore(prefs)..load();
    final bike = store.vehicles.first;
    final bytes = Uint8List.fromList([0xff, 0xd8, 0xff]);
    final image = await store.saveVehicleImage(
      bytes: bytes,
      contentType: 'image/jpeg',
      extension: 'jpg',
      vehicleId: bike.id,
      branchName: bike.branch,
    );
    await store.saveVehicle(
      Vehicle.fromJson({...bike.toJson(), 'image': image}),
    );
    final restored = MotorStore(prefs)..load();
    expect(
      UriData.parse(restored.vehicles.first.image).contentAsBytes(),
      bytes,
    );
    await expectLater(
      store.saveVehicleImage(
        bytes: Uint8List((1 << 20) + 1),
        contentType: 'image/jpeg',
        extension: 'jpg',
        vehicleId: bike.id,
        branchName: bike.branch,
      ),
      throwsStateError,
    );
  });

  testWidgets('editing offers camera, gallery and removes photo preview', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = MotorStore(await SharedPreferences.getInstance())..load();
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: VehicleForm(
          store: store,
          vehicle: store.vehicles.firstWhere(
            (vehicle) => vehicle.image.isNotEmpty,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vehicleCamera')), findsOneWidget);
    expect(find.byKey(const Key('vehicleGallery')), findsOneWidget);
    expect(find.byType(BikeImage), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.byType(BikeImage), findsNothing);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
