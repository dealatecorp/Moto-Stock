import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'domain.dart';
import 'store.dart';
import 'ui.dart';
import 'invoice.dart';

String? requiredText(String? v) =>
    (v ?? '').trim().isEmpty ? 'This field is required' : null;
String? positiveNumber(String? v) {
  final n = double.tryParse(v ?? '');
  return n == null || !n.isFinite || n <= 0
      ? 'Enter a number greater than zero'
      : null;
}

String? nonnegativeNumber(String? v) {
  final n = double.tryParse(v ?? '');
  return n == null || !n.isFinite || n < 0
      ? 'Enter zero or a positive number'
      : null;
}

Widget field(
  TextEditingController controller,
  String label, {
  bool numeric = false,
  String? Function(String?)? validate,
  int lines = 1,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: TextFormField(
    controller: controller,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    maxLines: lines,
    validator: validate ?? requiredText,
    decoration: InputDecoration(labelText: label),
  ),
);
Widget select(
  String label,
  String value,
  List<String> choices,
  ValueChanged<String> change,
) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: choices
        .map(
          (v) => DropdownMenuItem(
            value: v,
            child: Text(v, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (v) {
      if (v != null) change(v);
    },
  ),
);

class VehicleForm extends StatefulWidget {
  final MotorStore store;
  final Vehicle? vehicle;
  const VehicleForm({super.key, required this.store, this.vehicle});
  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  final form = GlobalKey<FormState>();
  late TextEditingController name, brand, vin, color, year, stock, price, cost;
  late String branch, category, vehicleId, savedImage;
  Uint8List? photoBytes;
  String photoExtension = 'jpg', photoContentType = 'image/jpeg';
  bool pickingPhoto = false;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    vehicleId = v?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    savedImage = v?.image ?? '';
    name = TextEditingController(text: v?.name ?? '');
    brand = TextEditingController(text: v?.brand ?? '');
    vin = TextEditingController(text: v?.vin ?? '');
    color = TextEditingController(text: v?.color ?? '');
    year = TextEditingController(text: '${v?.year ?? DateTime.now().year}');
    stock = TextEditingController(text: '${v?.stock ?? 1}');
    price = TextEditingController(text: v?.price.toStringAsFixed(0) ?? '');
    cost = TextEditingController(text: v?.cost.toStringAsFixed(0) ?? '');
    branch =
        v?.branch ??
        (widget.store.allBranches
            ? widget.store.branchNames.first
            : widget.store.effectiveBranch);
    category = v?.category ?? 'Superbike';
  }

  Future<void> pickPhoto(ImageSource source) async {
    setState(() => pickingPhoto = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      // Detect the actual format rather than trusting the selected filename.
      final isJpeg = bytes.length > 2 && bytes[0] == 0xff && bytes[1] == 0xd8;
      final isPng =
          bytes.length > 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4e &&
          bytes[3] == 0x47;
      final isWebp =
          bytes.length > 12 &&
          String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
      if (!isJpeg && !isPng && !isWebp) {
        throw StateError('Choose a JPG, PNG or WebP photo.');
      }
      final limit = widget.store.usesSupabase ? 5 << 20 : 1 << 20;
      if (bytes.length > limit) {
        throw StateError(
          widget.store.usesSupabase
              ? 'Choose a photo smaller than 5 MB.'
              : 'Choose a photo smaller than 1 MB in demo mode.',
        );
      }
      if (!mounted) return;
      setState(() {
        photoBytes = bytes;
        photoExtension = isJpeg
            ? 'jpg'
            : isPng
            ? 'png'
            : 'webp';
        photoContentType = isJpeg
            ? 'image/jpeg'
            : isPng
            ? 'image/png'
            : 'image/webp';
      });
    } catch (e) {
      if (mounted) {
        notice(
          context,
          'Could not add photo: ${e.toString().replaceFirst('Bad state: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => pickingPhoto = false);
    }
  }

  @override
  void dispose() {
    for (final c in [name, brand, vin, color, year, stock, price, cost]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    String? uploadedImage;
    try {
      if (photoBytes != null) {
        uploadedImage = await widget.store.saveVehicleImage(
          bytes: photoBytes!,
          contentType: photoContentType,
          extension: photoExtension,
          vehicleId: vehicleId,
          branchName: branch,
        );
      }
      await widget.store.saveVehicle(
        Vehicle(
          id: vehicleId,
          name: name.text.trim(),
          brand: brand.text.trim(),
          category: category,
          branch: branch,
          vin: vin.text.trim(),
          color: color.text.trim(),
          stock: int.parse(stock.text),
          price: double.parse(price.text),
          cost: double.parse(cost.text),
          year: int.parse(year.text),
          image: uploadedImage ?? savedImage,
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // A local validation rejection cannot have committed the vehicle remotely.
      // Keep uploads on uncertain network errors so a committed record never
      // points at a deleted image. Retain previous photos for invoice snapshots.
      if (uploadedImage != null && e is StateError) {
        try {
          await widget.store.deleteVehicleImage(uploadedImage);
        } catch (_) {}
      }
      if (mounted) {
        notice(context, e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.vehicle == null ? 'New vehicle intake' : 'Edit vehicle',
      ),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.vehicle == null
                ? 'Register a motorcycle'
                : 'Update stock & details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            widget.store.usesSupabase
                ? 'Records are saved to Supabase.'
                : 'Demo records are saved locally.',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 22),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehicle photo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (photoBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      photoBytes!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (savedImage.isNotEmpty && widget.vehicle != null)
                  BikeImage(
                    widget.vehicle!,
                    width: double.infinity,
                    height: 180,
                  )
                else
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 44,
                      color: muted,
                    ),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('vehicleCamera'),
                      onPressed: busy || pickingPhoto
                          ? null
                          : () => pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Camera'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('vehicleGallery'),
                      onPressed: busy || pickingPhoto
                          ? null
                          : () => pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(pickingPhoto ? 'Opening…' : 'Gallery'),
                    ),
                    if (photoBytes != null || savedImage.isNotEmpty)
                      TextButton(
                        onPressed: busy || pickingPhoto
                            ? null
                            : () => setState(() {
                                photoBytes = null;
                                savedImage = '';
                              }),
                        child: const Text('Remove'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          field(name, 'Make & model'),
          field(brand, 'Brand'),
          field(vin, 'VIN / Stock identifier'),
          field(color, 'Color'),
          select('Vehicle class', category, [
            'Supersport',
            'Superbike',
            'Cruiser',
            'Roadster',
            'Commuter',
          ], (v) => setState(() => category = v)),
          select(
            'Showroom',
            branch,
            widget.store.isAdmin
                ? widget.store.branchNames
                : [widget.store.userBranch],
            (v) => setState(() => branch = v),
          ),
          field(
            year,
            'Model year',
            numeric: true,
            validate: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n < 1950 || n > DateTime.now().year + 2
                  ? 'Enter a valid model year'
                  : null;
            },
          ),
          field(
            stock,
            'Available quantity',
            numeric: true,
            validate: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n < 0
                  ? 'Enter a whole number, zero or greater'
                  : null;
            },
          ),
          field(
            cost,
            'Purchase cost per unit (₹)',
            numeric: true,
            validate: nonnegativeNumber,
          ),
          field(
            price,
            'Selling price per unit (₹)',
            numeric: true,
            validate: positiveNumber,
          ),
          FilledButton.icon(
            key: const Key('saveVehicle'),
            onPressed: busy || pickingPhoto ? null : save,
            icon: const Icon(Icons.check),
            label: Text(busy ? 'Saving…' : 'Save vehicle'),
          ),
        ],
      ),
    ),
  );
}

Future<void> transferDialog(
  BuildContext context,
  MotorStore store,
  Vehicle v,
) async {
  final branches = store.branchNames.where((b) => b != v.branch).toList();
  if (branches.isEmpty) {
    notice(context, 'Add another showroom first.');
    return;
  }
  final count = TextEditingController(text: '1');
  String destination = branches.first;
  bool busy = false;
  await showDialog<void>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (dialog, setState) => AlertDialog(
        title: Text(
          store.usesSupabase ? 'Transfer stock' : 'Transfer demo stock',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${v.name}\n${v.stock} units at ${v.branch}'),
            const SizedBox(height: 16),
            select(
              'Destination',
              destination,
              branches,
              (b) => setState(() => destination = b),
            ),
            TextField(
              controller: count,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 10),
            Text(
              store.usesSupabase
                  ? 'Partial transfers create a separate stock lot.'
                  : 'Partial transfers create a separate demo stock lot.',
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      await store.transfer(
                        v,
                        destination,
                        int.tryParse(count.text) ?? 0,
                      );
                      if (dialog.mounted) Navigator.pop(dialog);
                    } catch (e) {
                      if (dialog.mounted) {
                        notice(dialog, e.toString());
                        setState(() => busy = false);
                      }
                    }
                  },
            child: const Text('Transfer'),
          ),
        ],
      ),
    ),
  );
  // Controllers remain alive through the dialog route's closing animation.
}

