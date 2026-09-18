import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'branding.dart';
import 'domain.dart';
import 'store.dart';
import 'ui.dart';
import 'forms.dart';
import 'invoice.dart';
import 'motion.dart';
import 'login_background.dart';

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
      child: LoginAtmosphere(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            systemOverlayStyle:
                (isDarkMode(context)
                        ? SystemUiOverlayStyle.light
                        : SystemUiOverlayStyle.dark)
                    .copyWith(
                      statusBarColor: Colors.transparent,
                      systemNavigationBarColor: Theme.of(context)
                          .scaffoldBackgroundColor,
                    ),
            leading: IconButton(
              key: const Key('welcomeBack'),
              tooltip: 'Back to welcome',
              onPressed: busy ? null : () => setState(() => showLogin = false),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDarkMode(context) ? darkInk : brandNavy,
              ),
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
                      const Brand(animateText: true),
                      const SizedBox(height: 32),
                      StaggeredTextReveal(
                        words: 'Welcome back',
                        delay: const Duration(milliseconds: 140),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 26),
                      if (!widget.store.usesSupabase) ...[
                        SizedBox(
                          width: double.infinity,
                          child: CompactMenu(
                            key: const Key('loginRole'),
                            label: 'Demo role',
                            value: admin ? 'Admin' : 'Showroom staff',
                            options: const ['Admin', 'Showroom staff'],
                            icon: Icons.person_outline_rounded,
                            animateText: true,
                            onChanged: (v) => setState(() {
                              admin = v == 'Admin';
                              user.text = admin
                                  ? 'admin@motorstock.demo'
                                  : 'staff@motorstock.demo';
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const StaggeredTextReveal(
                              words: 'Login ID',
                              textAlign: TextAlign.start,
                              delay: Duration(milliseconds: 320),
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
                            const StaggeredTextReveal(
                              words: 'Password',
                              textAlign: TextAlign.start,
                              delay: Duration(milliseconds: 380),
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
                                        if (mounted) {
                                          setState(() => busy = false);
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.arrow_forward),
                              label: busy
                                  ? const Text('Signing in…')
                                  : const StaggeredTextReveal(
                                      words: 'Sign in',
                                      delay: Duration(milliseconds: 440),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StaggeredTextReveal(
                            words: widget.store.usesSupabase
                                ? 'Connected workspace'
                                : 'Offline demo',
                            delay: const Duration(milliseconds: 500),
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                          if (!widget.store.usesSupabase)
                            IconButton(
                              tooltip: 'Demo details',
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                size: 17,
                                color: muted,
                              ),
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Offline demo'),
                                  content: const Text(
                                    'Sample data is saved on this device.\n\nUse the prefilled credentials or sign in with demo / demo123.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Got it'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int page = 0;
  final visited = <int>{0};
  late final _tabAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );

  void go(int i) {
    if (i == page) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    setState(() {
      page = i;
      visited.add(i);
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _tabAnimation.value = 1;
    } else {
      _tabAnimation.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _tabAnimation.value = 1;
  }

  @override
  void dispose() {
    _tabAnimation.dispose();
    super.dispose();
  }

  Widget destination(int index) => switch (index) {
    0 => Dashboard(store: widget.store, go: go),
    1 => InventoryPage(store: widget.store),
    2 => BillingPage(store: widget.store),
    3 => SalesPage(store: widget.store),
    _ => StoresPage(store: widget.store, embedded: true),
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: isDarkMode(context) ? Colors.white : brandNavy,
      systemOverlayStyle: isDarkMode(context)
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      toolbarHeight: 72,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode(context)
                ? const [Color(0xff1d3147), Color(0xff081321)]
                : const [Color(0xf7ffffff), Color(0xe8edf6f8)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1610172a),
              blurRadius: 22,
              spreadRadius: -8,
            ),
          ],
        ),
      ),
      title: Brand(compact: true, inverse: isDarkMode(context)),
      actions: [
        IconButton(
          key: const Key('appearanceMenu'),
          tooltip: 'Appearance',
          onPressed: () => showAppearanceSheet(context, widget.store),
          icon: Icon(
            widget.store.appearance == 'Dark'
                ? Icons.dark_mode_rounded
                : widget.store.appearance == 'System'
                ? Icons.brightness_auto_rounded
                : Icons.light_mode_rounded,
            color: isDarkMode(context) ? Colors.white : brandNavy,
          ),
        ),
        IconButton(
          tooltip: 'Inventory alerts',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AlertsPage(store: widget.store)),
          ),
          icon: Badge(
            backgroundColor: danger,
            textColor: Colors.white,
            label: Text(
              '${widget.store.visibleVehicles.where((v) => v.stock <= 2).length}',
            ),
            child: Icon(
              Icons.notifications_none,
              color: isDarkMode(context) ? Colors.white : brandNavy,
            ),
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
                body: ListenableBuilder(
                  listenable: widget.store,
                  builder: (context, _) => MorePage(store: widget.store),
                ),
              ),
            ),
          ),
          icon: CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xffdff6f7),
            child: Text(
              widget.store.userInitials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: brandNavy,
              ),
            ),
          ),
        ),
      ],
    ),
    body: TactileBackdrop(
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: AnimatedBuilder(
                  animation: _tabAnimation,
                  builder: (context, child) {
                    final progress = Curves.easeOutCubic.transform(
                      _tabAnimation.value,
                    );
                    return Opacity(
                      opacity: .35 + .65 * progress,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - progress)),
                        child: child,
                      ),
                    );
                  },
                  child: IndexedStack(
                    index: page,
                    children: List.generate(
                      5,
                      (index) => TickerMode(
                        enabled: index == page,
                        child: ExcludeFocus(
                          excluding: index != page,
                          child: visited.contains(index)
                              ? PrimaryScrollController.none(
                                  child: destination(index),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        decoration: BoxDecoration(
          color: surfaceColor(context)
              .withValues(alpha: isDarkMode(context) ? .84 : .62),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: isDarkMode(context)
                ? borderColor(context)
                : Colors.white.withValues(alpha: .85),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1710172a),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: NavigationBar(
              backgroundColor: surfaceColor(context)
                  .withValues(alpha: isDarkMode(context) ? .82 : .58),
              animationDuration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 380),
              selectedIndex: page,
              onDestinationSelected: go,
              destinations: [
                NavigationDestination(
                  icon: _TabIcon(
                    CupertinoIcons.square_grid_2x2,
                    selected: page == 0,
                  ),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: _TabIcon(CupertinoIcons.cube_box, selected: page == 1),
                  label: 'Sales In',
                ),
                NavigationDestination(
                  icon: _TabIcon(
                    CupertinoIcons.doc_text,
                    selected: page == 2,
                    primary: true,
                  ),
                  label: 'Bill',
                ),
                NavigationDestination(
                  icon: _TabIcon(CupertinoIcons.bag, selected: page == 3),
                  label: 'Sales Out',
                ),
                NavigationDestination(
                  icon: _TabIcon(
                    CupertinoIcons.building_2_fill,
                    selected: page == 4,
                  ),
                  label: 'Stores',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _TabIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final bool primary;
  const _TabIcon(this.icon, {required this.selected, this.primary = false});

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: selected ? 1.12 : 1,
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 360),
    curve: Curves.easeOutBack,
    child: AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      width: primary ? 38 : 32,
      height: primary ? 38 : 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected && isDarkMode(context)
            ? const Color(0xff456b9d)
            : Colors.transparent,
        border: primary && isDarkMode(context)
            ? Border.all(color: selected ? const Color(0xff7897b8) : darkLine)
            : null,
        boxShadow: selected && isDarkMode(context)
            ? const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 12,
                  spreadRadius: -3,
                ),
              ]
            : const [],
      ),
      child: Icon(
        icon,
        size: 22,
        color: selected
            ? (isDarkMode(context) ? Colors.white : brandNavy)
            : secondaryTextColor(context),
      ),
    ),
  );
}

