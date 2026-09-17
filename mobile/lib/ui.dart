import 'package:flutter/material.dart';

import 'branding.dart';
import 'domain.dart';

const blue = Color(0xff1e40af),
    ink = Color(0xff0f172a),
    muted = Color(0xff64748b),
    canvas = Color(0xfff5f7fc),
    line = Color(0xffe2e8f0),
    green = Color(0xff059669),
    amber = Color(0xffb45309);
final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: blue,
    primary: blue,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: canvas,
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: line),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xfff1f5fb),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: line),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: const BorderSide(color: line),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: Color(0xffdbeafe),
    height: 72,
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w600),
    ),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    bodyMedium: TextStyle(fontSize: 14, color: ink),
    bodySmall: TextStyle(fontSize: 12, color: muted),
  ),
);

class Brand extends StatelessWidget {
  final bool compact;
  const Brand({super.key, this.compact = false});
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MotorStockMark(size: compact ? 36 : 56),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MOTO STOCK',
              style: TextStyle(
                color: brandNavy,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: compact ? 18 : 27,
                letterSpacing: .3,
              ),
            ),
            Text(
              'DEALERSHIP ERP',
              style: TextStyle(
                fontSize: compact ? 8 : 10,
                letterSpacing: 1.5,
                color: muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, {super.key, this.color = blue});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

Color statusColor(String text) =>
    text.toLowerCase().contains('out') || text == 'Cancelled'
    ? Colors.red
    : text == 'Paid' || text == 'Delivered' || text == 'In stock'
    ? green
    : amber;

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SectionTitle(this.title, {super.key, this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class Metric extends StatelessWidget {
  final String label, value, hint;
  final IconData icon;
  const Metric(this.label, this.value, this.hint, this.icon, {super.key});
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ),
            Icon(icon, size: 18, color: blue),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(hint, style: const TextStyle(fontSize: 11, color: muted)),
      ],
    ),
  );
}

class MetricGrid extends StatelessWidget {
  final List<Widget> children;
  const MetricGrid({super.key, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children
          .map((w) => SizedBox(width: (c.maxWidth - 12) / 2, child: w))
          .toList(),
    ),
  );
}

class BikeImage extends StatelessWidget {
  final Vehicle vehicle;
  final double width, height;
  const BikeImage(this.vehicle, {super.key, this.width = 78, this.height = 64});

  @override
  Widget build(BuildContext context) =>
      ItemImage(vehicle.image, width: width, height: height);
}

class ItemImage extends StatelessWidget {
  final String source;
  final double width, height;
  const ItemImage(this.source, {super.key, this.width = 78, this.height = 64});

  Widget _image() {
    const fallback = Icon(Icons.two_wheeler, size: 36, color: blue);
    if (source.isEmpty) return fallback;
    if (source.startsWith('data:image/')) {
      try {
        return Image.memory(
          UriData.parse(source).contentAsBytes(),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } on FormatException {
        return fallback;
      }
    }
    if (source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: width,
      height: height,
      color: const Color(0xffeaf0fa),
      child: _image(),
    ),
  );
}

Widget emptyState(String title, String subtitle, IconData icon) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
  child: Center(
    child: Column(
      children: [
        Icon(icon, size: 48, color: muted),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted),
        ),
      ],
    ),
  ),
);
void notice(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;
Future<void> perform(
  BuildContext context,
  Future<void> Function() action, {
  String success = 'Saved on this device',
}) async {
  try {
    await action();
    if (context.mounted) notice(context, success);
  } catch (e) {
    if (context.mounted) {
      notice(context, e.toString().replaceFirst('Bad state: ', ''));
    }
  }
}

Widget valueRow(
  String label,
  String value, {
  bool bold = false,
  Color? color,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: muted)),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? ink,
          ),
        ),
      ),
    ],
  ),
);
