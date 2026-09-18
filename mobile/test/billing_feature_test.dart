import 'package:flutter_test/flutter_test.dart';
import 'package:motorstock_mobile/domain.dart';

void main() {
  const vehicle = Vehicle(
    id: 'vehicle-1',
    name: 'Test Motorcycle',
    brand: 'Test',
    category: 'Road',
    branch: 'Vizag Showroom',
    vin: 'VIN-001',
    color: 'Blue',
    stock: 2,
    price: 100000,
    cost: 80000,
    year: 2026,
    image: 'https://example.supabase.co/vehicle.jpg',
  );

  test('billing includes repair cost before discount and GST', () {
    const draft = BillDraft(
      vehicle: vehicle,
      customer: 'Customer',
      phone: '9000000000',
      address: 'Vizag',
      employee: 'Employee',
      extras: 5000,
      repairCost: 2000,
      discount: 7000,
      taxRate: 18,
      paid: 50000,
    );

    expect(draft.subtotal, 107000);
    expect(draft.taxable, 100000);
    expect(draft.tax, 18000);
    expect(draft.total, 118000);
    expect(draft.balance, 68000);
  });

  test('sale snapshots vehicle photo and detailed billing values', () {
    final sale = Sale(
      id: 'MS-2026-1',
      vehicleId: vehicle.id,
      bike: vehicle.name,
      branch: vehicle.branch,
      customer: 'Customer',
      phone: '9000000000',
      address: 'Vizag',
      employee: 'Employee',
      staffId: 'employee-1',
      vehicleImage: vehicle.image,
      customerImage: 'data:image/jpeg;base64,Y3VzdG9tZXI=',
      date: DateTime(2026, 9, 16),
      unitPrice: vehicle.price,
      extras: 5000,
      repairCost: 2000,
      subtotal: 107000,
      discount: 7000,
      taxRate: 18,
      tax: 18000,
      total: 118000,
      paid: 50000,
    );

    final restored = Sale.fromJson(sale.toJson());
    expect(restored.staffId, 'employee-1');
    expect(restored.vehicleImage, vehicle.image);
    expect(restored.customerImage, 'data:image/jpeg;base64,Y3VzdG9tZXI=');
    expect(restored.unitPrice, 100000);
    expect(restored.extras, 5000);
    expect(restored.repairCost, 2000);
    expect(restored.taxRate, 18);

    final legacy = sale.toJson()..remove('customerImage');
    expect(Sale.fromJson(legacy).customerImage, isEmpty);
  });
}
