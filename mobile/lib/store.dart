import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'domain.dart';
import 'supabase_backend.dart';

class MotorStore extends ChangeNotifier {
  MotorStore(this.preferences, {this.remote});
  final SharedPreferences preferences;
  final SupabaseMotorRepository? remote;
  static const storageKey = 'motorstock_demo_v1';
  List<Vehicle> vehicles = [];
  List<Sale> sales = [];
  List<Branch> branches = [];
  List<Staff> staff = [];
  bool signedIn = false, isAdmin = true;
  String _userName = 'Network Admin';
  String _userBranch = '';
  String selectedBranch = 'All branches';
  bool get usesSupabase => remote != null;
  String get userName => _userName;
  String get userInitials {
    final words = _userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'MS';
    if (words.length == 1) {
      final end = words.first.length >= 2 ? 2 : 1;
      return words.first.substring(0, end).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  String get userBranch => _userBranch.isNotEmpty
      ? _userBranch
      : branches.isNotEmpty
      ? branches.first.name
      : '';
  String get effectiveBranch => isAdmin ? selectedBranch : userBranch;
  bool get allBranches => effectiveBranch == 'All branches';
  List<Vehicle> get visibleVehicles => vehicles
      .where((v) => allBranches || v.branch == effectiveBranch)
      .toList();
  List<Sale> get visibleSales =>
      sales.where((s) => allBranches || s.branch == effectiveBranch).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  List<String> get branchNames => branches.map((b) => b.name).toList();

  Future<void> initialize() async {
    if (remote == null) {
      load();
      return;
    }
    final profile = await remote!.restoreProfile();
    if (profile == null) return;
    await _openRemoteSession(profile);
  }

  void load() {
    final saved = preferences.getString(storageKey);
    if (saved == null) {
      seed();
      return;
    }
    try {
      _restore(jsonDecode(saved) as Map<String, dynamic>);
    } catch (_) {
      seed();
    }
  }

  void _restore(Map<String, dynamic> j) {
    vehicles = (j['vehicles'] as List)
        .map((v) => Vehicle.fromJson(Map<String, dynamic>.from(v)))
        .toList();
    sales = (j['sales'] as List)
        .map((v) => Sale.fromJson(Map<String, dynamic>.from(v)))
        .toList();
    branches = (j['branches'] as List)
        .map((v) => Branch.fromJson(Map<String, dynamic>.from(v)))
        .toList();
    staff = (j['staff'] as List)
        .map((v) => Staff.fromJson(Map<String, dynamic>.from(v)))
        .toList();
  }

  Map<String, dynamic> snapshot() => {
    'vehicles': vehicles.map((v) => v.toJson()).toList(),
    'sales': sales.map((s) => s.toJson()).toList(),
    'branches': branches.map((s) => s.toJson()).toList(),
    'staff': staff.map((s) => s.toJson()).toList(),
  };
  Future<void> _change(
    void Function() action, {
    Future<void> Function()? sync,
  }) async {
    final before = snapshot();
    try {
      action();
      if (remote != null) {
        if (sync == null) {
          throw StateError('This cloud operation is not configured.');
        }
        await sync();
      } else {
        if (!await preferences.setString(storageKey, jsonEncode(snapshot()))) {
          throw StateError('Unable to save changes on this device.');
        }
      }
    } catch (_) {
      _restore(before);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> loginWithPassword(
    String email,
    String password, {
    bool demoAdmin = true,
  }) async {
    if (remote == null) {
      final expected = demoAdmin
          ? 'admin@motorstock.demo'
          : 'staff@motorstock.demo';
      if (email.trim() != expected || password != 'demo123') {
        throw StateError('Use the demo credentials shown below.');
      }
      login(admin: demoAdmin);
      return;
    }
    final identifier = email.trim();
    final loginEmail = identifier.toLowerCase() == 'demo'
        ? 'demo@motorstock.app'
        : identifier;
    final profile = await remote!.signIn(loginEmail, password);
    await _openRemoteSession(profile);
  }

  Future<void> _openRemoteSession(MotorProfile profile) async {
    final data = await remote!.loadSnapshot();
    branches = data.branches;
    vehicles = data.vehicles;
    sales = data.sales;
    staff = data.staff;
    isAdmin = profile.isAdmin;
    _userName = profile.name;
    _userBranch = profile.branchName;
    selectedBranch = 'All branches';
    signedIn = true;
    notifyListeners();
  }

  void login({bool admin = true}) {
    signedIn = true;
    isAdmin = admin;
    _userName = admin ? 'Network Admin' : 'Ravi Kumar';
    _userBranch = admin || branches.isEmpty ? '' : branches.first.name;
    selectedBranch = 'All branches';
    notifyListeners();
  }

  Future<void> refresh() async {
    if (remote == null || !signedIn) return;
    final data = await remote!.loadSnapshot();
    branches = data.branches;
    vehicles = data.vehicles;
    sales = data.sales;
    staff = data.staff;
    notifyListeners();
  }

  Future<void> logout() async {
    if (remote != null) await remote!.signOut();
    signedIn = false;
    notifyListeners();
  }

  void chooseBranch(String name) {
    selectedBranch = name;
    notifyListeners();
  }

  void _requireAdmin() {
    if (!isAdmin) throw StateError('Admin access is required.');
  }

  void _checkBranch(String name) {
    if (!branchNames.contains(name) || (!isAdmin && name != userBranch)) {
      throw StateError('This showroom is not accessible.');
    }
  }

  Future<void> reset() {
    if (remote != null) {
      throw StateError('Cloud data cannot be reset from the mobile app.');
    }
    return _change(seed);
  }

  Future<void> saveVehicle(Vehicle v) => _change(() {
    _checkBranch(v.branch);
    if (v.name.trim().isEmpty ||
        v.vin.trim().isEmpty ||
        v.stock < 0 ||
        v.price <= 0 ||
        v.cost < 0) {
      throw StateError('Enter valid vehicle details.');
    }
    if (vehicles.any(
      (b) => b.id != v.id && b.vin.toLowerCase() == v.vin.toLowerCase(),
    )) {
      throw StateError('This VIN / stock identifier already exists.');
    }
    final i = vehicles.indexWhere((b) => b.id == v.id);
    if (i < 0) {
      vehicles.add(v);
    } else {
      _checkBranch(vehicles[i].branch);
      vehicles[i] = v;
    }
  }, sync: remote == null ? null : () => remote!.saveVehicle(v, branches));
  Future<void> deleteVehicle(Vehicle v) => _change(() {
    _requireAdmin();
    if (sales.any((s) => s.vehicleId == v.id)) {
      throw StateError(
        'This vehicle has sales records. Set its stock to zero instead.',
      );
    }
    vehicles.removeWhere((b) => b.id == v.id);
  }, sync: remote == null ? null : () => remote!.deleteVehicle(v.id));
  Future<void> transfer(Vehicle v, String destination, int count) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final newVehicleId = '$stamp';
    final newVin = '${v.vin}-T$stamp';
    final destinationBranchId = remote == null
        ? ''
        : branches.firstWhere((branch) => branch.name == destination).id;
    await _change(
      () {
        _requireAdmin();
        _checkBranch(destination);
        final i = vehicles.indexWhere((b) => b.id == v.id);
        if (i < 0 ||
            count < 1 ||
            count > vehicles[i].stock ||
            destination == v.branch) {
          throw StateError('Choose another branch and an available quantity.');
        }
        final existing = vehicles[i];
        if (count == existing.stock) {
          vehicles[i] = existing.copy(branch: destination);
        } else {
          vehicles[i] = existing.copy(stock: existing.stock - count);
          // Partial transfers use a separate stock-lot identifier to avoid duplicate VIN claims.
          vehicles.add(
            Vehicle(
              id: newVehicleId,
              name: v.name,
              brand: v.brand,
              category: v.category,
              branch: destination,
              vin: newVin,
              color: v.color,
              stock: count,
              price: v.price,
              cost: v.cost,
              year: v.year,
              image: v.image,
            ),
          );
        }
      },
      sync: remote == null
          ? null
          : () => remote!.transferVehicle(
              vehicleId: v.id,
              destinationBranchId: destinationBranchId,
              count: count,
              newVehicleId: newVehicleId,
            ),
    );
    if (remote != null) await refresh();
  }

  Future<Sale> createSale(BillDraft draft) async {
    late Sale sale;
    final now = DateTime.now();
    final matchingStaff = staff.where(
      (employee) =>
          employee.name == draft.employee &&
          employee.branch == draft.vehicle.branch,
    );
    sale = Sale(
      id: 'MS-${now.year}-${now.microsecondsSinceEpoch}',
      vehicleId: draft.vehicle.id,
      bike: draft.vehicle.name,
      branch: draft.vehicle.branch,
      customer: draft.customer,
      phone: draft.phone,
      address: draft.address,
      employee: draft.employee,
      staffId: matchingStaff.isEmpty ? '' : matchingStaff.first.id,
      vehicleImage: draft.vehicle.image,
      date: now,
      unitPrice: draft.vehicle.price,
      extras: draft.extras,
      repairCost: draft.repairCost,
      subtotal: draft.subtotal,
      discount: draft.discount,
      taxRate: draft.taxRate,
      tax: draft.tax,
      total: draft.total,
      paid: draft.paid,
      quantity: draft.quantity,
      mode: draft.paymentMode,
      status: draft.kind == 'Booking'
          ? 'Booking confirmed'
          : draft.balance == 0
          ? 'Payment completed'
          : 'Balance pending',
      kind: draft.kind,
      finance: draft.finance,
      months: draft.months,
      interest: draft.interest,
      installment: draft.installment,
    );
    await _change(
      () {
        _checkBranch(draft.vehicle.branch);
        final i = vehicles.indexWhere((v) => v.id == draft.vehicle.id);
        if (i < 0 || draft.quantity < 1 || vehicles[i].stock < draft.quantity) {
          throw StateError('Not enough stock for this invoice.');
        }
        if (draft.customer.trim().isEmpty ||
            !RegExp(r'^\d{10}$').hasMatch(draft.phone)) {
          throw StateError('Enter a customer name and 10-digit phone number.');
        }
        if (draft.paid < 0 ||
            draft.paid > draft.total ||
            draft.discount < 0 ||
            draft.discount > draft.subtotal ||
            draft.taxRate < 0 ||
            draft.taxRate > 100 ||
            draft.extras < 0 ||
            draft.repairCost < 0) {
          throw StateError('Check the invoice amounts.');
        }
        sales.add(sale);
        vehicles[i] = vehicles[i].copy(
          stock: vehicles[i].stock - draft.quantity,
        );
      },
      sync: remote == null
          ? null
          : () => remote!.createSale(sale, draft, staff),
    );
    if (remote != null) await refresh();
    return sale;
  }

  Future<void> updateStatus(Sale sale, String status) async {
    await _change(
      () {
        _checkBranch(sale.branch);
        if (![
          'Booking confirmed',
          'Balance pending',
          'Payment completed',
          'Ready for delivery',
          'Delivered',
          'Cancelled',
        ].contains(status)) {
          throw StateError('Invalid status.');
        }
        final i = sales.indexWhere((s) => s.id == sale.id);
        if (i < 0) throw StateError('Sale not found.');
        final current = sales[i];
        if (current.status == 'Cancelled') {
          throw StateError('Cancelled invoices cannot be reopened.');
        }
        if (status == 'Payment completed' && current.balance > 0) {
          throw StateError('Record the remaining payment first.');
        }
        if (status == 'Delivered' && current.balance > 0 && !current.finance) {
          throw StateError('Collect the balance before delivery.');
        }
        if (status == 'Cancelled') {
          if (current.paid > 0 || current.status == 'Delivered') {
            throw StateError(
              'Paid or delivered invoices require a refund workflow; cancellation is unavailable.',
            );
          }
          final vi = vehicles.indexWhere((v) => v.id == current.vehicleId);
          if (vi >= 0) {
            vehicles[vi] = vehicles[vi].copy(
              stock: vehicles[vi].stock + current.quantity,
            );
          }
        }
        sales[i] = current.copy(status: status);
      },
      sync: remote == null
          ? null
          : () => remote!.updateSaleStatus(sale.id, status),
    );
    if (remote != null) await refresh();
  }

  Future<void> recordPayment(Sale sale, double amount) async {
    final paymentId = 'PAY-${DateTime.now().microsecondsSinceEpoch}';
    await _change(
      () {
        _checkBranch(sale.branch);
        final i = sales.indexWhere((s) => s.id == sale.id);
        if (i < 0) throw StateError('Sale not found.');
        final current = sales[i];
        if (current.status == 'Cancelled' ||
            amount <= 0 ||
            amount > current.balance) {
          throw StateError('Enter a payment within the outstanding balance.');
        }
        final paid = rounded(current.paid + amount);
        sales[i] = current.copy(
          paid: paid,
          status: paid >= current.total && current.status != 'Delivered'
              ? 'Payment completed'
              : current.status,
        );
      },
      sync: remote == null
          ? null
          : () => remote!.recordPayment(sale, amount, paymentId),
    );
    if (remote != null) await refresh();
  }

  Future<void> saveBranch(Branch b) => _change(() {
    _requireAdmin();
    if (b.name.trim().isEmpty ||
        branches.any((v) => v.name.toLowerCase() == b.name.toLowerCase())) {
      throw StateError('Enter a unique showroom name.');
    }
    branches.add(b);
  }, sync: remote == null ? null : () => remote!.saveBranch(b));
  Future<void> saveStaff(Staff s) => _change(() {
    _requireAdmin();
    _checkBranch(s.branch);
    if (s.name.trim().isEmpty) throw StateError('Enter a staff name.');
    final i = staff.indexWhere((e) => e.id == s.id);
    if (i < 0) {
      staff.add(s);
    } else {
      staff[i] = s;
    }
  }, sync: remote == null ? null : () => remote!.saveStaff(s, branches));
  Future<void> removeStaff(Staff s) => _change(() {
    _requireAdmin();
    staff.removeWhere((e) => e.id == s.id);
  }, sync: remote == null ? null : () => remote!.removeStaff(s.id));

  Future<String> saveVehicleImage({
    required Uint8List bytes,
    required String contentType,
    required String extension,
    required String vehicleId,
    required String branchName,
  }) async {
    final limit = remote == null ? (1 << 20) : (5 << 20);
    if (bytes.length > limit) {
      throw StateError(
        remote == null
            ? 'Choose a compressed image smaller than 1 MB in demo mode.'
            : 'Choose an image smaller than 5 MB.',
      );
    }
    if (remote == null) {
      return 'data:$contentType;base64,${base64Encode(bytes)}';
    }
    final branchId = branches
        .firstWhere((branch) => branch.name == branchName)
        .id;
    return remote!.uploadVehicleImage(
      bytes: bytes,
      branchId: branchId,
      vehicleId: vehicleId,
      extension: extension,
      contentType: contentType,
    );
  }

  Future<void> deleteVehicleImage(String image) async {
    if (remote == null || image.isEmpty) return;
    await remote!.deleteVehicleImage(image);
  }

  void seed() {
    branches = const [
      Branch('b1', 'Vizag Showroom', 'Visakhapatnam, Andhra Pradesh'),
      Branch('b2', 'Hyderabad Center', 'Hyderabad, Telangana'),
      Branch('b3', 'Vijayawada Hub', 'Vijayawada, Andhra Pradesh'),
      Branch('b4', 'Guntur Outlet', 'Guntur, Andhra Pradesh'),
    ];
    vehicles = const [
      Vehicle(
        id: 'v1',
        name: 'BMW S 1000 RR',
        brand: 'BMW',
        category: 'Supersport',
        branch: 'Hyderabad Center',
        vin: 'DEMO-BMW-001',
        color: 'Light White / M',
        stock: 5,
        price: 2485000,
        cost: 2250000,
        year: 2026,
        image: '',
      ),
      Vehicle(
        id: 'v2',
        name: 'Ducati Panigale V4 S',
        brand: 'Ducati',
        category: 'Superbike',
        branch: 'Vizag Showroom',
        vin: 'DEMO-DUC-002',
        color: 'Ducati Red',
        stock: 1,
        price: 3150000,
        cost: 2850000,
        year: 2026,
        image: '',
      ),
      Vehicle(
        id: 'v3',
        name: 'Kawasaki Ninja H2',
        brand: 'Kawasaki',
        category: 'Superbike',
        branch: 'Vijayawada Hub',
        vin: 'DEMO-KAW-003',
        color: 'Mirror Black',
        stock: 0,
        price: 3540000,
        cost: 3200000,
        year: 2025,
        image: '',
      ),
      Vehicle(
        id: 'v4',
        name: 'Triumph Street Triple RS',
        brand: 'Triumph',
        category: 'Roadster',
        branch: 'Guntur Outlet',
        vin: 'DEMO-TRI-004',
        color: 'Silver Ice',
        stock: 3,
        price: 1340000,
        cost: 1185000,
        year: 2026,
        image: '',
      ),
      Vehicle(
        id: 'v5',
        name: 'RE Continental GT 650',
        brand: 'Royal Enfield',
        category: 'Cruiser',
        branch: 'Vizag Showroom',
        vin: 'DEMO-RE-005',
        color: 'British Racing Green',
        stock: 2,
        price: 415000,
        cost: 355000,
        year: 2026,
        image: 'assets/bike.png',
      ),
      Vehicle(
        id: 'v6',
        name: 'Honda Activa 6G',
        brand: 'Honda',
        category: 'Commuter',
        branch: 'Vijayawada Hub',
        vin: 'DEMO-HON-006',
        color: 'Pearl White',
        stock: 12,
        price: 95000,
        cost: 79000,
        year: 2026,
      ),
    ];
    staff = const [
      Staff(id: 'EMP-001', name: 'Ravi Kumar', branch: 'Vizag Showroom'),
      Staff(
        id: 'EMP-002',
        name: 'Suresh Babu',
        branch: 'Hyderabad Center',
        shift: 'B',
      ),
      Staff(id: 'EMP-003', name: 'P. Rajesh', branch: 'Vijayawada Hub'),
      Staff(
        id: 'EMP-004',
        name: 'M. Srikanth',
        branch: 'Guntur Outlet',
        shift: 'B',
      ),
    ];
    vehicles = List.of(vehicles);
    branches = List.of(branches);
    staff = List.of(staff);
    final now = DateTime.now();
    sales = List.generate(12, (i) {
      final v = vehicles[i % vehicles.length];
      final total = v.price;
      final partial = i % 3 == 0;
      return Sale(
        id: 'MS-${now.year}-${124 - i}',
        vehicleId: v.id,
        bike: v.name,
        branch: v.branch,
        customer: [
          'Rahul Kumar',
          'Vikram Varma',
          'Ananya Reddy',
          'Karthik Naidu',
          'Anand Kumar',
          'P. Sai',
        ][i % 6],
        phone: '90000000${(10 + i)}',
        address: 'Sample address · ${v.branch}',
        employee: staff.firstWhere((e) => e.branch == v.branch).name,
        staffId: staff.firstWhere((e) => e.branch == v.branch).id,
        vehicleImage: v.image,
        date: now.subtract(Duration(days: i * 2)),
        unitPrice: v.price,
        subtotal: total,
        discount: 0,
        tax: 0,
        total: total,
        paid: partial ? rounded(total * .6) : total,
        status: partial ? 'Balance pending' : 'Delivered',
        mode: partial ? 'Bank transfer' : 'UPI',
        finance: partial,
        installment: partial ? emi(total * .4, 9.5, 36) : 0,
      );
    });
  }
}
