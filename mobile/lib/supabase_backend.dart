import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'domain.dart';

class MotorProfile {
  const MotorProfile({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.branchId,
    required this.branchName,
  });

  final String userId, email, name, role, branchId, branchName;
  bool get isAdmin => role == 'admin';
}

class RemoteSnapshot {
  const RemoteSnapshot({
    required this.branches,
    required this.vehicles,
    required this.sales,
    required this.staff,
  });

  final List<Branch> branches;
  final List<Vehicle> vehicles;
  final List<Sale> sales;
  final List<Staff> staff;
}

class SupabaseMotorRepository {
  SupabaseMotorRepository(this.client);

  final SupabaseClient client;

  Future<MotorProfile?> restoreProfile() async {
    if (client.auth.currentSession == null) return null;
    try {
      return await _loadProfile();
    } catch (_) {
      await client.auth.signOut();
      rethrow;
    }
  }

  Future<MotorProfile> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    try {
      return await _loadProfile();
    } catch (_) {
      await client.auth.signOut();
      rethrow;
    }
  }

  Future<void> signOut() => client.auth.signOut();

  Future<MotorProfile> _loadProfile() async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Your Supabase session has expired.');
    final value = await client
        .from('profiles')
        .select('user_id, display_name, role, branch_id, active')
        .eq('user_id', user.id)
        .maybeSingle();
    if (value == null) {
      throw StateError(
        'This account is not linked to a MotorStock profile yet.',
      );
    }
    final row = Map<String, dynamic>.from(value);
    if (row['active'] != true) {
      throw StateError('This MotorStock account is inactive.');
    }
    final role = row['role'] as String? ?? 'staff';
    final branchId = row['branch_id'] as String? ?? '';
    var branchName = '';
    if (branchId.isNotEmpty) {
      final branch = await client
          .from('branches')
          .select('name')
          .eq('id', branchId)
          .maybeSingle();
      branchName = branch == null ? '' : branch['name'] as String? ?? '';
    }
    if (role != 'admin' && (branchId.isEmpty || branchName.isEmpty)) {
      throw StateError('This staff account has no showroom assignment.');
    }
    return MotorProfile(
      userId: user.id,
      email: user.email ?? '',
      name: row['display_name'] as String? ?? user.email ?? 'MotorStock user',
      role: role,
      branchId: branchId,
      branchName: branchName,
    );
  }

  Future<RemoteSnapshot> loadSnapshot() async {
    final branchValue = await client
        .from('branches')
        .select('id, name, location')
        .order('name');
    final branches = _rows(branchValue).map(Branch.fromJson).toList();
    final branchNames = {for (final branch in branches) branch.id: branch.name};

    final values = await Future.wait<dynamic>([
      client
          .from('vehicles')
          .select(
            'id, branch_id, name, brand, category, vin, color, stock, '
            'price, cost, model_year, image_url',
          )
          .order('name'),
      client
          .from('sales')
          .select(
            'id, vehicle_id, branch_id, vehicle_name, vehicle_image_url, '
            'customer_name, phone, address, staff_id, employee_name, sold_at, '
            'unit_price, quantity, extras, repair_cost, subtotal, discount, '
            'tax_rate, tax, total, paid, payment_method, status, kind, finance, '
            'months, emis_paid, installment, interest',
          )
          .order('sold_at', ascending: false),
      client
          .from('staff')
          .select('id, branch_id, name, role, shift, frozen')
          .order('name'),
    ]);

    final vehicles = _rows(values[0]).map((row) {
      final branch = _branchName(branchNames, row['branch_id']);
      return Vehicle.fromJson({
        'id': row['id'],
        'name': row['name'],
        'brand': row['brand'],
        'category': row['category'],
        'branch': branch,
        'vin': row['vin'],
        'color': row['color'],
        'stock': row['stock'],
        'price': row['price'],
        'cost': row['cost'],
        'year': row['model_year'],
        'image': row['image_url'] ?? '',
      });
    }).toList();
    final sales = _rows(values[1]).map((row) {
      final branch = _branchName(branchNames, row['branch_id']);
      return Sale.fromJson({
        'id': row['id'],
        'vehicleId': row['vehicle_id'],
        'bike': row['vehicle_name'],
        'branch': branch,
        'customer': row['customer_name'],
        'phone': row['phone'],
        'address': row['address'],
        'employee': row['employee_name'],
        'staffId': row['staff_id'] ?? '',
        'vehicleImage': row['vehicle_image_url'] ?? '',
        'date': row['sold_at'],
        'unitPrice': row['unit_price'],
        'extras': row['extras'],
        'repairCost': row['repair_cost'],
        'subtotal': row['subtotal'],
        'discount': row['discount'],
        'taxRate': row['tax_rate'],
        'tax': row['tax'],
        'total': row['total'],
        'paid': row['paid'],
        'quantity': row['quantity'],
        'mode': row['payment_method'],
        'status': row['status'],
        'kind': row['kind'],
        'finance': row['finance'],
        'months': row['months'],
        'emisPaid': row['emis_paid'],
        'installment': row['installment'],
        'interest': row['interest'],
      });
    }).toList();
    final staff = _rows(values[2]).map((row) {
      final branch = _branchName(branchNames, row['branch_id']);
      return Staff.fromJson({
        'id': row['id'],
        'name': row['name'],
        'branch': branch,
        'role': row['role'],
        'shift': row['shift'],
        'frozen': row['frozen'],
      });
    }).toList();
    return RemoteSnapshot(
      branches: branches,
      vehicles: vehicles,
      sales: sales,
      staff: staff,
    );
  }

  Future<void> saveVehicle(Vehicle vehicle, List<Branch> branches) =>
      client.from('vehicles').upsert(_vehicleRow(vehicle, branches));

  Future<void> deleteVehicle(String id) =>
      client.from('vehicles').delete().eq('id', id);

  Future<void> transferVehicle({
    required String vehicleId,
    required String destinationBranchId,
    required int count,
    required String newVehicleId,
  }) => client.rpc(
    'transfer_vehicle',
    params: {
      'p_vehicle_id': vehicleId,
      'p_destination_branch_id': destinationBranchId,
      'p_quantity': count,
      'p_destination_vehicle_id': newVehicleId,
    },
  );

  Future<void> createSale(Sale sale, BillDraft draft, List<Staff> staff) =>
      client.rpc(
        'create_sale',
        params: {
          'p_vehicle_id': sale.vehicleId,
          'p_customer_name': sale.customer,
          'p_phone': sale.phone,
          'p_address': sale.address,
          'p_staff_id': sale.staffId.isEmpty
              ? _staffId(staff, sale.employee, sale.branch)
              : sale.staffId,
          'p_quantity': sale.quantity,
          'p_extras': draft.extras,
          'p_discount': sale.discount,
          'p_tax_rate': draft.taxRate,
          'p_initial_payment': sale.paid,
          'p_payment_method': sale.mode,
          'p_kind': sale.kind,
          'p_finance': sale.finance,
          'p_interest': sale.interest,
          'p_months': sale.months,
          'p_sale_id': sale.id,
          'p_repair_cost': draft.repairCost,
        },
      );

  Future<void> updateSaleStatus(String saleId, String status) => client.rpc(
    'update_sale_status',
    params: {'p_sale_id': saleId, 'p_status': status},
  );

  Future<void> recordPayment(Sale sale, double amount, String paymentId) =>
      client.rpc(
        'record_payment',
        params: {
          'p_sale_id': sale.id,
          'p_amount': amount,
          'p_method': sale.mode,
          'p_note': 'Recorded from MotorStock Mobile',
          'p_payment_id': paymentId,
        },
      );

  Future<void> saveBranch(Branch branch) =>
      client.from('branches').insert(branch.toJson());

  Future<void> saveStaff(Staff employee, List<Branch> branches) =>
      client.from('staff').upsert(_staffRow(employee, branches));

  Future<void> removeStaff(String id) =>
      client.from('staff').delete().eq('id', id);

  Future<String> uploadVehicleImage({
    required Uint8List bytes,
    required String branchId,
    required String vehicleId,
    required String extension,
    required String contentType,
  }) async {
    final safeExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? extension
        : 'jpg';
    final version = DateTime.now().microsecondsSinceEpoch;
    final path =
        '${_safePathPart(branchId)}/${_safePathPart(vehicleId)}/$version.$safeExtension';
    await client.storage
        .from('vehicle-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            cacheControl: '31536000',
          ),
        );
    return client.storage.from('vehicle-images').getPublicUrl(path);
  }

  Future<void> deleteVehicleImage(String publicUrl) async {
    final uri = Uri.tryParse(publicUrl);
    if (uri == null || !uri.host.endsWith('.supabase.co')) return;
    const marker = '/storage/v1/object/public/vehicle-images/';
    final start = uri.path.indexOf(marker);
    if (start < 0) return;
    final path = Uri.decodeComponent(uri.path.substring(start + marker.length));
    if (path.isEmpty) return;
    await client.storage.from('vehicle-images').remove([path]);
  }

  Map<String, dynamic> _vehicleRow(Vehicle vehicle, List<Branch> branches) => {
    'id': vehicle.id,
    'branch_id': _branchId(branches, vehicle.branch),
    'name': vehicle.name,
    'brand': vehicle.brand,
    'category': vehicle.category,
    'vin': vehicle.vin,
    'color': vehicle.color,
    'stock': vehicle.stock,
    'price': vehicle.price,
    'cost': vehicle.cost,
    'model_year': vehicle.year,
    'image_url': vehicle.image,
  };

  Map<String, dynamic> _staffRow(Staff employee, List<Branch> branches) => {
    'id': employee.id,
    'branch_id': _branchId(branches, employee.branch),
    'name': employee.name,
    'role': employee.role,
    'shift': employee.shift,
    'frozen': employee.frozen,
  };

  static List<Map<String, dynamic>> _rows(dynamic value) => (value as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();

  static String _branchName(Map<String, String> names, dynamic id) {
    final name = names[id as String?];
    if (name == null) {
      throw StateError('A record references an unknown branch.');
    }
    return name;
  }

  static String _branchId(List<Branch> branches, String name) {
    for (final branch in branches) {
      if (branch.name == name) return branch.id;
    }
    throw StateError('The selected showroom is unavailable.');
  }

  static String? _staffId(
    List<Staff> staff,
    String employeeName,
    String branchName,
  ) {
    for (final employee in staff) {
      if (!employee.frozen &&
          employee.name == employeeName &&
          employee.branch == branchName) {
        return employee.id;
      }
    }
    return null;
  }

  static String _safePathPart(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}