Future<void> paymentDialog(
  BuildContext context,
  MotorStore store,
  Sale sale,
) async {
  final amount = TextEditingController(text: sale.balance.toStringAsFixed(0));
  bool busy = false;
  await showDialog<void>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (dialog, setState) => AlertDialog(
        title: const Text('Record payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Outstanding balance: ${money(sale.balance)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount received (₹)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      await store.recordPayment(
                        sale,
                        double.tryParse(amount.text) ?? 0,
                      );
                      if (dialog.mounted) Navigator.pop(dialog);
                    } catch (e) {
                      if (dialog.mounted) {
                        notice(dialog, e.toString());
                        setState(() => busy = false);
                      }
                    }
                  },
            child: const Text('Record'),
          ),
        ],
      ),
    ),
  );
}

Future<void> branchDialog(BuildContext context, MotorStore store) async {
  final name = TextEditingController(), location = TextEditingController();
  final key = GlobalKey<FormState>();
  bool busy = false;
  await showDialog<void>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (dialog, setState) => AlertDialog(
        title: const Text('Add showroom'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(name, 'Showroom name'),
              field(location, 'City / Location'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!key.currentState!.validate()) return;
                    setState(() => busy = true);
                    try {
                      await store.saveBranch(
                        Branch(
                          DateTime.now().microsecondsSinceEpoch.toString(),
                          name.text.trim(),
                          location.text.trim(),
                        ),
                      );
                      if (dialog.mounted) Navigator.pop(dialog);
                    } catch (e) {
                      if (dialog.mounted) {
                        notice(dialog, e.toString());
                        setState(() => busy = false);
                      }
                    }
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> staffDialog(
  BuildContext context,
  MotorStore store, {
  Staff? employee,
  String? initialBranch,
}) async {
  final name = TextEditingController(text: employee?.name ?? '');
  final key = GlobalKey<FormState>();
  String branch = employee?.branch ?? initialBranch ?? store.branchNames.first,
      shift = employee?.shift ?? 'A',
      role = employee?.role ?? 'Sales Executive';
  bool busy = false;
  await showDialog<void>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (dialog, setState) => AlertDialog(
        title: Text(employee == null ? 'Add employee' : 'Edit employee'),
        content: SingleChildScrollView(
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field(name, 'Full name'),
                select(
                  'Showroom',
                  branch,
                  store.branchNames,
                  (v) => setState(() => branch = v),
                ),
                select('Role', role, [
                  'Sales Executive',
                  'Manager',
                  'Billing Agent',
                ], (v) => setState(() => role = v)),
                select('Shift', shift, [
                  'A',
                  'B',
                ], (v) => setState(() => shift = v)),
                Text(
                  store.usesSupabase
                      ? 'Adding a team record does not create a Supabase Auth login.'
                      : 'Team records are for this demo; adding staff does not create a server login.',
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!key.currentState!.validate()) return;
                    setState(() => busy = true);
                    try {
                      await store.saveStaff(
                        Staff(
                          id:
                              employee?.id ??
                              'EMP-${DateTime.now().millisecondsSinceEpoch}',
                          name: name.text.trim(),
                          branch: branch,
                          role: role,
                          shift: shift,
                          frozen: employee?.frozen ?? false,
                        ),
                      );
                      if (dialog.mounted) Navigator.pop(dialog);
                    } catch (e) {
                      if (dialog.mounted) {
                        notice(dialog, e.toString());
                        setState(() => busy = false);
                      }
                    }
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

class BillingPage extends StatefulWidget {
  final MotorStore store;
  final Vehicle? initialVehicle;
  const BillingPage({super.key, required this.store, this.initialVehicle});
  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final form = GlobalKey<FormState>();
  final customer = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController(),
      quantity = TextEditingController(text: '1'),
      extras = TextEditingController(text: '0'),
      repair = TextEditingController(text: '0'),
      discount = TextEditingController(text: '0'),
      tax = TextEditingController(text: '0'),
      paid = TextEditingController(text: '0'),
      interest = TextEditingController(text: '9.5');
  String? vehicleId;
  String kind = 'Vehicle sale', mode = 'UPI';
  bool finance = false, busy = false;
  int months = 36;
  @override
  void initState() {
    super.initState();
    vehicleId = widget.initialVehicle?.id;
    for (final c in [quantity, extras, repair, discount, tax, paid, interest]) {
      c.addListener(recompute);
    }
  }

  void recompute() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      customer,
      phone,
      address,
      quantity,
      extras,
      repair,
      discount,
      tax,
      paid,
      interest,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<Vehicle> get available =>
      widget.store.visibleVehicles.where((v) => v.stock > 0).toList();
  Vehicle? get selected {
    for (final v in available) {
      if (v.id == vehicleId) return v;
    }
    return null;
  }

  BillDraft? get draft {
    final v = selected;
    if (v == null) return null;
    return BillDraft(
      vehicle: v,
      customer: customer.text.trim(),
      phone: phone.text.trim(),
      address: address.text.trim(),
      employee: widget.store.userName,
      quantity: int.tryParse(quantity.text) ?? 1,
      extras: double.tryParse(extras.text) ?? 0,
      repairCost: double.tryParse(repair.text) ?? 0,
      discount: double.tryParse(discount.text) ?? 0,
      taxRate: double.tryParse(tax.text) ?? 0,
      paid: double.tryParse(paid.text) ?? 0,
      kind: kind,
      paymentMode: mode,
      finance: finance,
      interest: double.tryParse(interest.text) ?? 0,
      months: months,
    );
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final bill = draft;
    if (bill == null) {
      notice(context, 'Select an available vehicle.');
      return;
    }
    if (!await confirm(
      context,
      widget.store.usesSupabase
          ? 'Generate invoice?'
          : 'Generate demo invoice?',
      'Reserve ${bill.quantity} unit(s) and record ${money(bill.total)} for ${bill.customer}?',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => busy = true);
    try {
      final sale = await widget.store.createSale(bill);
      if (mounted) {
        customer.clear();
        phone.clear();
        address.clear();
        extras.text = '0';
        repair.text = '0';
        discount.text = '0';
        tax.text = '0';
        paid.text = '0';
        setState(() => vehicleId = null);
        await viewInvoice(context, sale);
      }
    } catch (e) {
      if (mounted) {
        notice(context, e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = draft;
    return Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Billing desk',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Text(
            'Create an invoice. Keep the ledger in sync.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Pill(
            widget.store.usesSupabase
                ? 'CLOUD INVOICE · VERIFY TAX DETAILS'
                : 'DEMO INVOICE · LOCAL RECORD',
          ),
          const SectionTitle('01  Vehicle & sale information'),
          Panel(
            child: Column(
              children: [
                select('Sale type', kind, [
                  'Vehicle sale',
                  'Booking',
                ], (v) => setState(() => kind = v)),
                DropdownButtonFormField<String>(
                  key: ValueKey('${vehicleId}_${available.length}'),
                  initialValue: selected?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select motorcycle',
                  ),
                  items: available
                      .map(
                        (v) => DropdownMenuItem(
                          value: v.id,
                          child: Text(
                            '${v.name} · ${v.branch}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                  validator: (v) => v == null ? 'Choose a vehicle' : null,
                  onChanged: (v) => setState(() => vehicleId = v),
                ),
                if (available.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'No available stock. Add a vehicle in Sale In.',
                      style: TextStyle(color: amber),
                    ),
                  ),
                if (selected != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      BikeImage(selected!, width: 62, height: 55),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${selected!.stock} available · ${money(selected!.price)}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                field(
                  quantity,
                  'Quantity',
                  numeric: true,
                  validate: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null || n < 1 || n > (selected?.stock ?? 0)
                        ? 'Enter an available whole quantity'
                        : null;
                  },
                ),
              ],
            ),
          ),
          const SectionTitle('02  Customer details'),
          Panel(
            child: Column(
              children: [
                field(customer, 'Customer full name'),
                field(
                  phone,
                  'Phone number',
                  numeric: true,
                  validate: (v) => RegExp(r'^\d{10}$').hasMatch(v ?? '')
                      ? null
                      : 'Enter a 10-digit phone number',
                ),
                field(address, 'Registration address', lines: 2),
              ],
            ),
          ),
          const SectionTitle('03  Payment & financial ledger'),
          Panel(
            child: Column(
              children: [
                select('Payment method', mode, [
                  'UPI',
                  'Cash',
                  'Bank transfer',
                  'Card',
                  'Cheque',
                ], (v) => setState(() => mode = v)),
                field(
                  extras,
                  'Registration / Insurance / Extras (₹)',
                  numeric: true,
                  validate: nonnegativeNumber,
                ),
                field(
                  repair,
                  'Repair cost (₹)',
                  numeric: true,
                  validate: nonnegativeNumber,
                ),
                field(
                  discount,
                  'Discount (₹)',
                  numeric: true,
                  validate: (v) {
                    final err = nonnegativeNumber(v);
                    if (err != null) return err;
                    return double.parse(v!) > (bill?.subtotal ?? 0)
                        ? 'Discount exceeds subtotal'
                        : null;
                  },
                ),
                field(
                  tax,
                  'GST rate (%)',
                  numeric: true,
                  validate: (v) {
                    final err = nonnegativeNumber(v);
                    if (err != null) return err;
                    return double.parse(v!) > 100
                        ? 'Enter a rate from 0 to 100'
                        : null;
                  },
                ),
                field(
                  paid,
                  'Amount received (₹)',
                  numeric: true,
                  validate: (v) {
                    final err = nonnegativeNumber(v);
                    if (err != null) return err;
                    return double.parse(v!) > (bill?.total ?? 0)
                        ? 'Payment exceeds invoice total'
                        : null;
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('EMI finance estimate'),
                  subtitle: const Text('Plan installments on the balance'),
                  value: finance,
                  onChanged: (v) => setState(() => finance = v),
                ),
                if (finance) ...[
                  field(
                    interest,
                    'Annual interest rate (%)',
                    numeric: true,
                    validate: nonnegativeNumber,
                  ),
                  select(
                    'Tenure',
                    '$months months',
                    [12, 24, 36, 48, 60, 72].map((v) => '$v months').toList(),
                    (v) =>
                        setState(() => months = int.parse(v.split(' ').first)),
                  ),
                ],
                const Divider(),
                valueRow(
                  'Vehicle amount',
                  money((bill?.vehicle.price ?? 0) * (bill?.quantity ?? 0)),
                ),
                valueRow('Registration / extras', money(bill?.extras ?? 0)),
                valueRow('Repair cost', money(bill?.repairCost ?? 0)),
                valueRow('Subtotal', money(bill?.subtotal ?? 0)),
                valueRow('Discount', money(bill?.discount ?? 0)),
                valueRow(
                  'GST (${(bill?.taxRate ?? 0).toStringAsFixed(2)}%)',
                  money(bill?.tax ?? 0),
                ),
                valueRow(
                  'Total invoice',
                  money(bill?.total ?? 0),
                  bold: true,
                  color: blue,
                ),
                valueRow(
                  'Balance payable',
                  money(bill?.balance ?? 0),
                  bold: true,
                  color: amber,
                ),
                if (finance)
                  valueRow(
                    'Estimated monthly EMI',
                    money(bill?.installment ?? 0),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Saving reserves stock, including bookings. GST is calculated on vehicle amount, extras, and repair cost after discount. Verify the applicable rate before invoicing.',
            style: TextStyle(fontSize: 11, color: muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('generateInvoice'),
            onPressed: busy ? null : save,
            icon: const Icon(Icons.receipt_long),
            label: Text(busy ? 'Generating…' : 'Generate invoice'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
