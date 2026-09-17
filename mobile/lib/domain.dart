import 'dart:math' as math;

import 'package:intl/intl.dart';

final _money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
String money(num value) => _money.format(value);
String shortMoney(num value) => value >= 10000000
    ? '₹${(value / 10000000).toStringAsFixed(2)} Cr'
    : value >= 100000
    ? '₹${(value / 100000).toStringAsFixed(2)} L'
    : money(value);
String dateLabel(DateTime value) => DateFormat('dd MMM yyyy').format(value);
double rounded(num value) => (value * 100).round() / 100;
double emi(double principal, double annualRate, int months) {
  if (principal <= 0 || months <= 0) return 0;
  if (annualRate == 0) return rounded(principal / months);
  final r = annualRate / 1200;
  final power = math.pow(1 + r, months);
  return rounded(principal * r * power / (power - 1));
}

class Vehicle {
  final String id, name, brand, category, branch, vin, color, image;
  final int stock, year;
  final double price, cost;
  const Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.branch,
    required this.vin,
    required this.color,
    required this.stock,
    required this.price,
    required this.cost,
    required this.year,
    this.image = '',
  });
  String get status => stock == 0
      ? 'Out of stock'
      : stock <= 2
      ? 'Low stock'
      : 'In stock';
  Vehicle copy({int? stock, String? branch, String? id}) => Vehicle(
    id: id ?? this.id,
    name: name,
    brand: brand,
    category: category,
    branch: branch ?? this.branch,
    vin: vin,
    color: color,
    stock: stock ?? this.stock,
    price: price,
    cost: cost,
    year: year,
    image: image,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category,
    'branch': branch,
    'vin': vin,
    'color': color,
    'stock': stock,
    'price': price,
    'cost': cost,
    'year': year,
    'image': image,
  };
  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
    id: j['id'],
    name: j['name'],
    brand: j['brand'],
    category: j['category'],
    branch: j['branch'],
    vin: j['vin'],
    color: j['color'],
    stock: j['stock'],
    price: (j['price'] as num).toDouble(),
    cost: (j['cost'] as num).toDouble(),
    year: j['year'],
    image: j['image'] ?? '',
  );
}

class Branch {
  final String id, name, location;
  const Branch(this.id, this.name, this.location);
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
  };
  factory Branch.fromJson(Map<String, dynamic> j) =>
      Branch(j['id'], j['name'], j['location']);
}

class Staff {
  final String id, name, branch, role, shift;
  final bool frozen;
  const Staff({
    required this.id,
    required this.name,
    required this.branch,
    this.role = 'Sales Executive',
    this.shift = 'A',
    this.frozen = false,
  });
  Staff freeze() => Staff(
    id: id,
    name: name,
    branch: branch,
    role: role,
    shift: shift,
    frozen: !frozen,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'branch': branch,
    'role': role,
    'shift': shift,
    'frozen': frozen,
  };
  factory Staff.fromJson(Map<String, dynamic> j) => Staff(
    id: j['id'],
    name: j['name'],
    branch: j['branch'],
    role: j['role'],
    shift: j['shift'],
    frozen: j['frozen'],
  );
}

class BillDraft {
  final Vehicle vehicle;
  final String customer, phone, address, paymentMode, kind, employee;
  final int quantity, months;
  final double extras, repairCost, discount, taxRate, paid, interest;
  final bool finance;
  const BillDraft({
    required this.vehicle,
    required this.customer,
    required this.phone,
    required this.address,
    required this.employee,
    this.quantity = 1,
    this.extras = 0,
    this.repairCost = 0,
    this.discount = 0,
    this.taxRate = 0,
    this.paid = 0,
    this.paymentMode = 'UPI',
    this.kind = 'Vehicle sale',
    this.finance = false,
    this.interest = 9.5,
    this.months = 36,
  });
  double get subtotal =>
      rounded(vehicle.price * quantity + extras + repairCost);
  double get taxable => rounded(math.max(0, subtotal - discount));
  double get tax => rounded(taxable * taxRate / 100);
  double get total => rounded(taxable + tax);
  double get balance => rounded(math.max(0, total - paid));
  double get installment => finance ? emi(balance, interest, months) : 0;
}