class BranchPicker extends StatelessWidget {
  final MotorStore store;
  const BranchPicker(this.store, {super.key});
  @override
  Widget build(BuildContext context) => store.isAdmin
      ? CompactMenu(
          key: const Key('branchPicker'),
          label: 'Showroom',
          value: store.selectedBranch,
          options: ['All branches', ...store.branchNames],
          labels: const {'All branches': 'All showrooms'},
          icon: CupertinoIcons.building_2_fill,
          onChanged: store.chooseBranch,
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
                'Week' => !s.date.isBefore(
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
    final s = widget.store;
    final revenue = rows.fold<double>(0, (a, b) => a + b.total);
    final stock = s.visibleVehicles.fold<int>(0, (a, b) => a + b.stock);
    final alerts = s.visibleVehicles.where((v) => v.stock <= 2).toList();
    return ListView(
      key: const PageStorageKey('dashboardScroll'),
      padding: const EdgeInsets.all(20),
      children: [
        MotionEntrance(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Overview',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              ActionMenu(
                tooltip: 'Dashboard tools',
                actions: [
                  MenuAction(
                    'EMI calculator',
                    Icons.calculate_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmiPage()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: BranchPicker(s)),
            const SizedBox(width: 8),
            CompactMenu(
              key: const Key('dashboardPeriod'),
              label: 'Reporting period',
              value: period,
              options: const ['Today', 'Week', 'Month'],
              onChanged: (v) => setState(() => period = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MetricGrid(
          children: [
            Metric(
              'Revenue',
              shortMoney(revenue),
              '',
              Icons.payments_outlined,
              numericValue: revenue,
              formatter: shortMoney,
            ),
            Metric(
              'In stock',
              '$stock',
              '',
              Icons.two_wheeler,
              numericValue: stock,
              formatter: (v) => '${v.round()}',
            ),
            Metric(
              'Bikes sold',
              '${rows.fold<int>(0, (a, b) => a + b.quantity)}',
              '',
              Icons.shopping_bag_outlined,
              numericValue: rows.fold<int>(0, (a, b) => a + b.quantity),
              formatter: (v) => '${v.round()}',
            ),
            Metric(
              'Outstanding',
              shortMoney(rows.fold<double>(0, (a, b) => a + b.balance)),
              '',
              Icons.account_balance_wallet_outlined,
              numericValue: rows.fold<double>(0, (a, b) => a + b.balance),
              formatter: shortMoney,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => widget.go(2),
          icon: const Icon(Icons.add_rounded, size: 19),
          label: const Text('New invoice'),
        ),
        const SectionTitle('Last 4 weeks'),
        Panel(child: RevenueChart(s.visibleSales)),
        SectionTitle(
          'Recent sales',
          action: TextButton(
            onPressed: () => widget.go(3),
            child: const Text('See all'),
          ),
        ),
        if (s.visibleSales.isEmpty)
          const Panel(
            child: Text('No sales yet', style: TextStyle(color: muted)),
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
        const SizedBox(height: 12),
        DetailDisclosure(
          title: 'Stock alerts · ${alerts.length}',
          leading: const Icon(
            Icons.inventory_2_outlined,
            size: 20,
            color: amber,
          ),
          child: Column(
            children: [
              if (alerts.isEmpty) const Text('Stock levels look healthy.'),
              ...alerts.map(
                (v) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: BikeImage(v, width: 48, height: 46),
                  title: Text(
                    v.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    v.branch,
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Pill(
                    '${v.stock} left',
                    color: statusColor(v.status),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleForm(store: s, vehicle: v),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DetailDisclosure(
          title: 'Revenue by showroom',
          leading: const Icon(
            CupertinoIcons.building_2_fill,
            size: 20,
            color: muted,
          ),
          child: Column(
            children: s.branches
                .where((b) => s.allBranches || b.name == s.effectiveBranch)
                .map((b) {
                  final value = rows
                      .where((sale) => sale.branch == b.name)
                      .fold<double>(0, (a, b) => a + b.total);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        valueRow(b.name, shortMoney(value)),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: revenue == 0 ? 0 : value / revenue,
                          ),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 650),
                          curve: Curves.easeOutCubic,
                          builder: (context, progress, _) =>
                              LinearProgressIndicator(
                                value: progress,
                                minHeight: 5,
                                color: accent,
                                borderRadius: BorderRadius.circular(8),
                                backgroundColor: line,
                                semanticsLabel: '${b.name} revenue share',
                              ),
                        ),
                      ],
                    ),
                  );
                })
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class RevenueChart extends StatefulWidget {
  final List<Sale> sales;
  const RevenueChart(this.sales, {super.key});
  @override
  State<RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart> {
  int selected = 3;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weeks = List.generate(
      4,
      (i) => widget.sales.where((s) {
        final age = now.difference(s.date).inDays;
        return s.status != 'Cancelled' && age >= i * 7 && age < (i + 1) * 7;
      }).toList(),
    ).reversed.toList();
    final values = weeks
        .map((week) => week.fold(0.0, (sum, sale) => sum + sale.total))
        .toList();
    final maxValue = values.fold(1.0, math.max);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week ${selected + 1} · ${weeks[selected].length} invoices',
                    key: const Key('revenueSelection'),
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                  const SizedBox(height: 4),
                  AnimatedAmount(
                    value: values[selected],
                    format: money,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: isDarkMode(context) ? neon : brandNavy,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chart_bar_alt_fill,
              color: brandTeal,
              size: 24,
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 172,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              4,
              (i) => Expanded(
                child: Semantics(
                  button: true,
                  selected: i == selected,
                  label:
                      'Week ${i + 1}, ${money(values[i])}, ${weeks[i].length} invoices',
                  child: PressFeedback(
                    child: InkWell(
                      key: Key('revenueWeek$i'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        if (selected == i) return;
                        HapticFeedback.selectionClick();
                        setState(() => selected = i);
                      },
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FittedBox(
                                child: Text(
                                  shortMoney(values[i]),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: selected == i
                                        ? (isDarkMode(context)
                                              ? neon
                                              : brandNavy)
                                        : secondaryTextColor(context),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    begin: 0,
                                    end: math.max(
                                      4,
                                      104 * values[i] / maxValue,
                                    ),
                                  ),
                                  duration: reduced
                                      ? Duration.zero
                                      : Duration(milliseconds: 600 + i * 70),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, height, _) =>
                                      AnimatedContainer(
                                        duration: reduced
                                            ? Duration.zero
                                            : const Duration(milliseconds: 250),
                                        height: height,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: selected == i
                                                ? [accent, brandTeal]
                                                : [
                                                    const Color(0xffc7e8ed),
                                                    const Color(0xffa5cad7),
                                                  ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                child: Text(
                                  i == 3 ? 'This week' : '${3 - i}w ago',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: selected == i ? brandNavy : muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tap a bar to explore a week',
          style: TextStyle(color: muted, fontSize: 11),
        ),
      ],
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

  void openVehicle(Vehicle v) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VehicleDetail(store: widget.store, vehicleId: v.id),
    ),
  );

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
      key: const PageStorageKey('inventoryScroll'),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sales In',
                style: Theme.of(context).textTheme.headlineMedium,
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
            hintText: 'Search bikes',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        BranchPicker(s),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CompactMenu(
                key: const Key('inventoryCategory'),
                label: 'Category',
                value: category,
                options: [
                  'All',
                  ...{
                    ...const [
                      'Supersport',
                      'Superbike',
                      'Cruiser',
                      'Roadster',
                      'Commuter',
                    ],
                    ...s.visibleVehicles.map((v) => v.category),
                  },
                ],
                labels: const {'All': 'All categories'},
                onChanged: (v) => setState(() => category = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CompactMenu(
                key: const Key('inventoryStock'),
                label: 'Stock availability',
                value: status,
                options: const [
                  'All stock',
                  'In stock',
                  'Low stock',
                  'Out of stock',
                ],
                onChanged: (v) => setState(() => status = v),
              ),
            ),
          ],
        ),
        SectionTitle(
          'Bikes',
          action: Text(
            '${vehicles.length}',
            style: const TextStyle(color: muted, fontSize: 13),
          ),
        ),
        if (vehicles.isEmpty)
          emptyState(
            'No bikes found',
            'Try another filter.',
            Icons.two_wheeler,
          ),
        ...vehicles.map(
          (v) => MotionEntrance(
            key: ValueKey(v.id),
            order: vehicles.indexOf(v).clamp(0, 4),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PressFeedback(
                child: Panel(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => openVehicle(v),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                      child: Row(
                        children: [
                          BikeImage(v, width: 72, height: 76),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  v.branch,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 5,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      money(v.price),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isDarkMode(context)
                                            ? neon
                                            : brandNavy,
                                      ),
                                    ),
                                    Text(
                                      '${v.stock} left',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: statusColor(v.status),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ActionMenu(
                            key: ValueKey('vehicleActions-${v.id}'),
                            tooltip: 'Actions for ${v.name}',
                            actions: [
                              MenuAction(
                                'View details',
                                Icons.info_outline,
                                () => openVehicle(v),
                              ),
                              MenuAction(
                                'Edit bike',
                                Icons.edit_outlined,
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        VehicleForm(store: s, vehicle: v),
                                  ),
                                ),
                              ),
                              if (s.isAdmin)
                                MenuAction(
                                  'Transfer stock',
                                  Icons.swap_horiz,
                                  () => transferDialog(context, s, v),
                                ),
                              if (s.isAdmin)
                                MenuAction('Delete vehicle', Icons.delete_outline, () async {
                                  if (await confirm(
                                        context,
                                        'Remove vehicle?',
                                        s.usesSupabase
                                            ? 'Remove ${v.name} from inventory?'
                                            : 'Remove ${v.name} from the demo inventory?',
                                      ) &&
                                      context.mounted) {
                                    await perform(
                                      context,
                                      () => s.deleteVehicle(v),
                                    );
                                  }
                                }, destructive: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
  Widget build(BuildContext context) => MotionEntrance(
    child: PressFeedback(
      child: Panel(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.customer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sale.bike,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      fit: FlexFit.tight,
                      child: Text(
                        shortMoney(sale.total),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDarkMode(context) ? neon : brandNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateLabel(sale.date),
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                    ),
                    Pill(
                      sale.status == 'Cancelled' ? 'Cancelled' : sale.payment,
                      color: statusColor(
                        sale.status == 'Cancelled' ? 'Cancelled' : sale.payment,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: muted,
                      size: 17,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
    final total = rows
        .where((s) => s.status != 'Cancelled')
        .fold<double>(0, (a, b) => a + b.total);
    final balance = rows
        .where((s) => s.status != 'Cancelled')
        .fold<double>(0, (a, b) => a + b.balance);
    return ListView(
      key: const PageStorageKey('salesScroll'),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sales Out',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            ActionMenu(
              tooltip: 'Sales actions',
              actions: [
                MenuAction(
                  'Export ledger PDF',
                  Icons.file_download_outlined,
                  () => exportLedger(context, rows),
                  enabled: rows.isNotEmpty,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        MetricGrid(
          children: [
            Metric(
              'Revenue',
              shortMoney(total),
              '',
              Icons.receipt_long,
              numericValue: total,
              formatter: shortMoney,
            ),
            Metric(
              'Outstanding',
              shortMoney(balance),
              '',
              Icons.account_balance_wallet_outlined,
              numericValue: balance,
              formatter: shortMoney,
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          key: const Key('salesSearch'),
          onChanged: (v) => setState(() => search = v),
          decoration: const InputDecoration(
            hintText: 'Search sales',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 3, child: BranchPicker(widget.store)),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: CompactMenu(
                key: const Key('salesPayment'),
                label: 'Payment status',
                value: payment,
                options: const ['All', 'Paid', 'Partial', 'Pending'],
                labels: const {'All': 'All payments'},
                onChanged: (v) => setState(() => payment = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CompactMenu(
                key: const Key('salesPeriod'),
                label: 'Invoice date',
                value: period,
                options: const ['All dates', 'Today', 'This month'],
                onChanged: (v) => setState(() => period = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CompactMenu(
                key: const Key('salesSort'),
                label: 'Sort sales',
                value: sort,
                options: const ['Newest', 'Oldest', 'Highest amount'],
                icon: Icons.sort_rounded,
                onChanged: (v) => setState(() => sort = v),
              ),
            ),
          ],
        ),
        SectionTitle(
          'Invoices',
          action: Text(
            '${rows.length}',
            style: const TextStyle(color: muted, fontSize: 13),
          ),
        ),
        if (rows.isEmpty)
          emptyState(
            'No sales found',
            'Try another filter.',
            Icons.receipt_long,
          ),
        ...rows.map(
          (sale) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
                  if (s.customerImage.isNotEmpty) ...[
                    Semantics(
                      image: true,
                      label: '${s.customer} customer photo',
                      child: ItemImage(
                        s.customerImage,
                        key: const Key('saleCustomerImage'),
                        width: double.infinity,
                        height: 170,
                        fallbackIcon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
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
                isExpanded: true,
                itemHeight: 52,
                menuMaxHeight: MediaQuery.sizeOf(context).height * .48,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: raisedColor(context),
                iconEnabledColor: secondaryTextColor(context),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(labelText: 'Status'),
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
      const SectionTitle('Appearance'),
      Panel(
        child: Row(
          children: [
            for (final item in const [
              ('Light', Icons.light_mode_rounded),
              ('System', Icons.brightness_auto_rounded),
              ('Dark', Icons.dark_mode_rounded),
            ]) ...[
              TactileChoice(
                label: item.$1,
                icon: item.$2,
                selected: store.appearance == item.$1,
                onTap: () => store.setAppearance(item.$1),
              ),
              if (item.$1 != 'Dark') const SizedBox(width: 8),
            ],
          ],
        ),
      ),
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
            ? 'Connected to your showroom account.'
            : 'Offline demo. Sample data and changes stay on this device.',
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
          'MotorStock · 1.2.0',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ),
    ],
  );
}

Future<void> showAppearanceSheet(BuildContext context, MotorStore store) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final item in const [
                    ('Light', Icons.light_mode_rounded),
                    ('System', Icons.brightness_auto_rounded),
                    ('Dark', Icons.dark_mode_rounded),
                  ]) ...[
                    TactileChoice(
                      label: item.$1,
                      icon: item.$2,
                      selected: store.appearance == item.$1,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        store.setAppearance(item.$1);
                      },
                    ),
                    if (item.$1 != 'Dark') const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

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
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Stores',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (store.isAdmin)
                ActionMenu(
                  tooltip: 'Store actions',
                  actions: [
                    MenuAction(
                      'Add showroom',
                      Icons.add_business_outlined,
                      () => branchDialog(context, store),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (branches.isEmpty)
            emptyState(
              'No stores yet',
              'Your showroom will appear here.',
              Icons.storefront_outlined,
            ),
          ...branches.map((b) {
            final employees = store.staff
                .where((e) => e.branch == b.name)
                .length;
            final stock = store.vehicles
                .where((v) => v.branch == b.name)
                .fold<int>(0, (a, b) => a + b.stock);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PressFeedback(
                child: Panel(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    key: Key('store-${b.id}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StoreDetailPage(store: store, branch: b),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xffe9f6f7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.storefront_outlined,
                              color: brandNavy,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  b.location,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '$employees staff · $stock bikes',
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 19,
                            color: muted,
                          ),
                        ],
                      ),
                    ),
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
            const SizedBox(height: 12),
            DetailDisclosure(
              title: 'Showroom summary',
              child: Column(
                children: [
                  valueRow(
                    'Invoiced revenue',
                    shortMoney(
                      store.sales
                          .where(
                            (s) =>
                                s.branch == branch.name &&
                                s.status != 'Cancelled',
                          )
                          .fold<double>(0, (a, b) => a + b.total),
                    ),
                  ),
                  valueRow(
                    'Available bikes',
                    '${store.vehicles.where((v) => v.branch == branch.name).fold<int>(0, (a, b) => a + b.stock)}',
                  ),
                ],
              ),
            ),
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
