import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'branding.dart';
import 'domain.dart';
import 'store.dart';
import 'ui.dart';
import 'forms.dart';
import 'invoice.dart';

class LoginScreen extends StatefulWidget {
  final MotorStore store;
  const LoginScreen({super.key, required this.store});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool admin = true, hidden = true, busy = false, showLogin = false;
  late final TextEditingController user, password;

  @override
  void initState() {
    super.initState();
    user = TextEditingController(
      text: widget.store.usesSupabase ? 'demo' : 'admin@motorstock.demo',
    );
    password = TextEditingController(text: 'demo123');
  }

  @override
  void dispose() {
    user.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!showLogin) {
      return MotorStockWelcome(
        onSignIn: () => setState(() => showLogin = true),
      );
    }
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) setState(() => showLogin = false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff5f2ff),
        appBar: AppBar(
          backgroundColor: const Color(0xfff5f2ff),
          leading: IconButton(
            key: const Key('welcomeBack'),
            tooltip: 'Back to welcome',
            onPressed: busy ? null : () => setState(() => showLogin = false),
            icon: const Icon(Icons.arrow_back_rounded, color: brandNavy),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Brand(),
                    const SizedBox(height: 32),
                    const Pill('YOUR SHOWROOM, CONNECTED'),
                    const SizedBox(height: 14),
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: brandNavy),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your showroom. Your inventory.\nOne connected workspace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, height: 1.5),
                    ),
                    const SizedBox(height: 26),
                    if (!widget.store.usesSupabase) ...[
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: true,
                            label: Text('Admin'),
                            icon: Icon(Icons.admin_panel_settings_outlined),
                          ),
                          ButtonSegment(
                            value: false,
                            label: Text('Showroom staff'),
                            icon: Icon(Icons.storefront_outlined),
                          ),
                        ],
                        selected: {admin},
                        onSelectionChanged: (v) => setState(() {
                          admin = v.first;
                          user.text = admin
                              ? 'admin@motorstock.demo'
                              : 'staff@motorstock.demo';
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Username / Login ID',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: user,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: password,
                            obscureText: hidden,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: 'Show password',
                                onPressed: () =>
                                    setState(() => hidden = !hidden),
                                icon: Icon(
                                  hidden
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            key: const Key('login'),
                            style: FilledButton.styleFrom(
                              backgroundColor: brandNavy,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: busy
                                ? null
                                : () async {
                                    if (user.text.trim().isEmpty ||
                                        password.text.isEmpty) {
                                      notice(
                                        context,
                                        'Enter your username and password.',
                                      );
                                      return;
                                    }
                                    setState(() => busy = true);
                                    try {
                                      await widget.store.loginWithPassword(
                                        user.text,
                                        password.text,
                                        demoAdmin: admin,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        notice(
                                          context,
                                          e.toString().replaceFirst(
                                            'Bad state: ',
                                            '',
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) setState(() => busy = false);
                                    }
                                  },
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(
                              busy ? 'Signing in…' : 'Sign in to dashboard',
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Demo login: demo  /  demo123',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Panel(
                      child: Row(
                        children: [
                          Icon(
                            widget.store.usesSupabase
                                ? Icons.cloud_done_outlined
                                : Icons.offline_bolt_outlined,
                            color: const Color(0xff087fa3),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.store.usesSupabase
                                  ? 'Your showroom, always in sync.\nSign in to access your team and inventory.'
                                  : 'Offline demo · Sample data\nChanges are saved on this device.',
                              style: const TextStyle(fontSize: 12, height: 1.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'SMART DEALERSHIP MANAGEMENT',
                      style: TextStyle(
                        fontSize: 10,
                        color: muted,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final MotorStore store;
  const HomeScreen({super.key, required this.store});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int page = 0;
  final titles = ['Dashboard', 'Sale In', 'Sale Out', 'Billing', 'Stores'];
  void go(int i) => setState(() => page = i);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Brand(compact: true),
      actions: [
        IconButton(
          tooltip: 'Inventory alerts',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AlertsPage(store: widget.store)),
          ),
          icon: Badge(
            label: Text(
              '${widget.store.visibleVehicles.where((v) => v.stock <= 2).length}',
            ),
            child: const Icon(Icons.notifications_none),
          ),
        ),
        IconButton(
          key: const Key('workspaceMenu'),
          tooltip: 'Account and settings',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Account and settings')),
                body: MorePage(store: widget.store),
              ),
            ),
          ),
          icon: CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xffdbeafe),
            child: Text(
              widget.store.userInitials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: blue,
              ),
            ),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Container(
          color: const Color(0xffedf2ff),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 6, color: blue),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  widget.store.usesSupabase
                      ? 'LIVE · Supabase cloud'
                      : 'DEMO · Saved on this device',
                  style: const TextStyle(
                    fontSize: 10,
                    color: blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                widget.store.isAdmin ? 'ADMIN' : 'STAFF',
                style: const TextStyle(
                  fontSize: 10,
                  color: blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: switch (page) {
                0 => Dashboard(store: widget.store, go: go),
                1 => InventoryPage(store: widget.store),
                2 => SalesPage(store: widget.store),
                3 => BillingPage(store: widget.store),
                _ => StoresPage(store: widget.store, embedded: true),
              },
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: page,
      onDestinationSelected: go,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.input_rounded),
          label: 'Sale In',
        ),
        NavigationDestination(
          icon: Icon(Icons.output_rounded),
          label: 'Sale Out',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Billing',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Stores',
        ),
      ],
    ),
  );
}

class BranchPicker extends StatelessWidget {
  final MotorStore store;
  const BranchPicker(this.store, {super.key});
  @override
  Widget build(BuildContext context) => store.isAdmin
      ? DropdownButtonFormField<String>(
          initialValue: store.selectedBranch,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.storefront_outlined),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: ['All branches', ...store.branchNames]
              .map(
                (b) => DropdownMenuItem(
                  value: b,
                  child: Text(b, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (b) => store.chooseBranch(b!),
        )
      : Pill(store.userBranch);
}

class Dashboard extends StatefulWidget {
  final MotorStore store;
  final ValueChanged<int> go;
  const Dashboard({super.key, required this.store, required this.go});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String period = 'Month';
  List<Sale> get rows {
    final now = DateTime.now();
    return widget.store.visibleSales
        .where(
          (s) =>
              s.status != 'Cancelled' &&
              switch (period) {
                'Today' =>
                  s.date.year == now.year &&
                      s.date.month == now.month &&
                      s.date.day == now.day,
                'Week' => s.date.isAfter(
                  DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).subtract(const Duration(days: 6)),
                ),
                _ => s.date.year == now.year && s.date.month == now.month,
              },
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store,
        revenue = rows.fold(0.0, (a, b) => a + b.total),
        stock = s.visibleVehicles.fold(0, (a, b) => a + b.stock);
    final alerts = s.visibleVehicles.where((v) => v.stock <= 2).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 6),
        Text(
          'Good ${DateTime.now().hour < 12 ? 'morning' : 'afternoon'},',
          style: const TextStyle(color: muted),
        ),
        Text(s.userName, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'A clear view of your showroom operations.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        BranchPicker(s),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => widget.go(3),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('Create invoice'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmiPage()),
              ),
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('EMI calculator'),
            ),
          ],
        ),
        SectionTitle(
          'Network snapshot',
          action: DropdownButton<String>(
            value: period,
            underline: const SizedBox(),
            items: ['Today', 'Week', 'Month']
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(v, style: const TextStyle(fontSize: 12)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => period = v!),
          ),
        ),
        MetricGrid(
          children: [
            Metric(
              'Invoiced revenue',
              shortMoney(revenue),
              period == 'Month' ? 'This calendar month' : period,
              Icons.payments_outlined,
            ),
            Metric(
              'Available bikes',
              '$stock units',
              'Across selected branches',
              Icons.two_wheeler,
            ),
            Metric(
              'Sales recorded',
              '${rows.fold(0, (a, b) => a + b.quantity)} units',
              '${rows.length} invoices',
              Icons.shopping_bag_outlined,
            ),
            Metric(
              'Pending balance',
              shortMoney(rows.fold(0.0, (a, b) => a + b.balance)),
              'From these invoices',
              Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        SectionTitle(
          'Inventory watch',
          subtitle: 'Replenish stock before the next sale',
          action: Pill('${alerts.length} alerts', color: amber),
        ),
        if (alerts.isEmpty)
          const Panel(child: Text('Stock levels look healthy.')),
        ...alerts
            .take(3)
            .map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          BikeImage(v, width: 56, height: 52),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  v.branch,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Pill('${v.stock} left', color: statusColor(v.status)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VehicleForm(store: s, vehicle: v),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Update stock'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        const SectionTitle(
          'Revenue by branch',
          subtitle: 'Distribution for the selected period',
        ),
        Panel(
          child: Column(
            children: s.branches
                .where((b) => s.allBranches || b.name == s.effectiveBranch)
                .map((b) {
                  final value = rows
                      .where((sale) => sale.branch == b.name)
                      .fold(0.0, (a, b) => a + b.total);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        valueRow(b.name, shortMoney(value)),
                        LinearProgressIndicator(
                          value: revenue == 0 ? 0 : value / revenue,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(4),
                          backgroundColor: line,
                        ),
                      ],
                    ),
                  );
                })
                .toList(),
          ),
        ),
        const SectionTitle(
          'Revenue velocity',
          subtitle: 'Invoiced totals over the last four weeks',
        ),
        Panel(
          child: SizedBox(height: 160, child: RevenueChart(s.visibleSales)),
        ),
        SectionTitle(
          'Recent dealership sales',
          action: TextButton(
            onPressed: () => widget.go(2),
            child: const Text('Full ledger'),
          ),
        ),
        ...s.visibleSales
            .take(3)
            .map(
              (sale) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SaleTile(
                  sale: sale,
                  onTap: () => openSale(context, s, sale),
                ),
              ),
            ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class RevenueChart extends StatelessWidget {
  final List<Sale> sales;
  const RevenueChart(this.sales, {super.key});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final values = List.generate(
      4,
      (i) => sales
          .where((s) {
            final age = now.difference(s.date).inDays;
            return s.status != 'Cancelled' && age >= i * 7 && age < (i + 1) * 7;
          })
          .fold(0.0, (a, b) => a + b.total),
    ).reversed.toList();
    final maxValue = values.fold(1.0, math.max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(
        4,
        (i) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FittedBox(
                  child: Text(
                    shortMoney(values[i]),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: math.max(3, 100 * values[i] / maxValue),
                  decoration: BoxDecoration(
                    color: i == 3 ? blue : const Color(0xff93b4f5),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(7),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  i == 3 ? 'This week' : '${3 - i}w ago',
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InventoryPage extends StatefulWidget {
  final MotorStore store;
  const InventoryPage({super.key, required this.store});
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String search = '', category = 'All', status = 'All stock';
  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final vehicles = s.visibleVehicles
        .where(
          (v) =>
              '${v.name} ${v.vin} ${v.brand}'.toLowerCase().contains(
                search.toLowerCase(),
              ) &&
              (category == 'All' || v.category == category) &&
              (status == 'All stock' || v.status == status),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sale In / Inventory',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${vehicles.fold(0, (a, b) => a + b.stock)} available units',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VehicleForm(store: s)),
              ),
              child: const Text('+ Intake'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          key: const Key('inventorySearch'),
          onChanged: (v) => setState(() => search = v),
          decoration: const InputDecoration(
            hintText: 'Search model, brand or VIN',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        BranchPicker(s),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [
                      'All',
                      'Supersport',
                      'Superbike',
                      'Cruiser',
                      'Roadster',
                      'Commuter',
                    ]
                    .map(
                      (v) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(v),
                          selected: category == v,
                          onSelected: (_) => setState(() => category = v),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: status,
          isExpanded: true,
          items: [
            'All stock',
            'In stock',
            'Low stock',
            'Out of stock',
          ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => status = v!),
        ),
        const SizedBox(height: 12),
        if (vehicles.isEmpty)
          emptyState(
            'No vehicles found',
            'Try another search or add a vehicle.',
            Icons.two_wheeler,
          ),
        ...vehicles.map(
          (v) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Pill(v.category),
                      const SizedBox(width: 8),
                      Text(
                        'MY ${v.year}',
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                      const Spacer(),
                      Pill(v.status, color: statusColor(v.status)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      BikeImage(v),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              v.branch,
                              style: const TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                            Text(
                              v.color,
                              style: const TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Purchase cost',
                                style: TextStyle(fontSize: 10, color: muted),
                              ),
                              Text(
                                money(v.cost),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Selling price',
                                style: TextStyle(fontSize: 10, color: muted),
                              ),
                              Text(
                                money(v.price),
                                style: const TextStyle(
                                  color: blue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${v.vin}  ·  ${v.stock} units',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VehicleDetail(store: s, vehicleId: v.id),
                          ),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VehicleForm(store: s, vehicle: v),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                      ),
                      if (s.isAdmin)
                        IconButton(
                          tooltip: 'Transfer stock',
                          onPressed: () => transferDialog(context, s, v),
                          icon: const Icon(Icons.swap_horiz, color: blue),
                        ),
                      if (s.isAdmin)
                        IconButton(
                          tooltip: 'Delete vehicle',
                          onPressed: () async {
                            if (await confirm(
                                  context,
                                  'Remove vehicle?',
                                  s.usesSupabase
                                      ? 'Remove ${v.name} from inventory?'
                                      : 'Remove ${v.name} from the demo inventory?',
                                ) &&
                                context.mounted) {
                              await perform(context, () => s.deleteVehicle(v));
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class VehicleDetail extends StatelessWidget {
  final MotorStore store;
  final String vehicleId;
  const VehicleDetail({
    super.key,
    required this.store,
    required this.vehicleId,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final v = store.vehicles.firstWhere((v) => v.id == vehicleId);
      return Scaffold(
        appBar: AppBar(title: const Text('Vehicle details')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            BikeImage(v, width: double.infinity, height: 200),
            const SizedBox(height: 22),
            Text(v.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Pill(v.category),
                Pill(v.status, color: statusColor(v.status)),
              ],
            ),
            const SizedBox(height: 20),
            Panel(
              child: Column(
                children: [
                  valueRow('Showroom', v.branch),
                  valueRow('VIN / Stock ID', v.vin),
                  valueRow('Model year', '${v.year}'),
                  valueRow('Color', v.color),
                  valueRow('Available stock', '${v.stock}'),
                  valueRow('Purchase cost', money(v.cost)),
                  valueRow('Selling price', money(v.price), bold: true),
                  valueRow(
                    'Gross unit margin',
                    money(v.price - v.cost),
                    color: green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: v.stock == 0
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('New invoice')),
                          body: BillingPage(store: store, initialVehicle: v),
                        ),
                      ),
                    ),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Create invoice'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VehicleForm(store: store, vehicle: v),
                ),
              ),
              child: const Text('Edit vehicle'),
            ),
          ],
        ),
      );
    },
  );
}

class SaleTile extends StatelessWidget {
  final Sale sale;
  final VoidCallback onTap;
  const SaleTile({super.key, required this.sale, required this.onTap});
  @override
  Widget build(BuildContext context) => Panel(
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sale.id,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ),
              Pill(sale.payment, color: statusColor(sale.payment)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xffedf2ff),
                child: Text(
                  sale.customer.substring(0, 1),
                  style: const TextStyle(color: blue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.customer,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      sale.bike,
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
              Text(
                shortMoney(sale.total),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const Divider(height: 24),
          valueRow(
            'Paid / Balance',
            '${shortMoney(sale.paid)} / ${shortMoney(sale.balance)}',
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${sale.branch}\n${dateLabel(sale.date)}',
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ),
              Pill(sale.status, color: statusColor(sale.status)),
              const Icon(Icons.chevron_right, color: muted, size: 18),
            ],
          ),
        ],
      ),
    ),
  );
}

void openSale(BuildContext context, MotorStore s, Sale sale) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => SaleDetail(store: s, saleId: sale.id),
  ),
);

class SalesPage extends StatefulWidget {
  final MotorStore store;
  const SalesPage({super.key, required this.store});
  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  String search = '', payment = 'All', period = 'All dates', sort = 'Newest';
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final rows = widget.store.visibleSales
        .where(
          (s) =>
              '${s.customer} ${s.bike} ${s.id} ${s.phone}'
                  .toLowerCase()
                  .contains(search.toLowerCase()) &&
              (payment == 'All' || s.payment == payment) &&
              (period == 'All dates' ||
                  (period == 'Today'
                      ? dateLabel(s.date) == dateLabel(now)
                      : s.date.month == now.month && s.date.year == now.year)),
        )
        .toList();
    rows.sort(
      (a, b) => sort == 'Highest amount'
          ? b.total.compareTo(a.total)
          : sort == 'Oldest'
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Sale Out', style: Theme.of(context).textTheme.headlineMedium),
        const Text(
          'Vehicle sales & transaction ledger',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 18),
        MetricGrid(
          children: [
            Metric(
              'Sales volume',
              shortMoney(
                rows
                    .where((s) => s.status != 'Cancelled')
                    .fold(0.0, (a, b) => a + b.total),
              ),
              'Filtered invoices',
              Icons.receipt_long,
            ),
            Metric(
              'Outstanding',
              shortMoney(
                rows
                    .where((s) => s.status != 'Cancelled')
                    .fold(0.0, (a, b) => a + b.balance),
              ),
              'Customer balance',
              Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: (v) => setState(() => search = v),
          decoration: const InputDecoration(
            hintText: 'Customer, model, phone or invoice',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        BranchPicker(widget.store),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: ['All', 'Paid', 'Partial', 'Pending']
              .map(
                (v) => ChoiceChip(
                  label: Text(v),
                  selected: payment == v,
                  onSelected: (_) => setState(() => payment = v),
                ),
              )
              .toList(),
        ),
        Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: period,
                isExpanded: true,
                items: ['All dates', 'Today', 'This month']
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => period = v!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                value: sort,
                isExpanded: true,
                items: ['Newest', 'Oldest', 'Highest amount']
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => sort = v!),
              ),
            ),
          ],
        ),
        SectionTitle(
          'Sales records',
          subtitle: '${rows.length} matching invoices',
          action: IconButton(
            tooltip: 'Export ledger PDF',
            onPressed: rows.isEmpty ? null : () => exportLedger(context, rows),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ),
        if (rows.isEmpty)
          emptyState(
            'No sales found',
            'Change the filters or create your first invoice.',
            Icons.receipt_long,
          ),
        ...rows.map(
          (sale) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SaleTile(
              sale: sale,
              onTap: () => openSale(context, widget.store, sale),
            ),
          ),
        ),
      ],
    );
  }
}

class SaleDetail extends StatelessWidget {
  final MotorStore store;
  final String saleId;
  const SaleDetail({super.key, required this.store, required this.saleId});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final s = store.sales.firstWhere((s) => s.id == saleId);
      var itemImage = s.vehicleImage;
      if (itemImage.isEmpty) {
        for (final vehicle in store.vehicles) {
          if (vehicle.id == s.vehicleId) {
            itemImage = vehicle.image;
            break;
          }
        }
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Sale details')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(s.id, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                Pill(s.payment, color: statusColor(s.payment)),
                Pill(s.status, color: statusColor(s.status)),
              ],
            ),
            const SizedBox(height: 18),
            Semantics(
              image: true,
              label: '${s.bike} sale item image',
              child: ItemImage(
                itemImage,
                key: const Key('saleItemImage'),
                width: double.infinity,
                height: 190,
              ),
            ),
            const SectionTitle('Customer & vehicle'),
            Panel(
              child: Column(
                children: [
                  valueRow('Customer', s.customer),
                  valueRow('Phone', s.phone),
                  valueRow(
                    'Address',
                    s.address.isEmpty ? 'Not entered' : s.address,
                  ),
                  valueRow('Motorcycle', s.bike),
                  valueRow('Quantity', '${s.quantity}'),
                  valueRow('Showroom', s.branch),
                  valueRow('Executive', s.employee),
                  valueRow('Sale date', dateLabel(s.date)),
                ],
              ),
            ),
            const SectionTitle('Financial ledger'),
            Panel(
              child: Column(
                children: [
                  valueRow(
                    'Vehicle amount',
                    money(
                      (s.unitPrice > 0
                              ? s.unitPrice
                              : (s.subtotal - s.extras - s.repairCost) /
                                    s.quantity) *
                          s.quantity,
                    ),
                  ),
                  valueRow('Registration / extras', money(s.extras)),
                  valueRow('Repair cost', money(s.repairCost)),
                  valueRow('Subtotal', money(s.subtotal)),
                  valueRow('Discount', money(s.discount)),
                  valueRow(
                    'GST (${s.taxRate.toStringAsFixed(2)}%)',
                    money(s.tax),
                  ),
                  const Divider(),
                  valueRow('Invoice total', money(s.total), bold: true),
                  valueRow('Amount paid', money(s.paid), color: green),
                  valueRow(
                    'Balance payable',
                    money(s.balance),
                    bold: true,
                    color: amber,
                  ),
                  valueRow('Payment mode', s.mode),
                  if (s.finance)
                    valueRow('Estimated monthly EMI', money(s.installment)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => viewInvoice(context, s),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Invoice PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: () => shareInvoice(context, s),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ],
            ),
            if (s.status != 'Cancelled') ...[
              const SectionTitle('Update transaction'),
              DropdownButtonFormField<String>(
                key: ValueKey(s.status),
                initialValue: s.status,
                items:
                    [
                          'Booking confirmed',
                          'Balance pending',
                          'Payment completed',
                          'Ready for delivery',
                          'Delivered',
                          'Cancelled',
                        ]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                onChanged: (value) async {
                  if (value == null || value == s.status) return;
                  if (await confirm(
                        context,
                        'Update status?',
                        'Set this sale to $value?',
                      ) &&
                      context.mounted) {
                    await perform(context, () => store.updateStatus(s, value));
                  }
                },
              ),
              if (s.balance > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => paymentDialog(context, store, s),
                    icon: const Icon(Icons.add_card),
                    label: const Text('Record payment'),
                  ),
                ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

class MorePage extends StatelessWidget {
  final MotorStore store;
  const MorePage({super.key, required this.store});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text('Your workspace', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 20),
      Panel(
        child: Column(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xffdbeafe),
              child: Text(
                store.userInitials,
                style: const TextStyle(
                  color: blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(store.userName, style: Theme.of(context).textTheme.titleLarge),
            Text(
              store.isAdmin ? 'Network administrator' : store.userBranch,
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 10),
            Pill(store.isAdmin ? 'ADMIN ACCESS' : 'SHOWROOM STAFF'),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Panel(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.calculate_outlined, color: blue),
              title: const Text('EMI calculator'),
              subtitle: const Text('Plan down payment and installments'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmiPage()),
              ),
            ),
            if (store.isAdmin)
              ListTile(
                leading: const Icon(Icons.storefront_outlined, color: blue),
                title: const Text('Stores & team'),
                subtitle: Text(
                  '${store.branches.length} showrooms · ${store.staff.length} employees',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StoresPage(store: store)),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.notifications_none, color: blue),
              title: const Text('Inventory alerts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AlertsPage(store: store)),
              ),
            ),
          ],
        ),
      ),
      SectionTitle(store.usesSupabase ? 'Cloud account' : 'Demo settings'),
      Text(
        store.usesSupabase
            ? 'Connected to Supabase. Access is enforced by your account role and assigned showroom.'
            : 'This build works offline with sample records. Changes stay on this device and do not update the PHP/MySQL database.',
        style: const TextStyle(color: muted, height: 1.5),
      ),
      const SizedBox(height: 16),
      if (store.usesSupabase)
        OutlinedButton.icon(
          onPressed: () =>
              perform(context, store.refresh, success: 'Cloud data refreshed'),
          icon: const Icon(Icons.cloud_sync_outlined),
          label: const Text('Refresh cloud data'),
        )
      else
        OutlinedButton.icon(
          onPressed: () async {
            if (await confirm(
                  context,
                  'Reset demo data?',
                  'This replaces all locally created demo vehicles, sales and staff with the sample records.',
                ) &&
                context.mounted) {
              await perform(context, store.reset, success: 'Demo data reset');
            }
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset demo data'),
        ),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: () async {
          await store.logout();
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('Sign out'),
      ),
      const SizedBox(height: 24),
      const Center(
        child: Text(
          'MotorStock · Flutter 1.0',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ),
    ],
  );
}

class EmiPage extends StatefulWidget {
  const EmiPage({super.key});
  @override
  State<EmiPage> createState() => _EmiPageState();
}

class _EmiPageState extends State<EmiPage> {
  final price = TextEditingController(text: '500000'),
      down = TextEditingController(text: '100000');
  double rate = 9.5;
  int months = 36;
  @override
  void dispose() {
    price.dispose();
    down.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = double.tryParse(price.text) ?? 0,
        d = double.tryParse(down.text) ?? 0;
    final valid = p > 0 && d >= 0 && d <= p;
    final loan = valid ? p - d : 0.0;
    final monthly = emi(loan, rate, months);
    return Scaffold(
      appBar: AppBar(title: const Text('EMI calculator')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Make the numbers work.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore a repayment plan before you commit.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Vehicle price (₹)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: down,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Down payment (₹)',
              errorText: valid
                  ? null
                  : 'Enter a price and a down payment within that price.',
            ),
          ),
          const SizedBox(height: 22),
          valueRow('Annual interest rate', '${rate.toStringAsFixed(1)}%'),
          Slider(
            value: rate,
            min: 0,
            max: 24,
            divisions: 48,
            label: '$rate%',
            onChanged: (v) => setState(() => rate = v),
          ),
          const SizedBox(height: 12),
          const Text(
            'Loan tenure',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [12, 24, 36, 48, 60, 72]
                .map(
                  (v) => ChoiceChip(
                    label: Text('$v mo'),
                    selected: months == v,
                    onSelected: (_) => setState(() => months = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [blue, Color(0xff2563eb)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESTIMATED MONTHLY EMI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  money(monthly),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'for $months months',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Panel(
            child: Column(
              children: [
                valueRow('Loan principal', money(loan)),
                valueRow(
                  'Total interest',
                  money(math.max(0, monthly * months - loan)),
                ),
                valueRow(
                  'Total loan repayment',
                  money(monthly * months),
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Illustrative estimate. Fees and lender-specific calculations are excluded.',
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }
}

class StoresPage extends StatelessWidget {
  final MotorStore store;
  final bool embedded;
  const StoresPage({super.key, required this.store, this.embedded = false});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final branches = store.branches
          .where((b) => store.isAdmin || b.name == store.userBranch)
          .toList();
      final content = ListView(
        padding: const EdgeInsets.all(18),
        children: [
          SectionTitle(
            'Stores',
            subtitle: 'Choose a showroom to view its employees.',
            action: store.isAdmin
                ? IconButton(
                    tooltip: 'Add showroom',
                    onPressed: () => branchDialog(context, store),
                    icon: const Icon(Icons.add_business, color: blue),
                  )
                : null,
          ),
          if (branches.isEmpty)
            emptyState(
              'No stores yet',
              'Your assigned showroom will appear here.',
              Icons.storefront_outlined,
            ),
          ...branches.map((b) {
            final rows = store.sales.where(
              (s) => s.branch == b.name && s.status != 'Cancelled',
            );
            final employees = store.staff
                .where((e) => e.branch == b.name)
                .length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Panel(
                child: InkWell(
                  key: Key('store-${b.id}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoreDetailPage(store: store, branch: b),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront, color: blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              b.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: muted),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        b.location,
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      valueRow('Employees', '$employees'),
                      valueRow(
                        'Available bikes',
                        '${store.vehicles.where((v) => v.branch == b.name).fold(0, (a, b) => a + b.stock)}',
                      ),
                      valueRow(
                        'Invoiced revenue',
                        shortMoney(rows.fold(0.0, (a, b) => a + b.total)),
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );
      return embedded
          ? content
          : Scaffold(
              appBar: AppBar(title: const Text('Stores & team')),
              body: content,
            );
    },
  );
}

class StoreDetailPage extends StatelessWidget {
  final MotorStore store;
  final Branch branch;
  const StoreDetailPage({super.key, required this.store, required this.branch});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final employees = store.staff
          .where((e) => e.branch == branch.name)
          .toList();
      return Scaffold(
        appBar: AppBar(title: Text(branch.name)),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(branch.location, style: const TextStyle(color: muted)),
            SectionTitle(
              'Employees',
              subtitle: '${employees.length} team members',
              action: store.isAdmin
                  ? TextButton.icon(
                      onPressed: () => staffDialog(
                        context,
                        store,
                        initialBranch: branch.name,
                      ),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('Add employee'),
                    )
                  : null,
            ),
            if (employees.isEmpty)
              emptyState(
                'No employees yet',
                'Add an employee to this showroom to track their sales.',
                Icons.people_outline,
              ),
            ...employees.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  child: InkWell(
                    key: Key('employee-${e.id}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EmployeeStatsPage(store: store, employee: e),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              child: Text(e.name.isEmpty ? '?' : e.name[0]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    e.role,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (store.isAdmin)
                              PopupMenuButton<String>(
                                tooltip: 'Manage ${e.name}',
                                onSelected: (action) async {
                                  if (action == 'edit') {
                                    await staffDialog(
                                      context,
                                      store,
                                      employee: e,
                                    );
                                  } else if (action == 'freeze') {
                                    await perform(
                                      context,
                                      () => store.saveStaff(e.freeze()),
                                    );
                                  } else if (await confirm(
                                        context,
                                        'Remove staff?',
                                        'Remove ${e.name} from the team?',
                                      ) &&
                                      context.mounted) {
                                    await perform(
                                      context,
                                      () => store.removeStaff(e),
                                    );
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit employee'),
                                  ),
                                  PopupMenuItem(
                                    value: 'freeze',
                                    child: Text(
                                      e.frozen ? 'Unfreeze' : 'Freeze access',
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Remove'),
                                  ),
                                ],
                              )
                            else
                              const Icon(Icons.chevron_right, color: muted),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Pill('Shift ${e.shift}'),
                            Pill(
                              e.frozen ? 'Frozen' : 'Active',
                              color: e.frozen ? amber : green,
                            ),
                            const Pill('View statistics'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class EmployeeStatsPage extends StatelessWidget {
  final MotorStore store;
  final Staff employee;
  const EmployeeStatsPage({
    super.key,
    required this.store,
    required this.employee,
  });

  static List<Sale> salesFor(Iterable<Sale> sales, Staff employee) =>
      sales
          .where(
            (s) =>
                s.status != 'Cancelled' &&
                s.branch == employee.branch &&
                (s.staffId.isNotEmpty
                    ? s.staffId == employee.id
                    : s.employee == employee.name),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final current =
          store.staff.where((e) => e.id == employee.id).firstOrNull ?? employee;
      final rows = salesFor(store.sales, current);
      final revenue = rows.fold(0.0, (sum, sale) => sum + sale.total);
      final collected = rows.fold(0.0, (sum, sale) => sum + sale.paid);
      final outstanding = rows.fold(0.0, (sum, sale) => sum + sale.balance);
      final units = rows.fold(0, (sum, sale) => sum + sale.quantity);
      return Scaffold(
        appBar: AppBar(title: const Text('Employee statistics')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              current.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '${current.role} · ${current.branch}',
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 8),
            const Text(
              'All time · Cancelled invoices excluded',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            MetricGrid(
              children: [
                Metric(
                  'Invoices',
                  '${rows.length}',
                  'Assigned sales',
                  Icons.receipt_long,
                ),
                Metric(
                  'Vehicles sold',
                  '$units',
                  'Units invoiced',
                  Icons.two_wheeler,
                ),
                Metric(
                  'Invoiced revenue',
                  shortMoney(revenue),
                  'Includes GST and costs',
                  Icons.trending_up,
                ),
                Metric(
                  'Collected',
                  shortMoney(collected),
                  'Payments received',
                  Icons.payments_outlined,
                ),
                Metric(
                  'Outstanding',
                  shortMoney(outstanding),
                  'Pending collection',
                  Icons.account_balance_wallet_outlined,
                ),
                Metric(
                  'Average invoice',
                  shortMoney(rows.isEmpty ? 0 : revenue / rows.length),
                  'Revenue per invoice',
                  Icons.analytics_outlined,
                ),
              ],
            ),
            const SectionTitle('Recent sales'),
            if (rows.isEmpty)
              emptyState(
                'No sales recorded',
                'Invoices assigned to this employee will appear here.',
                Icons.receipt_long_outlined,
              ),
            ...rows
                .take(20)
                .map(
                  (sale) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SaleTile(
                      sale: sale,
                      onTap: () => openSale(context, store, sale),
                    ),
                  ),
                ),
          ],
        ),
      );
    },
  );
}

class AlertsPage extends StatelessWidget {
  final MotorStore store;
  const AlertsPage({super.key, required this.store});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final rows = store.visibleVehicles.where((v) => v.stock <= 2).toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Inventory alerts')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (rows.isEmpty)
              emptyState(
                'All stocked up',
                'No low-stock alerts for this showroom.',
                Icons.check_circle_outline,
              ),
            ...rows.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      color: statusColor(v.status),
                    ),
                    title: Text(v.name),
                    subtitle: Text('${v.branch}\n${v.stock} units available'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VehicleForm(store: store, vehicle: v),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