class Sale {
  final String id,
      vehicleId,
      bike,
      branch,
      customer,
      phone,
      address,
      employee,
      mode,
      status,
      kind,
      staffId,
      vehicleImage;
  final DateTime date;
  final int quantity, months, emisPaid;
  final double unitPrice,
      extras,
      repairCost,
      subtotal,
      discount,
      taxRate,
      tax,
      total,
      paid,
      installment,
      interest;
  final bool finance;
  const Sale({
    required this.id,
    required this.vehicleId,
    required this.bike,
    required this.branch,
    required this.customer,
    required this.phone,
    required this.address,
    required this.employee,
    required this.date,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paid,
    this.staffId = '',
    this.vehicleImage = '',
    this.unitPrice = 0,
    this.extras = 0,
    this.repairCost = 0,
    this.taxRate = 0,
    this.quantity = 1,
    this.mode = 'UPI',
    this.status = 'Payment completed',
    this.kind = 'Vehicle sale',
    this.finance = false,
    this.months = 36,
    this.emisPaid = 0,
    this.installment = 0,
    this.interest = 9.5,
  });
  double get balance => rounded(math.max(0, total - paid));
  String get payment => balance <= 0
      ? 'Paid'
      : paid > 0
      ? 'Partial'
      : 'Pending';
  Sale copy({String? status, double? paid, int? emisPaid}) => Sale(
    id: id,
    vehicleId: vehicleId,
    bike: bike,
    branch: branch,
    customer: customer,
    phone: phone,
    address: address,
    employee: employee,
    date: date,
    subtotal: subtotal,
    discount: discount,
    tax: tax,
    total: total,
    paid: paid ?? this.paid,
    quantity: quantity,
    mode: mode,
    status: status ?? this.status,
    kind: kind,
    staffId: staffId,
    vehicleImage: vehicleImage,
    unitPrice: unitPrice,
    extras: extras,
    repairCost: repairCost,
    taxRate: taxRate,
    finance: finance,
    months: months,
    emisPaid: emisPaid ?? this.emisPaid,
    installment: installment,
    interest: interest,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'bike': bike,
    'branch': branch,
    'customer': customer,
    'phone': phone,
    'address': address,
    'employee': employee,
    'date': date.toIso8601String(),
    'subtotal': subtotal,
    'discount': discount,
    'tax': tax,
    'total': total,
    'paid': paid,
    'quantity': quantity,
    'mode': mode,
    'status': status,
    'kind': kind,
    'staffId': staffId,
    'vehicleImage': vehicleImage,
    'unitPrice': unitPrice,
    'extras': extras,
    'repairCost': repairCost,
    'taxRate': taxRate,
    'finance': finance,
    'months': months,
    'emisPaid': emisPaid,
    'installment': installment,
    'interest': interest,
  };
  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
    id: j['id'],
    vehicleId: j['vehicleId'],
    bike: j['bike'],
    branch: j['branch'],
    customer: j['customer'],
    phone: j['phone'],
    address: j['address'],
    employee: j['employee'],
    date: DateTime.parse(j['date']),
    subtotal: (j['subtotal'] as num).toDouble(),
    discount: (j['discount'] as num).toDouble(),
    tax: (j['tax'] as num).toDouble(),
    total: (j['total'] as num).toDouble(),
    paid: (j['paid'] as num).toDouble(),
    quantity: j['quantity'],
    mode: j['mode'],
    status: j['status'],
    kind: j['kind'],
    staffId: j['staffId'] ?? '',
    vehicleImage: j['vehicleImage'] ?? '',
    unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? 0,
    extras: (j['extras'] as num?)?.toDouble() ?? 0,
    repairCost: (j['repairCost'] as num?)?.toDouble() ?? 0,
    taxRate: (j['taxRate'] as num?)?.toDouble() ?? 0,
    finance: j['finance'],
    months: j['months'],
    emisPaid: j['emisPaid'],
    installment: (j['installment'] as num).toDouble(),
    interest: (j['interest'] as num).toDouble(),
  );
}
